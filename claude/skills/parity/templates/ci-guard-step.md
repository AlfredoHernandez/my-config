# Wiring the guard into a repo's own CI

One step, in the repository's existing pipeline. No sibling checkout, no extra repo, no
dependencies beyond a Python 3 interpreter.

## GitHub Actions

```yaml
      - name: Parity guard
        run: python3 parity/guard.py
```

Put it beside lint, before the long test job: it is fast, and a contract that has drifted makes the
rest of the run's parity claims meaningless.

## Gradle

```kotlin
tasks.register<Exec>("parityGuard") {
  commandLine("python3", "parity/guard.py")
}
tasks.named("check") { dependsOn("parityGuard") }
```

## Xcode Cloud / local script phase

```bash
python3 "$CI_PRIMARY_REPOSITORY_PATH/parity/guard.py"
```

## Makefile

```make
parity:
	python3 parity/guard.py
```

## What must NOT go here

The cross-platform comparison. `compare.py` needs every platform's inventory, so putting it in one
app's pipeline makes that app's build depend on a sibling checkout. Someone will then make it skip
itself when the sibling is absent, and from that day the build is green while nothing is verified.
That gate belongs to the tool, or to a workspace-level job that checks out both repos deliberately.

## Not done until you have seen it go red

Break something on purpose — delete `parity/pair.json`, or rename a string the contract maps — and
confirm the step fails. A guard nobody has watched fail is a guard nobody knows works.
