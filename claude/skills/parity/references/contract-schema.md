# The parity contract

Four files plus fixtures, mirrored byte-identically into every repo of the pair, under `parity/`.
`CONTRACT.lock` is generated — never edit it, and never edit the others by hand either: edit via
`/parity spec` and run `/parity sync`.

## Why JSON and not YAML

The contract is read by the tool, by each repo's guard, and by CI. JSON is in the standard library
of every runtime involved, so a guard has zero dependencies and the lock is a byte-for-byte
checksum with no serializer ambiguity. Prose does not belong here anyway: it lives in each repo's
feature docs, and the contract points at it with `spec`. Keeping prose out of the contract is what
makes it safe to checksum.

## `pair.json`

```json
{
  "schema": 1,
  "product": "Demo",
  "axes": ["features", "tests", "strings", "ci", "capabilities"],
  "platforms": {
    "ios":     { "label": "iOS",     "toolchain": "swift_spm" },
    "android": { "label": "Android", "toolchain": "gradle_kts" }
  },
  "modules":  { "domain": { "ios": ["DemoDomain"], "android": [":core:model"] } },
  "features": { "wallet": { "ios": ["DemoApp/Features/Wallet"], "android": [":feature:wallet"] } },
  "ci_roles": { "release": { "ios": ["release*"], "android": ["release*", "publish*"] } },
  "capability_roles": { "notifications": { "ios": ["aps-environment"], "android": ["*POST_NOTIFICATIONS"] } }
}
```

- `axes` turns whole dimensions on and off. A project with no telemetry must not be shown telemetry
  gaps; a fabricated gap costs more trust than a missed one.
- `modules` and `features` are the equivalence maps. **Declared, never inferred from names.** Two
  modules doing the same job are routinely called unrelated things.
- `ci_roles` and `capability_roles` are glob patterns per platform. `[]` means "this platform is
  not expected to satisfy this role"; omitting the platform means undeclared, which surfaces as
  `unknown`.
- Per-platform extras live inside the platform entry: `feature_globs`, `test_kinds`,
  `test_path_globs`, `strings_paths`, `telemetry`, `design_tokens`, `declared_modules`.

## `features.json`

```json
{
  "schema": 1,
  "features": [{
    "id": "wallet.balance",
    "story": "The customer sees their balance when they open the wallet",
    "spec": "docs/features.md#wallet",
    "fixtures": ["fixtures/wallet-balance.json"],
    "criteria": [{
      "id": "shows-cached-balance-offline",
      "owners": {
        "ios":     { "impl": ["DemoApp/Features/Wallet/**"], "tests": ["WalletModelTests"] },
        "android": { "impl": ["feature/wallet/**"], "tests": ["WalletViewModelTest"] }
      }
    }],
    "deviations": [{
      "platform": "android",
      "criteria": ["streams-live-balance-in-background"],
      "reason": "continuous background streaming is not grantable under Doze",
      "constraint": "os",
      "evidence": "docs/android-background.md"
    }]
  }]
}
```

### The four states, and only four

| state | how it arises | what it means |
|---|---|---|
| `parity` | owner declared, impl found, named suites exist | verified on this platform |
| `gap` | owner `{"status":"missing"}`, or impl/tests absent | known, priced debt |
| `deviation` | a deviation covers this platform and criterion | divergence that is correct |
| `unknown` | the contract says nothing about this platform | **nobody has decided yet** |

`unknown` is the highest-priority finding in the report. Known debt has been looked at; an
`unknown` is a question no one has asked. This is also why you must never invent an owner to make a
row look tidy — that converts a question into invisible debt.

A deviation with no `evidence` is itself reported as `unknown·contract`. "The OS won't let us" is a
claim, and a claim without a citation is how real debt gets laundered into an accepted difference.

Omitting `criteria` from a deviation scopes it to the whole feature.

## `strings.json` and `telemetry.json`

```json
{ "schema": 1, "keys":   { "wallet.title": { "ios": "wallet.title", "android": "wallet_title" } } }
{ "schema": 1, "events": { "wallet_opened": { "ios": "walletOpened", "android": "wallet_opened" } } }
```

One neutral key, one resource name per platform. Each platform is checked against the contract and
never against another platform's catalog — that is the whole point. `null` for a platform means the
key deliberately does not apply there.

A resource a platform defines but the contract does not know about is reported `unknown`: no other
platform can be held to a key that was never written down.

## `fixtures/*.json`

```json
{ "cases": [{ "given": { "cents": 1234 }, "expect": { "formatted": "$12.34" } }] }
```

Free-form beyond `cases`; what matters is that **both platforms' contract tests read the same
file**. The shape is the feature's business language, not a framework's. Put the arithmetic here —
rounding, currency, date boundaries, tiering — because that is where platforms silently drift and
where two suites reading the same numbers proves they did not.

## `CONTRACT.lock`

```json
{ "schema": 1, "files": { "features.json": "<sha256>" }, "contract": "<sha256 of all entries>" }
```

Two independent checks, deliberately:

- Each repo's own guard compares its files to its own lock. Catches hand edits. Needs nothing else.
- The tool compares the aggregate `contract` hash across repos. Catches mirrors drifting apart.
  This one never runs inside an app's CI.
