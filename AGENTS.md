# AGENTS.md — qusto-ce (public AGPL engine)

## Purpose

Public AGPL-3.0 analytics engine (a fork of Plausible Analytics). Git root: this directory.

## Remote

- **origin:** `github.com/Qusto-io/qusto-ce`
- Default branch: `main`. A push to `main` deploys; open a pull request for every change.

## Operating rules

- AGPL: everything here is public. Do not commit proprietary code, credentials, customer data or internal planning documents.
- Plausible's proprietary `extra/` directory must never return (CI blocks it, see `scripts/ci/open-core-guard.sh`).
- Never force-push `main`.
