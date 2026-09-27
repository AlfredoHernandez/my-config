# Guards and CI

Two levels, and the split is the whole design.

## Level 1 — in each repo, self-contained, always wired

`parity/guard.py`, generated from `templates/guard.py` with the platform id baked in. Standard
library only, reads one repo, no sibling needed. It checks:

- **Lock integrity** — its own `parity/` files match its own `CONTRACT.lock`. Catches hand edits.
- **Its own criteria** — every criterion this platform owns has an implementation matching the
  contract's globs and every test suite the contract names.
- **Its own resources** — every string and telemetry name the contract assigns to this platform
  exists here.
- **Its own fixtures** — every fixture the contract references is present.

Wire it as an ordinary step in that repo's existing pipeline:

```yaml
- run: python3 parity/guard.py
```

It does **not** check declared debt. A criterion marked `{"status": "missing"}` passes the guard, on
purpose: a repo must be able to commit honest debt and stay green. Debt is the audit's job to
report and a human's to schedule.

## Level 2 — cross-platform, in the tool, never in an app's CI

`compare.py` is the only thing that sees more than one platform. Run it from `/parity audit`, or
from a workspace-level job that checks out both repos on purpose.

**Never put it in an app's pipeline.** The moment repo A's build needs repo B on disk, one of two
things happens: the build breaks for everyone who has only one repo, or someone makes the check skip
itself when B is absent — and then it reports green while verifying nothing, which is strictly worse
than not having it.

## Replacing an existing cross-repo check

If a pair already has a test that reads the sibling by path:

1. Write the neutral contract for whatever it was checking (usually `strings.json`).
2. Generate both guards and confirm each one catches a deliberately broken resource on its own side.
3. Delete the cross-repo test **in the same change**. Leaving both means the old failure mode stays.
4. Verify in a clean checkout, with the sibling absent, that both repos are green and **nothing is
   skipped**. Any skip means the replacement inherited the disease.
5. Update the repo docs that described the old mechanism. A stale instruction telling people to
   update a mapping file that no longer exists costs the next person an hour.

## Wiring is not done until you have seen it go red

Remove the contract, or break a mapped resource, and confirm the step fails. A guard nobody has seen
fail is a guard nobody knows works.
