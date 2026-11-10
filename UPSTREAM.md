# Upstream attribution and differences

Qusto Community Edition (CE) is a fork of
[Plausible Analytics](https://github.com/plausible/analytics), licensed under the
GNU AGPL v3. Plausible's copyright, trademarks and authorship stay credited to
**Plausible Insights OÜ**.

> **Updated 2026-11-10.** The previous version said the fork was "based on
> v2.1.0 (January 2025)". That was the original fork point, and it has been out
> of date since the 2026 upstream syncs. It also claimed features this
> repository does not contain. Both are corrected below.

## Where this fork stands

| | |
|---|---|
| Upstream base | `plausible/analytics` `master` at `27cbc4419c` (2026-09-24), `git describe`: `v3.2.0-rc.0-444-g27cbc4419c` |
| Last upstream sync | "Slice 4 monthly", merged 2026-09-24 (DRIFT-01) |
| Divergence (2026-11-10) | 266 commits ahead (Qusto changes and merges), 106 behind upstream `master` |
| Drift monitoring | `.github/workflows/upstream-drift.yml`, every Monday 06:00 UTC |

To recompute:

```sh
git fetch upstream master
mb=$(git merge-base origin/main upstream/master)
git describe --tags "$mb"
git rev-list --count upstream/master..origin/main   # ahead
git rev-list --count origin/main..upstream/master   # behind
```

## What this repository is, and is not

**Is:** Plausible's open-source engine and dashboard (`lib/`), built with
`MIX_ENV=ce`. Qusto changes are kept small on purpose:
- branding
- privacy defaults (IP masking)
- city and region resolution for the DB-IP City Lite database
- a Source Code Offer page that links the exact running commit (AGPL §13)
- deployment and CI

**Is not:** Qusto's commercial product. Store orders, revenue, products, the
Coverage figure, customer LTV, attribution and the Shopify and WooCommerce
connectors are separate Qusto services. They read this engine over its API and
are not part of this repository.

### `extra/` is not open source

Plausible keeps some features (funnels, installation verification, the
customer-support tools and more) in `extra/`. **`extra/COPYING.txt` grants no
rights** to use, distribute or otherwise exploit that code. It is in this
repository only because it is in the upstream tree.

- Every image Qusto builds or ships uses `MIX_ENV=ce`, which compiles `lib/`
  only. `deploy-variant-guard.yml` fails any PR that builds an image with the
  `prod` variant.
- CI runs the Elixir suite as `ce_test` only (ADR-008 D3, 2026-11-10).
- Still open: the end-to-end suite (`e2e_test`) and local `dev` compile
  `extra/lib`. Moving them to CE environments is tracked as a follow-up.
- Funnels in managed Qusto are a separate Qusto implementation, not
  Plausible's `extra/` code.

## Licence notices

- Files from Plausible keep their copyright and licence notices.
- The JavaScript tracker is MIT, `Copyright 2020 Plausible Insights OÜ`
  ([tracker/npm_package/LICENSE.md](tracker/npm_package/LICENSE.md)). A 2026-02
  branding change had replaced that line. It was restored on 2026-11-09.
- Third-party data attributions (for example GeoNames, CC BY 4.0) are listed in
  [NOTICE](NOTICE).
- The AGPL source offer for the running service is the in-app Source Code Offer
  page. It links the commit that is deployed.

## How upstream changes come in

- **Security fixes:** taken as soon as upstream publishes them.
- **Everything else:** merged in monthly slices from upstream `master`. Each
  slice goes through CI and the production deploy smoke gate.
- **Drift budget:** fewer than 50 Qusto-only commits outside the areas listed
  above (ADR-009).
- **Qusto UX:** not forked into CE. Qusto's product UX lives in the managed
  dashboard.

## Contributing back

Qusto has not yet contributed a change upstream. Fixes to upstream code that
would help every Plausible user (bugs, security, test reliability) should be
offered to `plausible/analytics` as pull requests rather than kept only here.

## Self-hosting

Build from source with `MIX_ENV=ce` (see [DEPLOYMENT.md](DEPLOYMENT.md)).
Versioned public images and an install guide are being prepared. Until they ship,
self-hosting this fork is community supported. Plausible's own Community Edition
guide describes Plausible CE, not this fork.

## Acknowledgements

- **Plausible Insights OÜ**, for creating and maintaining Plausible Analytics
- **Plausible contributors**, for their open-source work
