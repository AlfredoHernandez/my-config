# Equivalence across platforms

Parity is **behavioural**, never line-by-line. Two apps are at parity when a user can do the same
things and get the same answers — not when their files look alike. Transliterated code passes an
audit and fights the platform it runs on.

## Layers

The layers must correspond; the names must be idiomatic per platform.

| layer | Apple | Android | the property that must hold |
|---|---|---|---|
| domain | a package importing no UI/network/storage framework | a module enforced by a layering test | compiles with nothing outward |
| ports | protocols the domain declares | interfaces the domain declares | declared inward, satisfied outward |
| adapters | one type per framework | one module or class per framework | swapping one touches one file |
| composition root | the app target's dependency wiring | DI modules in the app module | the only place that knows which build this is |
| presentation | `@Observable` model beside the view | `ViewModel` exposing immutable state | views lay out values, never decide them |
| test kit | shared doubles and fixtures target | shared doubles and fixtures module | both read `parity/fixtures/` |

If one platform enforces a layer with a test and the other enforces it by package boundaries, that
is parity — the constraint is checked either way. If one enforces it and the other only intends it,
that is a gap on the axis of architecture, and it will become a gap in behaviour.

## Test kinds

Map kinds by what they *reach*, not by the framework's name for them.

| kind | reaches | Apple | Android |
|---|---|---|---|
| unit | one type, no I/O | Swift Testing / XCTest | JUnit / Kotest |
| contract | a port's guarantees, driven by shared fixtures | a shared contract suite | a shared contract suite |
| integration | several real collaborators | integration target | `src/test` with real wiring |
| acceptance | a use case end to end, no UI | acceptance target | acceptance tests |
| screenshot | what a screen looks like | snapshot images | Roborazzi / Paparazzi |
| ui | the OS driving the app | XCUITest | Espresso / instrumented |

Two rules that matter more than the table:

- A criterion covered by a unit test on one platform and only by a UI test on the other is **not**
  at parity. The slow, flaky one will be deleted or ignored first, and then the coverage is gone.
- Screenshot tests prove what a screen looks like, never what it decides. They do not substitute
  for a test of the decision.

## CI roles

Compare by role, not by pipeline shape. Declare roles in `pair.json` and let each platform satisfy
them however its ecosystem does:

`lint` · `unit-tests` · `ui-tests` · `screenshot-verify` · `build` · `sign` · `publish` ·
`release-notes`

A platform whose releases are cut by hand while the other publishes from CI is a **high-priority
gap**, not a stylistic difference: it is the axis where a human forgets a step under time pressure,
and it is invisible in the app's own code.

## UI/UX

- Compare **design tokens** — spacing scale, color roles, type ramp, corner radii, motion
  durations — by name and value. Never compare pixels: identical pixels across platforms means one
  of them is fighting its own conventions.
- Compare the **state set** per screen: loading, empty, error, stale, offline, permission-denied,
  signed-out. A missing state is the most common real UX gap and the easiest to miss by reading code.
- Compare **navigation semantics**, not gestures. Back-with-unsaved-changes must behave the same;
  how the user asks for it is the platform's business.
- Compare **copy through the contract**. Same neutral key, same meaning. A string that exists on one
  platform only is either a missing feature or a leaked internal — both worth knowing.

## Error taxonomy

The same domain error must produce the same user-facing meaning on both platforms. Divergence here
is invisible in tests, obvious to users, and reads as two different products.
