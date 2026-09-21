# Upstream merge playbook

How to merge `plausible/analytics` into `qusto-ce` without re-deciding the same
questions every time. DRIFT-01 Phase 1.

`qusto-ce` is a long-lived fork that **rebranded in place**. That makes conflicts
permanent rather than occasional: ~58% of the files that conflict do so because
a branded string sits on a line upstream also edits. This playbook exists so
that cost is paid once per conflict instead of once per merge.

## Before the first merge on a machine

```sh
scripts/ops/upstream-merge.sh setup
```

Enables `rerere` + `rerere.autoupdate`, adds the `upstream` remote, and loads the
shared resolution cache from `.rerere-cache/` into `.git/rr-cache`.

`rerere.enabled` is **local config** — git cannot carry it in the repo, so every
clone needs this once.

## The loop

```sh
scripts/ops/upstream-merge.sh status            # how far behind are we
scripts/ops/upstream-merge.sh slice 2026-03-31  # prints the target commit
git merge <target>                              # you run it, you see the conflicts
# ...resolve per the table below...
git commit                                      # rerere records postimages HERE
scripts/ops/upstream-merge.sh save              # export to .rerere-cache/
git add .rerere-cache && git commit -m "chore: record merge resolutions"
```

**`save` after `git commit`, not before.** rerere writes the *preimage* when the
conflict appears but the *postimage* only when the merge is committed. Run `save`
too early and it correctly exports nothing — it refuses to share entries that
have a preimage and no postimage, because those record "we got stuck", not a
resolution.

## Standing resolutions

| Conflict is about | Resolution |
|---|---|
| Product name in prose ("Welcome to Qusto") | **Keep ours** |
| Logos, images, favicons, other binary assets | **Keep ours** |
| Logic, bug fixes, tests, **security fixes** | **Take theirs** |
| Upstream adds a target/function next to our branded line | **Both** — keep our string, take their addition |
| `mix.lock`, `package-lock.json` | **Regenerate**, never hand-merge |
| `.tool-versions` | Take theirs unless it breaks the build; upstream drives the toolchain |
| Storybook | Keep it deleted (Qusto removed it deliberately; upstream keeps it) |
| `.github/workflows/*` | Case by case — see "gratuitous divergence" below |

The fourth row is the one that bites. "Keep ours" is about the *branding*, not
the hunk: upstream frequently adds real content adjacent to a branded line, and
a reflexive `--ours` silently drops it. The `Makefile` conflict in slice 1 is
exactly this — our branded header versus upstream's new `.PHONY` line. Correct
answer is both.

## Always run both test environments

```sh
MIX_ENV=test    mix test      # EE mode — compiles extra/lib
MIX_ENV=ce_test mix test      # CE mode — does not
```

A change can pass one and fail the other; that has happened more than once. If
`ce_test` reports `column u0.trial_expiry_date does not exist`, the local
`ce_test` database is stale: `MIX_ENV=ce_test mix ecto.drop/create/migrate`.

## Lockfiles

- `mix.lock` — regenerate with `mix deps.get`. Platform independent.
- `assets/` and `tracker/` `package-lock.json` — **must be generated on Linux /
  Node 24**. npm on macOS drops the Linux-only optional `@emnapi/*` packages and
  CI then fails `npm ci` with `EUSAGE`.

## Gratuitous divergence

Some conflicts buy nothing and should be retired rather than re-resolved forever
(DRIFT-01 Phase 2):

- `.github/workflows/elixir.yml` — ours is 202 lines, upstream's 308. Establish
  what Qusto actually needs and move back toward upstream's shape.
- Storybook — deleted here, kept upstream. Keeping the deletion is fine; the
  point is that it is written down so nobody re-litigates it mid-merge.

## Slice, don't leap

Measured on the real repository, 2026-09-21:

| Merge | Conflicted files |
|---|---|
| Full jump (421 commits, base 2026-01-07) | **103** |
| Slice 1 only (to 2026-03-31, 115 commits) | **37** |

Conflicts scale with the *overlap* between two change sets, so three slices cost
far less than one leap — and each is small enough to actually review. Suggested
slices: `2026-03-31`, `2026-06-30`, then current.

Merging to `main` **deploys to production** (ADR-008), so each slice ships on its
own and must pass the Phase 0 smoke gate.

## A warning about rerere

rerere replays a *recorded* resolution faithfully — including a wrong one, on
every future merge, silently. So:

- Review the first merge of each slice properly. Do not trust auto-resolution
  because it is convenient.
- `upstream-merge.sh slice` deliberately does **not** run the merge for you.
- If a resolution turns out to be wrong, delete its directory from
  `.rerere-cache/` and re-resolve; otherwise it outlives the mistake.

## Cadence

Monthly (DRIFT-01 Phase 4). `.github/workflows/upstream-drift.yml` reports the
gap every Monday and raises an issue past the threshold or on any upstream commit
that looks security-relevant. Falling behind again is what produced the funnel
tooltip XSS that sat unmerged in the gap for months.
