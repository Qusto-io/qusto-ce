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
- **Before committing a slice, diff every lockfile and manifest against
  pre-merge `main`** — `mix.lock`, `assets/package.json`, `tracker/package.json`
  (and their `package-lock.json`). Any version that is *newer* than upstream's
  because of a security fix must be kept (`mix deps.update <pkg>` /
  `npm install <pkg>@<ver>`), not regenerated back to upstream's pin. No alert
  will fire if you get this wrong: slice 3 (#164) silently reverted #138's
  cowboy 2.19.0 / cowlib 2.20.0 / plug_cowboy 2.9.0 (HTTP splitting).

  ```sh
  git diff <pre-merge-main> HEAD -- mix.lock assets/package.json tracker/package.json
  ```

- **Enforced for `mix.lock` by the `dep-downgrade-guard` check**
  (`.github/workflows/dep-downgrade-guard.yml` →
  `scripts/ci/check-dep-downgrades.sh`). It fails a PR that lowers the version of
  any package on its security-pin list (`cowboy cowlib plug_cowboy req mint
  phoenix finch`), comparing `mix.lock` at the PR base and head. Run it locally
  before opening the slice PR:

  ```sh
  scripts/ci/check-dep-downgrades.sh origin/main HEAD
  ```

  If a downgrade is genuinely intended, add the **`allow-dep-downgrade`** label
  and write the reason in the PR description; the check then passes with a
  warning.   Add a hex package to `SECURITY_PINS` in the script whenever we bump it
  ahead of upstream for a security reason. npm packages (`assets/` and
  `tracker/`) are guarded via `NPM_SECURITY_PINS` in the same script; add a
  package there when we apply a security-motivated npm bump ahead of a slice.

## Workflows: runner labels and triggers

Upstream runs CI on **`blacksmith-*` runners, which do not exist in the Qusto-io
org**. A job pinned to one queues forever, and `enforce-all-checks` then waits on
it until it times out. Slice 2026-06-30 (83973663d5) imported them into
`node.yml`, `tracker.yml`, `build-private-images-ghcr.yml` and
`tracker-script-update.yml`. Every PR from 2026-09-22 onward had a stuck NPM CI
run until #174 moved them back to `ubuntu-latest`. On every slice:

- `grep -rn 'blacksmith\|useblacksmith' .github/workflows/` must be empty.
  Replace `useblacksmith/*` actions with the `docker/*` equivalents.
- `build-private-images-ghcr.yml` must keep `pull_request.types` including
  `opened`. Its `build` job is a **required check**, and upstream's
  `[synchronize, labeled]` never reports on a PR opened with a single push.
- `tracker-script-update.yml` is upstream-only (Plausible bot token, `master`
  branch). It was removed in #33, re-imported by the slice, and removed again in
  #174. Keep it deleted.

## Divergence: what to retire, and what to leave alone (Phase 2)

Measured on the 2026-09-21 trial merge: **103 conflicts, 60 branding / 43 not**.
Taking the 43 apart changed the picture, so the rules below are the conclusions —
not guesses.

### Retired: branded binary assets → `merge=ours`

Logos, favicons and app icons are ours by definition, are binary (so git cannot
merge them and rerere cannot record a resolution), and conflicted on every merge
for no decision value. `.gitattributes` now pins them to our side. **103 → 98.**

Needs `git config merge.ours.driver true`, which `upstream-merge.sh setup` does.
Without it the attribute is inert and they conflict as before — it fails safe.

### Not divergence at all: action-version lag

Five workflow conflicts — `all-checks-pass`, `migrations-validation`, `codespell`,
`publish-docs`, `terraform-e2e` — are **purely** older pinned action SHAs. Nothing
Qusto-specific. Dependabot (now targeting `main`) closes them on its own, and its
bumps land on upstream's *exact* pins: PR #141 moves codespell to
`8f01853…# v2.2`, which is character-for-character what upstream has.

**Do not hand-edit these.** It duplicates Dependabot and conflicts with its open
PRs. Merge them instead.

### ⚠️ Do NOT converge `.github/workflows/elixir.yml`

An earlier draft of the Phase 2 plan said to move it back toward upstream's shape
(ours 202 lines, upstream's 308). **That is wrong and would break the repository.**

- Our `static` and `security` jobs are *named* `static` and `security`, and those
  exact strings are **required status checks** on `main`. Upstream's `static` is
  named "Static checks (format, credo, dialyzer)" and upstream has **no `security`
  job at all**. Converging renames one check and deletes the other, so both
  required contexts stop reporting and **every PR blocks forever**.
- Our `security` job is what runs `mix deps.audit` and `mix sobelow`. Upstream
  does not have it. Converging would silently delete security scanning.

This divergence is load-bearing. Keep it.

### Left alone deliberately

- **Storybook** — deleted here, kept upstream. Keep it deleted; written down so
  nobody re-litigates it mid-merge.
- **4 favicon PNGs** (`favicon-16x16/32x32` under `images/ce` and `images/ee`) —
  upstream deleted them in "Update the favicon set to SVG with an ICO fallback".
  They are unreferenced in our code, *but* `priv/static/cache_manifest.json` still
  lists them, so removing them means regenerating the Phoenix digest. Not worth
  coupling to a merge. These stay as modify/delete conflicts; standing answer is
  **keep ours**. (`merge=ours` cannot help: a merge driver never runs when one
  side deleted the file.)
- **`.tool-versions`** — upstream is on Erlang 28.5 / Elixir 1.20.4-otp-28; we are
  on 27.3.4.6 / 1.18.3. That is a real toolchain upgrade and belongs *inside* a
  Phase 3 slice, not a standalone convergence.
- **`mix.exs`** — the divergence is the project name/source_url (ours forever) and
  `elixirc_paths/1`, which is load-bearing for the CE build variant (ADR-008).

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

## Production deploy traceability (AGPL §13)

After a successful push-to-`main` deploy, GitHub Actions tags the deployed commit:

- Tag: `v<run_number>-ce` (matches `CE_VERSION` on beta1, e.g. `v121-ce`)
- Points at the **`main` commit that triggered the workflow** (same tree the host
  clones for `docker build`)
- Created only **after** the pre-swap smoke gate and on-host health check pass

Verify a running beta1 image against source:

```sh
TAG=v121-ce   # from qusto-ee .env CE_VERSION
git fetch --tags origin
git rev-parse "$TAG"
# Optional on beta1: docker inspect qusto-ce-ee --format '{{.Config.Image}}'
```

DRIFT-01 P1 (QUSTO-689): do not retag an existing `v*-ce` to a different SHA;
fix forward with the next deploy.

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
