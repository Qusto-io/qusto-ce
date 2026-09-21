# Shared rerere resolution cache

`git rerere` records how a merge conflict was resolved and replays that
resolution the next time the same conflict appears. Its cache lives in
`.git/rr-cache`, which is not version controlled — so it would be per-clone and
per-machine, and every upstream merge would re-resolve the same branding
conflicts from scratch.

This directory is that cache, tracked, so a resolution is decided **once**.

Do not edit by hand. Use:

    scripts/ops/upstream-merge.sh setup   # load these into .git/rr-cache
    scripts/ops/upstream-merge.sh save    # export new resolutions back here

Each subdirectory is one conflict, named by rerere's hash of the conflict text,
containing `preimage` (the conflict) and `postimage` (how it was resolved).

**A wrong resolution in here is replayed forever, silently.** If one turns out to
be wrong, delete its directory and re-resolve on the next merge.

Empty for now: it fills during the DRIFT-01 Phase 3 merge slices, where the
resolutions get made under review. See `docs/UPSTREAM_MERGE_PLAYBOOK.md`.
