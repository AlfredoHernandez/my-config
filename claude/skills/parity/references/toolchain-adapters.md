# Toolchain adapters

`export.py` turns one repo into one `inventory.json`, through an adapter. Adapters are the only
place that knows how a build system is shaped, which is what lets the rest of the tool be
platform-agnostic.

| adapter | detected by | modules from | tests from |
|---|---|---|---|
| `swift_spm` | any `Package.swift` | package dirs + `.target(name:)` | `@Test` (Swift Testing) and `func test…` (XCTest) |
| `xcodeproj` | `*.xcodeproj` / `*.xcworkspace` | projects + top-level source groups | same as `swift_spm` |
| `gradle_kts` / `gradle_groovy` | `settings.gradle[.kts]` | `include(":a:b")` | `@Test` + `fun` (backticked names kept) |
| `flutter` | `pubspec.yaml` | pubspec dirs | `test(` / `testWidgets(` |
| `rn` | `package.json` with react-native or expo | package dirs | `it(` / `test(` |
| `generic` | always matches, last | `declared_modules` in `pair.json` | declared globs |

## Adding one

A new adapter is a module in `scripts/adapters/` exposing `NAME`, `MARKERS`, `SOURCE_SUFFIXES`,
`DEFAULTS`, `detect(root, files)`, `modules`, `features`, `strings`, `capabilities`. Tests, CI,
telemetry and design tokens are already shared in `common.py` — do not reimplement them.

## Rules an adapter must not break

- **No absolute paths in output.** Everything is repo-relative POSIX. An absolute path in an
  inventory is how a tool stops working on anyone else's machine, and how a repo starts depending
  on where it happens to be checked out.
- **Deterministic.** Sort everything; never read the clock; never depend on directory order. Two
  runs over an unchanged tree produce identical bytes. An audit that is not reproducible cannot
  settle an argument.
- **No builds, no network.** Regex and the filesystem only, so an audit costs seconds and works
  offline on a repo that does not currently compile.
- **Never read another platform.** An adapter receives one root. That is the whole design.

## Opt-in axes

Telemetry and design tokens have no portable shape, so they stay off until a project declares how
to find them:

```json
"telemetry": { "paths": ["**/Telemetry/**"], "pattern": "Event\\.([a-zA-Z_]+)" }
```

Capture group 1 is the name. A guessed default here would manufacture gaps that do not exist, which
is worse than the axis being absent.

## Calibrating a real pair

`--detect-only` reports the toolchain, modules and feature candidates without a contract. Use it
first, always, and read the output before proposing a map:

- Test trees mirror feature trees, so they look identical to any path heuristic. They are already
  excluded via `test_path_globs`; if a test dir still shows up as a feature, fix the globs rather
  than the map.
- A module that exists on one side and not the other is the interesting finding. Do not "fix" it in
  the map — that is precisely the thing the audit is for.
