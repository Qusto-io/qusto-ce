# AGENTS.md — qusto-ce (public AGPL engine)

## Purpose

Public AGPL-3.0 analytics engine — Plausible fork. Git root: this directory.

## Remote

- **origin:** `github.com/Qusto-io/qusto-ce`
- Default branch for staging work: `staging` (verify with `git branch --show-current`)

## Stack

Elixir/Phoenix analytics core. Staging on Daxo-01 when `qusto_staging_control` start is invoked via governed MCP.

## Operating rules

- AGPL — respect license boundaries vs EE proprietary code in `qusto-ee`.
- Do not commit vault docs or EE code here.
- Production deploys: human-gated runbooks on qusto-prod-1.
- Branch off `staging` or `main` per active sprint; never force-push.

## MCP tools

- **daxo-governed**: `qusto_staging_control` (`start` | `stop`)
- **daxo-qusto**: health checks
- **daxo-plane**: Qusto engineering issues

## Related

- Vault specs/logs: `../../00-obsidian-vault/`
- EE commercial layer: `../qusto-ee/`
