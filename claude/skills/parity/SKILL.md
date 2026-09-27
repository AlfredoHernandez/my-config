---
name: parity
description: "Keep two or more platform apps (iOS / Android / Flutter / React Native) at parity — same features, same business logic, same tests, same CI. Audits both sides and says what each one is missing, ports a feature to the lagging platform, specs a feature neutrally before either side is written, or scaffolds a fresh pair. Works on apps already written and on greenfield."
argument-hint: "<list|init|audit|spec|port|sync|guard|scaffold> [args]"
user-invocable: true
---

# Parity

You act as a **software architect**. You own the parity contract and the verdicts; you delegate
the code.

## The one rule that shapes everything

> **Every cross-repo read is replaced by two self-contained validations against a mirrored neutral
> contract.**

No repository reads another. No repository depends on an extra repository. Each repo carries a
byte-identical copy of `parity/` and validates **only its own side** against it. The comparison
across platforms is done by the tool, outside every repo, so each app's CI can be green on its own
in a clean checkout.

The antipattern this exists to kill: a test in repo A that reads repo B by absolute path and
*skips itself* when B is absent. It couples two suites, cannot run in clean CI, and when it cannot
run **parity silently stops being verified while the build stays green**. If you ever find yourself
writing a check that reaches across repos, you have made a mistake — put it in the tool.

The second rule: **separate extraction from judgment.** The scripts count; you interpret. Never
tally tests, modules, or strings by reading files yourself — an audit assembled by eye cannot be
reproduced, and an audit that cannot be reproduced does not change anyone's mind. If a number
appears in your output, a script produced it.

## Layout

```
$SKILL/scripts/list.py        every platform's features, and which ones the contract pairs
$SKILL/scripts/export.py      one repo  → inventory.json     (never sees a sibling)
$SKILL/scripts/compare.py     N inventories + contract → matrix + backlog
$SKILL/scripts/sync.py        mirror the contract across repos, recompute locks
$SKILL/templates/guard.py     the self-contained per-repo gate
```

Read `references/contract-schema.md` before touching any contract file. Read
`references/deviation-catalog.md` before ruling anything a deviation. Read
`references/toolchain-adapters.md` when a repo's toolchain is unusual, and
`references/guards.md` before wiring CI.

## Resolving the pair

1. Read `parity/pair.json` in the current repo. It declares the platforms, the module map, the
   feature map and the axes — and **no machine paths**.
2. Read `.parity.local.json` (gitignored) for sibling locations:
   `{"repos": {"ios": "/abs/path", "android": "/abs/path"}}`. If it is missing, ask the user for
   the sibling paths and write it. Never invent paths from directory conventions — sibling repos
   are routinely named differently, and a wrong guess audits the wrong tree.
3. If neither exists, this pair has never been initialized: run **init**.

A parent workspace folder (`<Product>/{app-ios,app-android}`) is a convenience for reports only.
Nothing may depend on it existing.

---

## Mode: list

"What features exist on each side, and which ones line up." Read-only, and the cheapest way in —
it works before a contract exists.

```bash
python3 $SKILL/scripts/list.py --root ios=<repo> --root android=<repo> [--json]
```

It finds the contract by itself in whichever repo has one, or takes `--contract <repo>`. Each
mapped feature comes back `paired` (found on every declared platform), `partial` (the contract
declares it for some platforms only) or `stale` (declared, and the code no longer has it — a
mapping that rotted). Anything the contract does not claim is listed separately per platform.

Two things to say out loud whenever you show this:

- **Without a contract, nothing is paired.** The entries are candidates detected from directory and
  module structure, and names rarely correspond across platforms. Reading that raw list as a diff
  invents missing features in both directions. Point the user at `init`.
- **Pairing is not parity.** A feature on both sides can still be missing half its behaviour and all
  of its tests. `audit` is what rules on that; `list` only says what exists.

## Mode: init

Bootstrapping, idempotent, for a pair that already has code.

1. `export.py --root <repo> --detect-only` on each repo. This reports the toolchain, the modules
   and the feature candidates without needing a contract.
2. Propose `parity/pair.json`: platforms, axes, and the **module and feature maps**. Derive the
   mapping from what the code does, not from what things are called. Equivalent modules routinely
   have unrelated names (`FooDomain` ↔ `:core:model`), and a name-based guess produces a report
   full of features that "only exist on one platform" when they exist on both.
3. Show the proposed mapping to the user and get it confirmed **before** seeding anything. A wrong
   map makes every later verdict wrong.
4. Seed `features.json` from whatever specs already exist (Gherkin docs, acceptance tests, use-case
   docs). Mark a criterion `{"status": "missing"}` only when you have checked; otherwise leave the
   platform out so it surfaces as `unknown`. **Never guess an owner into existence** — a fabricated
   owner is invisible debt, while `unknown` is a question someone will answer.
5. `sync.py --from <repo> --to <others>` to mirror and lock.
6. Add `.parity.local.json` to each repo's `.gitignore`.

## Mode: audit

Read-only. The main mode.

1. Resolve the pair. Run `export.py` per repo — in parallel, via the `platform-inventory` agent so
   file listings stay out of your context.
2. `compare.py --contract <repo> --inventory <p>=<path> ... --out-json --out-md`.
3. Hand the matrix and findings to the `cross-platform-architect` agent for the verdict. Give it
   the JSON, never the repos.
4. Write the report to `parity-reports/<YYYY-MM-DD>-audit.md` next to the repos (or to the
   workspace root when there is one) and summarize in chat: the verdict counts, then the top
   findings with their next steps.

Judgment rules:

- `unknown` outranks every gap. Undecided is worse than known debt, because debt has been priced.
- A gap in business logic outranks a gap in tests, which outranks CI, which outranks resources.
- Never rule something a `deviation` without an OS constraint you can name and evidence to cite.
  Marking a real limitation as debt burns the tool's credibility on its first run; marking real
  debt as a deviation is how parity quietly dies.
- Report what the scripts found. If a number surprises you, check the mapping in `pair.json`
  before doubting the script — a stale map is the usual cause.

## Mode: spec

For a feature that does not exist yet on any platform, or one being formalized.

1. Write the prose where prose belongs: the repo's own feature docs. The contract holds ids,
   owners, statuses and deviations, and points at the prose.
2. Add the feature to `features.json` with its criteria, strings, telemetry and fixtures. Leave
   every owner `{"status": "missing"}` — nothing is implemented yet.
3. Extract the arithmetic into `parity/fixtures/<feature>.json` as inputs and exact expected
   outputs. This is the strongest parity guarantee available: two suites in two languages reading
   the same numbers, with no shared runtime and no cross-repo read.
4. `sync.py` and report which platforms now owe work.

## Mode: port

Implement a feature on the lagging platform, driven by the contract.

1. Read the criteria the target platform does not satisfy. These are your failing tests.
2. Delegate to the platform's TDD architect — `swift-tdd-architect` for Apple,
   `kotlin-tdd-architect` for Android/Kotlin — with the criteria, the fixtures, and the sibling's
   implementation **as reference only**. The target must end up idiomatic for its platform:
   transliterating the other platform's code produces something that passes the audit and fights
   the OS. Parity is behavioural, never line-by-line.
3. Tests first, from the fixtures. The same fixture file must drive both platforms' contract tests.
4. Update the owners in `features.json`, `sync.py`, re-run the guard, re-audit the feature.

## Mode: sync

`sync.py --from <repo> --to <others>`. Use `--check` to detect drift without writing. Never
hand-edit a contract file in one repo: the lock will catch it, and the fix is always to edit via
`spec` and re-sync.

## Mode: guard

1. Write `templates/guard.py` into each repo's `parity/` with `@PLATFORM@` replaced by that repo's
   platform id.
2. Wire it into that repo's own CI as a step that runs `python3 parity/guard.py`. It needs nothing
   but the repo and a Python 3 interpreter.
3. Do **not** wire the cross-platform comparison into an app's CI. That gate belongs to the tool,
   or to a workspace-level job that checks out both repos deliberately.
4. Verify the wiring by removing the contract and confirming the step goes **red**. A guard that
   skips when its inputs are missing is a guard that reports green while verifying nothing.

## Mode: scaffold

Greenfield, `--platforms ios,android`.

1. Create the workspace and one repo per platform, with mirrored layers: domain free of any
   framework, ports the domain declares and the composition root satisfies, adapters behind those
   ports, presentation with no logic in the views. The layers must correspond; the names must be
   idiomatic per platform.
2. Write `pair.json` with the module map filled in from what you just created, an empty
   `features.json`, and a test kit on each side that can read `parity/fixtures/`.
3. Generate the guards and each repo's own CI.
4. Run `audit` — it must report total parity over zero features. If it does not, the scaffold is
   wrong, not the audit.

---

## Boundaries

- Modes `list`, `audit`, `sync --check` and `init --detect-only` are read-only. Everything else writes.
- Before writing a contract into repos that had none, show the user what will be written and where.
- Removing an existing cross-repo parity check is a behaviour change to someone's CI: replace it
  with the self-contained guards in the **same** change, and confirm both repos are green in a
  clean checkout before calling it done.
- Deleting or rewriting a test is never a way to close a gap.
