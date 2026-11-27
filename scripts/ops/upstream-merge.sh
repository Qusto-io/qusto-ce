#!/usr/bin/env bash
#
# Tooling for merging plausible/analytics into qusto-ce (DRIFT-01 Phase 1).
#
# qusto-ce is a long-lived fork that rebranded in place, so ~58% of the conflicts
# in an upstream merge are the same branding collisions every single time. git
# rerere ("reuse recorded resolution") replays a resolution once it has seen it,
# which turns that recurring cost into a one-off — but only if the cache
# outlives the clone. `.git/rr-cache` does not, so this script copies it to and
# from a private directory outside the repository. Cache entries are whole
# conflicted files from upstream: never commit them to this public repository.
#
#   setup            enable rerere and load the saved cache into this clone
#   save             export this clone's cache to the private directory
#   slice <DATE>     merge upstream history up to YYYY-MM-DD (Phase 3 slices)
#   status           drift, rerere state, cache size
#
# Read the playbook before resolving anything: docs/UPSTREAM_MERGE_PLAYBOOK.md

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/plausible/analytics.git}"
UPSTREAM_REF="${UPSTREAM_REF:-master}"

repo_root="$(git rev-parse --show-toplevel)"
# --git-common-dir, not --git-dir: in a worktree the latter points at a per-worktree
# directory, and rerere's cache lives with the shared one.
git_dir="$(cd "${repo_root}" && git rev-parse --git-common-dir)"
case "${git_dir}" in
  /*) : ;;
  *) git_dir="${repo_root}/${git_dir}" ;;
esac

SHARED_CACHE="${RERERE_SHARED_CACHE:-${XDG_DATA_HOME:-$HOME/.local/share}/qusto-ce/rerere-cache}"
LIVE_CACHE="${git_dir}/rr-cache"

die() { echo "ERROR: $*" >&2; exit 1; }

case "${SHARED_CACHE}/" in
  "${repo_root}"/*) die "RERERE_SHARED_CACHE must be outside the repository: ${SHARED_CACHE}" ;;
esac

# main's history was rewritten (extra/, assets/js/dashboard/extra/ and leaked upstream
# credentials removed). Raw upstream shares no commit ids with main any more and
# would re-import extra/. Upstream is therefore always taken through the same deterministic
# filter (scripts/ops/filtered-upstream.sh); the `upstream` remote points at that local copy.
FILTERED_UPSTREAM="${FILTERED_UPSTREAM:-${XDG_CACHE_HOME:-$HOME/.cache}/qusto-ce/upstream-filtered.git}"

ensure_upstream_remote() {
  if git remote get-url upstream >/dev/null 2>&1; then
    git remote set-url upstream "${FILTERED_UPSTREAM}"
  else
    git remote add upstream "${FILTERED_UPSTREAM}"
  fi
}

# Rebuild the filtered copy and fetch it. Never fetch ${UPSTREAM_URL} directly.
fetch_upstream() {
  command -v git-filter-repo >/dev/null 2>&1 || die "git-filter-repo is required (pip install git-filter-repo==2.47.0)"
  mkdir -p "$(dirname "${FILTERED_UPSTREAM}")"
  "${repo_root}/scripts/ops/filtered-upstream.sh" "${FILTERED_UPSTREAM}" "${UPSTREAM_URL}" >&2
  ensure_upstream_remote
  git fetch --no-tags -q upstream "${UPSTREAM_REF}"
}

# docs/UPSTREAM_INTEGRATION_STATE.md records the ORIGINAL upstream sha; print its filtered id.
map_integrated_tip() {
  awk -v s="$1" '$1==s{print $2}' "${FILTERED_UPSTREAM}/filter-repo/commit-map" 2>/dev/null
}

cmd_setup() {
  git config rerere.enabled true
  # Stage files rerere resolves, so a fully-recognised merge needs only a commit.
  git config rerere.autoupdate true
  echo "rerere: enabled (autoupdate on)"

  # Backs the `merge=ours` entries in .gitattributes (branded binary assets).
  # Git ships no built-in "ours" file driver: `true` succeeds without touching
  # the working-tree copy, which leaves our version in place. Without this the
  # attribute is inert and those files conflict as before - it fails safe.
  git config merge.ours.driver true
  echo "merge driver: ours (branded assets keep our side - see .gitattributes)"

  mkdir -p "${LIVE_CACHE}"
  if [ -d "${SHARED_CACHE}" ] && [ -n "$(ls -A "${SHARED_CACHE}" 2>/dev/null || true)" ]; then
    # `cp -R src dst` nests src INSIDE dst when dst already exists, which silently
    # puts the cache at rr-cache/rr-cache and rerere never finds it. The trailing
    # /. copies the *contents*. This bit me while proving the mechanism works.
    cp -R "${SHARED_CACHE}/." "${LIVE_CACHE}/"
    echo "loaded $(find "${SHARED_CACHE}" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') recorded resolution(s) into ${LIVE_CACHE}"
  else
    echo "shared cache is empty - resolutions recorded from now on will populate it"
  fi

  ensure_upstream_remote
  echo "upstream remote: $(git remote get-url upstream)"
}

cmd_save() {
  [ -d "${LIVE_CACHE}" ] || die "no ${LIVE_CACHE}; run '$0 setup' and perform a merge first"

  mkdir -p "${SHARED_CACHE}"
  chmod 700 "${SHARED_CACHE}"
  local saved=0 skipped=0
  for d in "${LIVE_CACHE}"/*/; do
    [ -d "${d}" ] || continue
    # A preimage with no postimage is an unresolved conflict, not a resolution.
    # Exporting those would share "we got stuck here", which helps nobody.
    if [ ! -f "${d}postimage" ]; then
      skipped=$(( skipped + 1 ))
      continue
    fi
    mkdir -p "${SHARED_CACHE}/$(basename "${d}")"
    cp -R "${d}." "${SHARED_CACHE}/$(basename "${d}")/"
    saved=$(( saved + 1 ))
  done

  echo "exported ${saved} resolution(s) to ${SHARED_CACHE}"
  if [ "${skipped}" -gt 0 ]; then
    echo "skipped ${skipped} unresolved entr(ies) (preimage only)"
  fi
  echo "kept outside the repository; copy that directory privately to use it on another machine"
}

cmd_slice() {
  local cutoff="${1:-}"
  [ -n "${cutoff}" ] || die "usage: $0 slice <YYYY-MM-DD>"
  case "${cutoff}" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) : ;;
    *) die "date must be YYYY-MM-DD, got '${cutoff}'" ;;
  esac

  fetch_upstream

  local target
  target="$(git rev-list -1 --before="${cutoff} 23:59:59" "upstream/${UPSTREAM_REF}")"
  [ -n "${target}" ] || die "no upstream commit on or before ${cutoff}"

  local behind_total behind_slice
  behind_total="$(git rev-list --count "HEAD..upstream/${UPSTREAM_REF}")"
  behind_slice="$(git rev-list --count "HEAD..${target}")"

  echo "upstream/${UPSTREAM_REF} is ${behind_total} commits ahead of HEAD"
  echo "slice to ${cutoff} => ${target:0:10} (${behind_slice} commits)"
  echo
  echo "Run the merge yourself so you see every conflict:"
  echo "    git merge ${target}"
  echo
  echo "Then: resolve per docs/UPSTREAM_MERGE_PLAYBOOK.md, commit, and run '$0 save'."
  echo "Deliberately not merging for you - an auto-merge here is how a wrong"
  echo "resolution gets committed unread, and rerere would then replay it forever."
}

cmd_status() {
  fetch_upstream

  local base behind ahead
  base="$(git merge-base HEAD "upstream/${UPSTREAM_REF}" 2>/dev/null || echo '')"
  if [ -n "${base}" ]; then
    behind="$(git rev-list --count "HEAD..upstream/${UPSTREAM_REF}")"
    ahead="$(git rev-list --count "upstream/${UPSTREAM_REF}..HEAD")"
    echo "merge base : ${base:0:10} ($(git log -1 --format=%cs "${base}"))"
    echo "behind     : ${behind} (git ancestry; squash merges do not move the base)"
    echo "ahead      : ${ahead}"
  else
    echo "no merge base with upstream/${UPSTREAM_REF} yet"
  fi

  integrated_file="${repo_root}/docs/UPSTREAM_INTEGRATION_STATE.md"
  if [ -f "${integrated_file}" ]; then
    integrated="$(map_integrated_tip "$(sed -n 's/^integrated_upstream_tip: //p' "${integrated_file}" | head -1)")"
    if [ -n "${integrated}" ] && git cat-file -e "${integrated}^{commit}" 2>/dev/null; then
      remaining="$(git rev-list --count "${integrated}..upstream/${UPSTREAM_REF}")"
      echo "integrated : ${integrated:0:10} ($(git log -1 --format=%cs "${integrated}"))"
      echo "remaining  : ${remaining} upstream commit(s) after integrated tip"
    fi
  fi

  echo "rerere     : $(git config --get rerere.enabled || echo 'NOT ENABLED - run setup')"
  echo "shared     : $(find "${SHARED_CACHE}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') resolution(s) in ${SHARED_CACHE}"
  echo "live       : $(find "${LIVE_CACHE}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') entr(ies) in ${LIVE_CACHE}"
}

case "${1:-}" in
  setup)  shift; cmd_setup "$@" ;;
  save)   shift; cmd_save "$@" ;;
  slice)  shift; cmd_slice "$@" ;;
  status) shift; cmd_status "$@" ;;
  *)
    sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
