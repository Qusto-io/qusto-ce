# `develop` branch retired (2026-09-24)

Qusto CE uses a **single trunk** (`main`); push to `main` deploys production.

- GitHub remote **`develop`**: absent (404 as of 2026-09-24).
- Staging (`staging.qusto.io`) decommissioned per `deploy.yml` header.

Local clones may still have a stale `develop` branch. Safe cleanup:

```sh
git fetch origin
git checkout main
git branch -D develop   # only if you no longer need local-only commits
```

QUSTO-684 (DRIFT-01 P2).
