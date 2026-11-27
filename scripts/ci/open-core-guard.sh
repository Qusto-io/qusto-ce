#!/usr/bin/env bash
# Open-core guard: this repository is public AGPL code. Fail when something that
# must stay private or that we have no licence to redistribute appears in the tree.
#  - Go sources, modules and directories that belong to the private services
#  - Plausible's proprietary extra/ tree (no rights granted; removed 2026-11)
#  - recorded merge resolutions (.rerere-cache/), which hold whole upstream files
#  - env files and private keys that are not the known placeholders
#  - credential-shaped strings
set -euo pipefail
fail=0
report() { echo "::error title=open-core-guard::$1"; fail=1; }

files="$(git ls-files)"

bad_paths="$(printf '%s\n' "$files" | grep -E '(\.go$|(^|/)go\.(mod|sum)$|^(extra|services|modules|dashboard|connectors|packages|backups|\.rerere-cache)/|^assets/js/dashboard/extra/)' || true)"
[ -z "$bad_paths" ] || report "paths that must not be in the public engine: $(echo "$bad_paths" | head -5 | tr '\n' ' ')"

bad_env="$(printf '%s\n' "$files" | grep -E '(^|/)\.(env|backup-env)([._-].*)?$' | grep -v -E '^(config/\.env\.(dev|test|e2e_test|load)|\.env\.(example|dev|test)|plausible-variables\.sample\.env)$' || true)"
[ -z "$bad_env" ] || report "env files that are not the known placeholders: $(echo "$bad_env" | head -5 | tr '\n' ' ')"

patterns='-----BEGIN ((RSA|OPENSSH|EC|DSA|PGP) )?PRIVATE KEY|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|xox[abpr]-[A-Za-z0-9-]{10,}|[sr]k_live_[A-Za-z0-9]{16,}|shp(at|ua|ss|ca)_[a-f0-9]{24,}|AIza[0-9A-Za-z_-]{35}|ya29\.[A-Za-z0-9_-]{20,}|hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+'
set +e
hits="$(git grep -nIE -e "$patterns" -- . ':!scripts/ci/open-core-guard.sh')"
status=$?
set -e
# git grep: 0 = matches, 1 = no match, anything else = the scan itself failed (must not pass silently)
if [ "$status" -gt 1 ]; then report "credential scan failed to run (git grep exit $status)"; hits=""; fi
hits="$(printf '%s\n' "$hits" | grep -v 'AKIAIOSFODNN7EXAMPLE' | grep -v '^$' || true)"
[ -z "$hits" ] || report "credential-shaped strings: $(echo "$hits" | cut -c1-120 | head -5 | tr '\n' ' ')"

if [ "$fail" -eq 0 ]; then echo "open-core-guard: ok ($(printf '%s\n' "$files" | wc -l) tracked files)"; fi
exit "$fail"
