integrated_upstream_tip: 5e2f1036dab9b88f31dfd14b01ffb5d81e5ffe25
integrated_through_date: 2026-06-30
slice: 3

# Upstream integration state (DRIFT-01)

Git merge-base with `plausible/analytics` stays at the fork when slice merges are
squash-merged to `main`. The `integrated_upstream_tip` line above records the
**upstream commit whose content is integrated**, so drift can be measured as
commits after that tip (`scripts/ops/upstream-merge.sh status`).

Update the tip at the end of each Phase 3 slice PR.

| Slice | Upstream tip | PR |
|-------|----------------|-----|
| 1 | `7b18ffcab4` (2026-03-31) | #161 |
| 2 | `5e2f1036da` (2026-06-30) | #163 |
| 3 | `0f362bd84e` (2026-09-21) | #164 |
