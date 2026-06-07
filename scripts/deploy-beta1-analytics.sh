#!/usr/bin/env bash
# Deploy Qusto CE analytics container on beta1 (qusto-prod-1).
# Invoked by .github/workflows/deploy.yml via SSH.
#
# Required env on server:
#   CE_GIT_REF  — branch, tag, or commit to build (e.g. main, feat/rebrand-2026-06)
#   CE_VERSION  — image tag suffix (e.g. v1.0.2-ce)
#
# Prerequisites:
#   - docker, git
#   - /home/deploy/qusto-ee with docker compose stack

set -euo pipefail

CE_GIT_REF="${CE_GIT_REF:-main}"
CE_VERSION="${CE_VERSION:?CE_VERSION is required}"
BUILD_DIR="/home/deploy/qusto-ce-build"
EE_DIR="/home/deploy/qusto-ee"
IMAGE="ghcr.io/qusto-io/qusto-ce:${CE_VERSION}"

echo "==> Deploy CE analytics: ref=${CE_GIT_REF} version=${CE_VERSION}"

rm -rf "${BUILD_DIR}"
git clone --depth 1 --branch "${CE_GIT_REF}" \
  https://github.com/Qusto-io/qusto-ce.git "${BUILD_DIR}"

cd "${BUILD_DIR}"
docker build -t "${IMAGE}" -t "qusto/qusto-ce:${CE_VERSION}" .

cd "${EE_DIR}"
if grep -q '^CE_VERSION=' .env; then
  sed -i "s/^CE_VERSION=.*/CE_VERSION=${CE_VERSION}/" .env
else
  echo "CE_VERSION=${CE_VERSION}" >> .env
fi

docker compose up -d analytics

echo "==> Waiting for health..."
for i in $(seq 1 12); do
  if curl -sf http://127.0.0.1:8000/api/health >/dev/null; then
    curl -sf http://127.0.0.1:8000/api/health
    echo ""
    echo "==> CE analytics healthy (${IMAGE})"
    exit 0
  fi
  sleep 5
done

echo "ERROR: health check failed after analytics restart" >&2
docker compose logs analytics --tail 40
exit 1
