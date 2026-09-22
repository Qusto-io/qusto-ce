# Upstream integration state (DRIFT-01)

Git merge-base with `plausible/analytics` stays at the fork when slice merges are
squash-merged to `main`. This file records the **upstream commit tip whose content
is integrated**, so drift can be measured as commits *after* that tip.

Update the tip at the end of each Phase 3 slice PR (after merge commit on the
slice branch, before squash to `main` is fine to set the value that slice shipped).

```yaml
integrated_upstream_tip: 5e2f1036dab9b88f31dfd14b01ffb5d81e5ffe25
integrated_through_date: 2026-06-30
slice: 2
```

Previous: slice 1 → `7b18ffcab440644986482c2371b35f58b99a8e2b` (2026-03-31), PR #161.
