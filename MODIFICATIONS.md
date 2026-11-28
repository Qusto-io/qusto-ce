# Modifications

Date: 2026-11-11

Qusto Community Edition is derived from Plausible Analytics. The upstream merge-base of this tree is `27cbc4419c`. This file is the dated record that the work has been modified. It is not a generated diff. A later check regenerates it from the merge log of each `v*-ce` tag.

## Changes from upstream

- ClickHouse database renamed from `plausible_events_db` to `qusto`
- JavaScript tracker global: `window.qusto` is primary, and `window.plausible` remains as a compatibility shim
- Custom events: `product_view`, `add_to_cart`, `purchase`
- AI referrer detection for ChatGPT, Perplexity, Claude, Gemini
- Geo-name fields on the public stats API. There is no private bridge between this repository and the managed service
- `POST /api/v1/sites` and `DELETE /api/v1/sites/:domain` write and remove a site row for managed Qusto. The token is `QUSTO_PROVISION_TOKEN`. An empty timezone is stored as `Europe/Berlin`. The write is `sites` plus `site_memberships` for team 1 and user 1. It does not call `Plausible.Sites.create/3`

`extra/` is not in this tree. It remains on tags published before this removal. Those files are Plausible's, and this record does not claim a right to them. No Mix environment compiles them.

All modifications in this repository are under the GNU AGPL v3.0, the same licence as the upstream work.
