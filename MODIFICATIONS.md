# Modifications

Date: 2026-11-11

Qusto Community Edition is derived from Plausible Analytics. The upstream merge-base of this tree is `27cbc4419c`. This file is the dated record that the work has been modified. It is not a generated diff. A later check regenerates it from the merge log of each `v*-ce` tag.

## Changes from upstream

- ClickHouse database renamed from `plausible_events_db` to `qusto`
- JavaScript tracker global: `window.qusto` is primary, and `window.plausible` remains as a compatibility shim
- Custom events: `product_view`, `add_to_cart`, `purchase`
- AI referrer detection for ChatGPT, Perplexity, Claude, Gemini
- Geo-name fields on the public stats API. There is no private bridge between this repository and the managed service

The files under `extra/` are Plausible's. `extra/COPYING.txt` is unchanged. This record does not claim a right to those files.

All modifications in this repository are under the GNU AGPL v3.0, the same licence as the upstream work.
