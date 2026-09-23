#!/usr/bin/env bash
# Fail when a PR lowers the mix.lock version of a security-pinned package.
#
# Usage: scripts/ci/check-dep-downgrades.sh <base-ref> <head-ref>
#
# Env:
#   SECURITY_PINS  space-separated hex package names (default below)
#   LABELS         comma-separated PR labels; `allow-dep-downgrade` downgrades
#                  the failure to a warning (for upstream slice merges that
#                  deliberately take an older version — say why in the PR)
#
# `mix deps.audit` only flags versions with a published advisory, so it does not
# notice a slice merge silently reverting a bump we made ahead of an advisory
# (#164 reverted cowboy 2.19.0 -> 2.14.x this way; restored in #173).
# Must stay bash 3.2 compatible so it runs on macOS as well as CI.

set -euo pipefail

BASE_REF="${1:?usage: $0 <base-ref> <head-ref>}"
HEAD_REF="${2:?usage: $0 <base-ref> <head-ref>}"
SECURITY_PINS="${SECURITY_PINS:-cowboy cowlib plug_cowboy req mint phoenix finch}"
LABELS="${LABELS:-}"
ALLOW_LABEL="allow-dep-downgrade"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
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

if [ -z "${downgrades}" ]; then
  echo "No security-pinned package was downgraded."
  exit 0
fi

if printf '%s' "${LABELS}" | tr ',' '\n' | grep -qx "${ALLOW_LABEL}"; then
  echo "::warning title=Security-pinned dep downgraded::${downgrades# } — allowed by the '${ALLOW_LABEL}' label. State the reason in the PR description."
  exit 0
fi

echo "::error title=Security-pinned dep downgraded::${downgrades# }. These packages are pinned for security (docs/UPSTREAM_MERGE_PLAYBOOK.md). Re-apply the newer version in mix.lock, or add the '${ALLOW_LABEL}' label with a written justification."
exit 1
