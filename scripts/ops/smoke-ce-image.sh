#!/usr/bin/env bash
#
# Prove a freshly built CE image actually boots and serves before the running
# production container is swapped for it.
#
# Why this exists: `deploy.yml` used to `docker compose up -d analytics` and only
# then health-check. By the time a broken image failed that check, production was
# already down — the check reported the outage rather than preventing it.
#
# The image is booted against THROWAWAY Postgres and ClickHouse containers on an
# isolated network, never production's. Two reasons that matters:
#   1. A second app instance pointed at the production database would start Oban
#      workers and crons against live data — duplicate jobs, possibly duplicate
#      email. (Belt and braces: DISABLE_CRON=true and a local mail adapter here.)
#   2. `db migrate` has to run for the boot to be meaningful, and that must never
#      touch a production schema.
#
# No production secrets are passed in; throwaway credentials are generated per run.
#
# Usage:  smoke-ce-image.sh <image-ref>
# Exit:   0 = image boots and serves /api/health; non-zero = do not deploy it.

set -euo pipefail

IMAGE="${1:?usage: smoke-ce-image.sh <image-ref>}"

PG_IMAGE="${SMOKE_PG_IMAGE:-postgres:15-alpine}"
CH_IMAGE="${SMOKE_CH_IMAGE:-clickhouse/clickhouse-server:24.3-alpine}"
BOOT_TIMEOUT="${SMOKE_BOOT_TIMEOUT:-120}"
DB_TIMEOUT="${SMOKE_DB_TIMEOUT:-90}"

ID="cesmoke-$$-${RANDOM}"
NET="${ID}-net"
PG="${ID}-pg"
CH="${ID}-ch"
APP="${ID}-app"

PG_PASS="$(openssl rand -hex 16)"
CH_PASS="$(openssl rand -hex 16)"
SECRET_KEY_BASE="$(openssl rand -base64 48 | tr -d '\n')"

# Which stage we are in, so a failure says where it happened rather than
# blaming a container that was never created.
STAGE="startup"

cleanup() {
  local rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "ERROR: smoke failed during stage: ${STAGE}" >&2
    if docker ps -a --format '{{.Names}}' | grep -qx "${APP}"; then
      echo "--- smoke app logs (last 60) ---" >&2
      docker logs --tail 60 "${APP}" 2>&1 | sed 's/^/    /' >&2 || true
    else
      echo "    (the app container was never started - failure was earlier)" >&2
    fi
  fi
  docker rm -f "${APP}" "${PG}" "${CH}" >/dev/null 2>&1 || true
  docker network rm "${NET}" >/dev/null 2>&1 || true
  return "${rc}"
}
trap cleanup EXIT

echo "==> Smoke: ${IMAGE}"
STAGE="creating throwaway stack"
docker network create "${NET}" >/dev/null

docker run -d --name "${PG}" --network "${NET}" \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="${PG_PASS}" \
  -e POSTGRES_DB=plausible \
  "${PG_IMAGE}" >/dev/null

docker run -d --name "${CH}" --network "${NET}" \
  -e CLICKHOUSE_DB=qusto \
  -e CLICKHOUSE_USER=default \
  -e CLICKHOUSE_PASSWORD="${CH_PASS}" \
  -e CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1 \
  --ulimit nofile=262144:262144 \
  "${CH_IMAGE}" >/dev/null

STAGE="waiting for throwaway databases"
echo "--> waiting for throwaway databases"
deadline=$(( $(date +%s) + DB_TIMEOUT ))
pg_ok=0; ch_ok=0
# Explicit ifs, not `A || B && C`: that parses as `(A||B) && C`, and when the
# whole list evaluates false `set -e` kills the script on the first poll where a
# database is simply not up yet.
while [ "$(date +%s)" -lt "${deadline}" ]; do
  if [ "${pg_ok}" -ne 1 ]; then
    if docker exec "${PG}" pg_isready -U postgres -q >/dev/null 2>&1; then pg_ok=1; fi
  fi
  if [ "${ch_ok}" -ne 1 ]; then
    if docker exec "${CH}" sh -c 'wget -qO- http://127.0.0.1:8123/ping 2>/dev/null || curl -sf http://127.0.0.1:8123/ping 2>/dev/null' >/dev/null 2>&1; then ch_ok=1; fi
  fi
  if [ "${pg_ok}" -eq 1 ] && [ "${ch_ok}" -eq 1 ]; then break; fi
  sleep 2
done
if [ "${pg_ok}" -ne 1 ] || [ "${ch_ok}" -ne 1 ]; then
  echo "ERROR: throwaway databases did not become ready (pg=${pg_ok} ch=${ch_ok})" >&2
  echo "       This is a smoke-harness fault, not necessarily a bad image." >&2
  exit 2
fi

DB_URL="postgresql://postgres:${PG_PASS}@${PG}:5432/plausible"
CH_URL="http://default:${CH_PASS}@${CH}:8123/qusto"

app_env=(
  -e "DATABASE_URL=${DB_URL}"
  -e "CLICKHOUSE_DATABASE_URL=${CH_URL}"
  -e "SECRET_KEY_BASE=${SECRET_KEY_BASE}"
  -e "BASE_URL=http://localhost:8000"
  # Nothing background may run: no crons, no queues, no Oban peer.
  -e "DISABLE_CRON=true"
  # Even with cron off, make outbound mail impossible rather than unlikely.
  -e "MAILER_ADAPTER=Bamboo.LocalAdapter"
  -e "LOG_LEVEL=warning"
)

STAGE="createdb"
echo "--> creating schema and running migrations"
docker run --rm --network "${NET}" "${app_env[@]}" "${IMAGE}" db createdb  >/dev/null
STAGE="migrate"
docker run --rm --network "${NET}" "${app_env[@]}" "${IMAGE}" db migrate   >/dev/null

STAGE="boot"
echo "--> booting the image"
docker run -d --name "${APP}" --network "${NET}" "${app_env[@]}" "${IMAGE}" >/dev/null

deadline=$(( $(date +%s) + BOOT_TIMEOUT ))
health=""
while [ "$(date +%s)" -lt "${deadline}" ]; do
  if ! docker ps --format '{{.Names}}' | grep -qx "${APP}"; then
    echo "ERROR: the image exited during boot" >&2
    exit 1
  fi
  health="$(docker exec "${APP}" wget -qO- http://127.0.0.1:8000/api/health 2>/dev/null || true)"
  if [ -n "${health}" ]; then break; fi
  sleep 3
done

STAGE="health check"
if [ -z "${health}" ]; then
  echo "ERROR: /api/health never responded within ${BOOT_TIMEOUT}s" >&2
  exit 1
fi

echo "--> /api/health: ${health}"

# A 200 alone is not enough: the endpoint reports per-subsystem status, and a
# degraded subsystem still answers. Fail on any value that is not "ok".
if echo "${health}" | grep -qiE '"(error|degraded|down|false)"'; then
  echo "ERROR: /api/health reported a subsystem not ok" >&2
  exit 1
fi
if ! echo "${health}" | grep -q '"ok"'; then
  echo "ERROR: /api/health did not report any subsystem as ok" >&2
  exit 1
fi

echo "==> Smoke PASSED for ${IMAGE}"
