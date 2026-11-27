#!/usr/bin/env bash
# Build a *filtered* copy of plausible/analytics that shares commit ids with qusto-ce.
#
# qusto-ce's public history was rewritten with git-filter-repo to remove Plausible's
# proprietary extra/ and assets/js/dashboard/extra/ trees, recorded merge resolutions
# (.rerere-cache/) and credentials that upstream once committed.
# Commit ids changed, so a raw `git fetch` of upstream no longer shares ancestry
# with main. Applying the SAME deterministic filter to a clone of upstream yields the
# same commit ids for shared history, so merges and drift measurement work again.
#
# Usage: scripts/ops/filtered-upstream.sh <target-bare-dir> [upstream-url]
# Then:  git fetch --no-tags <target-bare-dir> master:refs/remotes/upstream/master
# Map an original upstream sha to its filtered id:
#        awk -v s=<40-char-sha> '$1==s{print $2}' <target-bare-dir>/filter-repo/commit-map
#
# DO NOT change the filter arguments or the replace file: any change alters commit ids
# and silently breaks the shared ancestry (this is the --preserve-commit-hashes lesson).
set -euo pipefail

target="${1:?usage: $0 <target-bare-dir> [upstream-url]}"
url="${2:-https://github.com/plausible/analytics.git}"
here="$(cd "$(dirname "$0")" && pwd)"

command -v git-filter-repo >/dev/null 2>&1 || { echo "git-filter-repo is required (pip install git-filter-repo)"; exit 2; }

rm -rf "${target}"
git clone --quiet --bare "${url}" "${target}"
(
  cd "${target}"
  git filter-repo --force \
    --path extra/ --path backups/ --path E2E_IMPLEMENTATION_REPORT.md --path .week5-progress.json \
    --path opencode.json --path .env --path .backup-env --path backup-config.yml \
    --path .rerere-cache/ --path assets/js/dashboard/extra/ \
    --invert-paths \
    --preserve-commit-hashes \
    --replace-text "${here}/filter-replace.txt" >/dev/null 2>&1
)
echo "filtered upstream ready: ${target} ($(git -C "${target}" rev-list --count --all) commits)"
