# Qusto Community Edition — deployment

This repository is **Qusto Community Edition (CE)**: a fork of
[Plausible Analytics](https://github.com/plausible/analytics), licensed AGPL-3.0.
It is the event engine and traffic dashboard that managed Qusto also runs.

> **Rewritten 2026-11-09 (OC-03).** The previous version described a private
> `qusto-ecommerce` submodule compiled into this engine, Helm charts and a
> `public-main` branch. None of that exists, and compiling private modules into
> this AGPL program would have made them AGPL. The hook that allowed it
> (`proprietary_paths()` in `mix.exs`) has been removed.

## What this repository builds

| Build | How | What is in it |
|---|---|---|
| **CE** (`MIX_ENV=ce`) | `Dockerfile` default; `docker compose` in this repo; the production deploy | `lib/` only. Traffic analytics, goals, custom properties, Stats API, Qusto branding and privacy defaults |
| Local and CI (`ce_dev`, `ce_test`, `dev`, `test`) | `mix test`, local dev | the same `lib/` tree. **Never built into an image** |

`extra/` is absent at this commit. It remains on tags published before the
removal. Those files are Plausible's. `deploy-variant-guard.yml` fails the
build if `extra/` or `assets/js/dashboard/extra/` is present, and it fails any
PR that builds an image with the `prod` variant.

**Not in this repository:** orders, revenue, products, the Coverage figure,
customer LTV, cart abandonment, attribution and the Shopify/WooCommerce
connectors. Those are managed Qusto (separate services that read this engine
over its API), not part of CE.

## Self-hosting from source

Self-hosting is **community supported**. A tested install guide and versioned
public images are planned; until then, build from source:

```bash
git clone https://github.com/Qusto-io/qusto-ce.git
cd qusto-ce
# Set at least SECRET_KEY_BASE (64+ random bytes) and BASE_URL in .env
docker compose up -d        # builds the CE image (MIX_ENV=ce), Postgres, ClickHouse
```

City and region data needs an IP database: set `IP_GEOLOCATION_DB` (e.g. DB-IP
City Lite) or `MAXMIND_LICENSE_KEY`. Without one, locations fall back to country
level or are empty.

`main` is the only release line, and every merge to `main` is a production
deploy of managed Qusto. Pin a commit if you need a stable install.

## Production deploy (maintainers)

`.github/workflows/deploy.yml`, job `deploy-production`, runs on every push to
`main`: it builds the image on the host with `docker build .` (so `MIX_ENV=ce`),
boots it against throwaway databases (smoke gate), then swaps the running
container. The job prints the build variant it shipped. See ADR-008 in the vault
for the branch model and build-variant decision.

## Support

Community support: GitHub issues on this repository. Upstream Plausible's own
self-hosting guide describes Plausible CE, not this fork.
