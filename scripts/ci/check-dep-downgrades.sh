#!/usr/bin/env bash
# Fail when a PR lowers the version of a security-pinned package in either
# mix.lock (Elixir/Hex) or an npm package-lock.json.
#
# Usage: scripts/ci/check-dep-downgrades.sh <base-ref> <head-ref>
#
# Env:
#   SECURITY_PINS     space-separated hex package names (default below)
#   NPM_SECURITY_PINS space-separated npm package names (default below)
#   NPM_LOCKFILES     space-separated lockfile paths relative to repo root
#   LABELS            comma-separated PR labels; `allow-dep-downgrade` downgrades
#                     the failure to a warning (for upstream slice merges that
#                     deliberately take an older version — say why in the PR)
#
# `mix deps.audit` only flags versions with a published advisory, so it does not
# notice a slice merge silently reverting a bump we made ahead of an advisory
# (#164 reverted cowboy 2.19.0 -> 2.14.x this way; restored in #173).
# Similarly, npm lockfile downgrades went undetected until QUS-685 (#150
# restored by slice 3, caught post-merge). This guard covers both surfaces.
# Must stay bash 3.2 compatible so it runs on macOS as well as CI.

set -euo pipefail

BASE_REF="${1:?usage: $0 <base-ref> <head-ref>}"
HEAD_REF="${2:?usage: $0 <base-ref> <head-ref>}"
SECURITY_PINS="${SECURITY_PINS:-cowboy cowlib plug_cowboy req mint phoenix finch}"
# @humanfs/node: dev-only, restored by QUS-685 after DRIFT-01 slice 3 reverted #150.
# react-router / react-router-dom: shipped in the dashboard bundle (QUS-687).
# Add new packages here when a security bump is applied ahead of an upstream slice.
NPM_SECURITY_PINS="${NPM_SECURITY_PINS:-@humanfs/node react-router react-router-dom}"
NPM_LOCKFILES="${NPM_LOCKFILES:-assets/package-lock.json tracker/package-lock.json}"
LABELS="${LABELS:-}"
ALLOW_LABEL="allow-dep-downgrade"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

# ── Hex / mix.lock ───────────────────────────────────────────────────────────
git show "${BASE_REF}:mix.lock" > "${tmp_dir}/base.lock"
git show "${HEAD_REF}:mix.lock" > "${tmp_dir}/head.lock"

lock_version() {
  # Prints the hex version of package $2 in lockfile $1, or nothing.
  awk -v pkg="\"$2\":" '$1 == pkg && $2 == "{:hex," { gsub(/[",]/, "", $4); print $4; exit }' "$1"
}

# 0 if version $1 is strictly lower than version $2.
version_lt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

echo "── Hex (mix.lock) ──────────────────────────────────────────────────────"
downgrades=""
for pkg in ${SECURITY_PINS}; do
  base_v="$(lock_version "${tmp_dir}/base.lock" "${pkg}")"
  head_v="$(lock_version "${tmp_dir}/head.lock" "${pkg}")"

  if [ -z "${base_v}" ]; then
    echo "  ${pkg}: not in base mix.lock, skipping"
  elif [ -z "${head_v}" ]; then
    echo "  ${pkg}: ${base_v} -> removed"
  elif version_lt "${head_v}" "${base_v}"; then
    echo "  ${pkg}: ${base_v} -> ${head_v}  DOWNGRADE"
    downgrades="${downgrades} ${pkg}(${base_v}->${head_v})"
  else
    echo "  ${pkg}: ${base_v} -> ${head_v}"
  fi
done

# ── npm / package-lock.json ──────────────────────────────────────────────────
# Requires jq, available in all GitHub Actions runners.
# Targets lockfile v2/v3 format: .packages["node_modules/<pkg>"].version
echo "── npm (package-lock.json) ─────────────────────────────────────────────"

npm_lock_version() {
  # Prints the resolved version of npm package $2 from lockfile JSON $1, or nothing.
  jq -r --arg pkg "node_modules/$2" '.packages[$pkg].version // empty' "$1"
}

npm_lock_idx=0
for npm_lockfile in ${NPM_LOCKFILES}; do
  npm_lock_idx=$((npm_lock_idx + 1))
  base_npm="${tmp_dir}/base_npm_${npm_lock_idx}.json"
  head_npm="${tmp_dir}/head_npm_${npm_lock_idx}.json"

  if ! git show "${BASE_REF}:${npm_lockfile}" > "${base_npm}" 2>/dev/null; then
    echo "  ${npm_lockfile}: not in base ref, skipping"
    continue
  fi
  if ! git show "${HEAD_REF}:${npm_lockfile}" > "${head_npm}" 2>/dev/null; then
    echo "  ${npm_lockfile}: not in HEAD ref, skipping"
    continue
  fi

  for pkg in ${NPM_SECURITY_PINS}; do
    base_v="$(npm_lock_version "${base_npm}" "${pkg}")"
    head_v="$(npm_lock_version "${head_npm}" "${pkg}")"

    if [ -z "${base_v}" ]; then
      echo "  ${npm_lockfile} / ${pkg}: not in base, skipping"
    elif [ -z "${head_v}" ]; then
      echo "  ${npm_lockfile} / ${pkg}: ${base_v} -> removed"
    elif version_lt "${head_v}" "${base_v}"; then
      echo "  ${npm_lockfile} / ${pkg}: ${base_v} -> ${head_v}  DOWNGRADE"
      downgrades="${downgrades} ${pkg}(${base_v}->${head_v},${npm_lockfile})"
    else
      echo "  ${npm_lockfile} / ${pkg}: ${base_v} -> ${head_v}"
    fi
  done
done

# ── Gate ─────────────────────────────────────────────────────────────────────
if [ -z "${downgrades}" ]; then
  echo "No security-pinned package was downgraded."
  exit 0
fi

if printf '%s' "${LABELS}" | tr ',' '\n' | grep -qx "${ALLOW_LABEL}"; then
  echo "::warning title=Security-pinned dep downgraded::${downgrades# } — allowed by the '${ALLOW_LABEL}' label. State the reason in the PR description."
  exit 0
fi

echo "::error title=Security-pinned dep downgraded::${downgrades# }. These packages are pinned for security (docs/UPSTREAM_MERGE_PLAYBOOK.md). Re-apply the newer version in mix.lock / package-lock.json, or add the '${ALLOW_LABEL}' label with a written justification."
exit 1
