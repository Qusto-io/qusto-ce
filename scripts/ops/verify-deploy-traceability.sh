#!/usr/bin/env bash
# Verify a CE production deploy tag resolves to a git commit (AGPL §13 / QUSTO-689).
#
# Usage: verify-deploy-traceability.sh <vNNN-ce>
# Exit 0 when the annotated tag exists on origin and prints the commit SHA.

set -euo pipefail

TAG="${1:?usage: verify-deploy-traceability.sh <vNNN-ce>}"

git fetch --tags origin >/dev/null 2>&1 || true

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "ERROR: tag $TAG not found (git fetch --tags origin?)" >&2
  exit 1
fi

SHA="$(git rev-parse "$TAG")"
echo "OK: $TAG -> $SHA"
git log -1 --oneline "$SHA"
