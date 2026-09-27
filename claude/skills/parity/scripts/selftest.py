#!/usr/bin/env python3
"""Self-test for the parity toolchain. No network, no fixtures on disk, seconds to run.

Builds a throwaway pair in a temp directory with defects planted on purpose, then
asserts the tool finds exactly those and nothing else. The point is the tool's own
regression guard: every claim the skill makes about determinism, isolation,
fail-not-skip, and layout-independence is checked here rather than asserted in prose.

The pair is deliberately built with modules that do NOT correspond across
platforms. Two apps can be at full parity with different architectures, and a
tool that cannot express that is measuring the wrong thing.

    python3 selftest.py
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
SKILL = SCRIPTS.parent
sys.path.insert(0, str(SCRIPTS))
FAILURES: list[str] = []

CRITERIA = (
    "cached-offline",
    "refreshes-on-appear",
    "hides-while-locked",
    "background-stream",
    "untested",
    "missing-case",
    "legacy-impl",
)


def check(condition: bool, label: str) -> None:
    print(f"  {'ok  ' if condition else 'FAIL'} {label}")
    if not condition:
        FAILURES.append(label)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def run(*args: str, cwd: Path | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, *args], cwd=cwd, capture_output=True, text=True, check=False
    )


def audit(contract: Path, out: Path, **inventories: Path) -> dict:
    args = [str(SCRIPTS / "compare.py"), "--contract", str(contract)]
    for platform, path in inventories.items():
        args += ["--inventory", f"{platform}={path}"]
    args += ["--out-json", str(out)]
    result = run(*args)
    if result.returncode != 0:
        raise SystemExit(f"selftest: compare.py failed — {result.stderr}")
    return json.loads(out.read_text())


def export_all(ios: Path, android: Path, out: Path) -> tuple[Path, Path]:
    for name, repo in (("ios", ios), ("android", android)):
        result = run(str(SCRIPTS / "export.py"), "--root", str(repo), "--platform", name,
                     "--out", str(out / f"{name}.json"))
        if result.returncode != 0:
            raise SystemExit(f"selftest: export failed for {name} — {result.stderr}")
    return out / "ios.json", out / "android.json"


def findings_of(matrix: dict) -> set[tuple]:
    return {(f["status"], f["axis"], f["platform"], f["subject"]) for f in matrix["findings"]}


def android_status(matrix: dict, criterion: str) -> str:
    return platform_status(matrix, "android", criterion)


def platform_status(matrix: dict, platform: str, criterion: str) -> str:
    for feature in matrix["matrix"]:
        for cell in feature["criteria"]:
            if cell["id"] == criterion:
                return cell["platforms"].get(platform, {}).get("status", "absent")
    return "absent"


def pair_json(axes: list[str], extra: dict | None = None) -> str:
    pair = {
        "schema": 1, "product": "Demo",
        "axes": axes,
        "platforms": {"ios": {"toolchain": "swift_spm"}, "android": {"toolchain": "gradle_kts"}},
        "features": {"wallet": {"ios": ["DemoApp/Features/Wallet"], "android": [":feature:wallet"]}},
        "ci_roles": {"unit-tests": {"ios": ["*test*"], "android": ["check"]}},
    }
    pair.update(extra or {})
    return json.dumps(pair, indent=2)


def features_json() -> str:
    def criterion(cid: str, ios: dict | None, android: dict | None) -> dict:
        owners = {}
        if ios is not None:
            owners["ios"] = ios
        if android is not None:
            owners["android"] = android
        return {"id": cid, "doc": f"use-cases/wallet.balance/{cid}.md", "owners": owners}

    return json.dumps({
        "schema": 1,
        "features": [{
            "id": "wallet.balance",
            "fixtures": ["fixtures/wallet.json"],
            "criteria": [
                # The case this whole change exists for: evidence, no location at all.
                criterion("cached-offline",
                          {"tests": ["WalletModelTests#shows the cached balance when offline"]},
                          {"tests": ["WalletViewModelTest"]}),
                criterion("refreshes-on-appear",
                          {"tests": ["WalletModelTests#refreshes on appear"],
                           "location": ["DemoApp/Features/Wallet/**"]},
                          {"tests": ["WalletRefreshTest"]}),
                # Location points at a path that no longer exists; the tests are intact.
                criterion("hides-while-locked",
                          {"tests": ["WalletModelTests"], "location": ["DemoApp/Features/Vault/**"]},
                          {"status": "missing"}),
                criterion("background-stream", {"tests": ["WalletModelTests"]}, None),
                criterion("untested",
                          {"location": ["DemoApp/Features/Wallet/**"]},
                          {"tests": ["WalletViewModelTest"]}),
                criterion("missing-case",
                          {"tests": ["WalletModelTests#no such case"]},
                          {"tests": ["WalletViewModelTest"]}),
                # `impl` is the deprecated spelling of `location` and must still work.
                criterion("legacy-impl",
                          {"impl": ["DemoApp/Features/Wallet/**"], "tests": ["WalletModelTests"]},
                          {"tests": ["WalletViewModelTest"]}),
            ],
            "deviations": [{"platform": "android", "criteria": ["background-stream"],
                            "reason": "not grantable under Doze", "constraint": "os",
                            "evidence": "docs/background.md"}],
        }],
    }, indent=2)


def build_pair(base: Path) -> tuple[Path, Path]:
    ios, android = base / "demo-ios", base / "demo-android"

    write(ios / "Package.swift", '.target(name: "DemoDomain")\n')
    write(ios / "DemoApp/Features/Wallet/WalletModel.swift", "final class WalletModel {}\n")
    write(ios / "DemoApp/Features/Settings/SettingsView.swift", "struct SettingsView {}\n")
    write(ios / "DemoDomain/Sources/DemoDomain/UseCases/FetchBalance.swift",
          "public struct FetchBalance {}\n")
    write(ios / "DemoDomain/Sources/DemoDomain/UseCases/FormatMoney.swift",
          "public struct FormatMoney {}\n")
    write(
        ios / "DemoTests/WalletModelTests.swift",
        "@Suite struct WalletModelTests {\n"
        "  @Test func `shows the cached balance when offline`() {}\n"
        "  @Test func `refreshes on appear`() {}\n}\n",
    )
    write(
        ios / "Resources/Localizable.xcstrings",
        json.dumps({"strings": {"wallet.title": {}, "settings.title": {}}}),
    )
    write(ios / ".github/workflows/ci.yml", "jobs:\n  unit-tests:\n    runs-on: macos-15\n")

    # Module names correspond to nothing on the other side, on purpose.
    write(android / "settings.gradle.kts", 'include(":core:model")\ninclude(":feature:wallet")\n')
    write(android / "feature/wallet/src/main/kotlin/WalletViewModel.kt", "class WalletViewModel\n")
    write(android / "core/model/src/main/kotlin/usecase/FetchBalance.kt", "class FetchBalance\n")
    write(
        android / "feature/wallet/src/test/kotlin/WalletViewModelTest.kt",
        "class WalletViewModelTest {\n  @Test fun `shows the cached balance when offline`() {}\n}\n",
    )
    write(
        android / "app/src/main/res/values/strings.xml",
        '<resources>\n  <string name="wallet_title">Wallet</string>\n</resources>\n',
    )
    write(android / ".github/workflows/ci.yml", "jobs:\n  check:\n    runs-on: ubuntu-latest\n")

    write(ios / "parity/pair.json", pair_json(["features", "tests", "strings", "ci", "spec"]))
    write(ios / "parity/features.json", features_json())
    write(ios / "parity/strings.json", json.dumps({
        "schema": 1,
        "keys": {"wallet.title": {"ios": "wallet.title", "android": "wallet_title"},
                 "wallet.locked": {"ios": "wallet.locked", "android": "wallet_locked"}},
    }, indent=2))
    write(ios / "parity/fixtures/wallet.json", json.dumps({"cases": []}))
    for cid in CRITERIA:
        status = "draft" if cid == "missing-case" else "written"
        write(ios / f"parity/use-cases/wallet.balance/{cid}.md",
              f"---\nid: wallet.balance/{cid}\nstatus: {status}\n---\n# {cid}\n")
    return ios, android


def main() -> int:
    with tempfile.TemporaryDirectory() as raw:
        base = Path(raw)
        ios, android = build_pair(base)
        out = base / "out"

        print("contract mirroring")
        mirrored = run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        check(mirrored.returncode == 0, "sync writes the mirror")
        locks = [json.loads((repo / "parity/CONTRACT.lock").read_text()) for repo in (ios, android)]
        check(locks[0]["contract"] == locks[1]["contract"], "locks agree across repos")
        check(any(name.startswith("use-cases/") for name in locks[0]["files"]),
              "the lock covers use-case docs")
        check(run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android),
                  "--check").returncode == 0, "sync --check reports no drift after a sync")

        import parityutil as u  # noqa: E402  — after sync, so the lock exists
        guard_members = run("-c", (
            "import sys,json;sys.argv=['guard','--platform','ios'];"
            f"sys.path.insert(0,{str(ios / 'parity')!r});"
            "import guard;"
            f"print(json.dumps(sorted(guard.contract_members({str(ios / 'parity')!r}))))"
        ))
        if guard_members.returncode == 0:
            tool_members = sorted(u.lock_for(ios)["files"])
            check(json.loads(guard_members.stdout) == tool_members,
                  "the guard and the tool agree on what the contract contains")
        else:
            check(False, "the guard exposes contract_members for cross-checking")

        print("export")
        ios_inv, android_inv = export_all(ios, android, out)
        first = ios_inv.read_bytes()
        run(str(SCRIPTS / "export.py"), "--root", str(ios), "--platform", "ios",
            "--out", str(out / "again.json"))
        check(first == (out / "again.json").read_bytes(), "export is byte-identical across runs")
        inventory = json.loads(first)
        check(not any(path.startswith("/") for path in inventory["sources"]),
              "no absolute path leaks into an inventory")
        check([t["suite"] for t in inventory["tests"]] == ["WalletModelTests"],
              "backticked Swift Testing names are collected")
        check(not any(f["path"].startswith("DemoTests") for f in inventory["features"]),
              "a test tree is not counted as a feature")
        check("use_cases" not in inventory, "the use-case axis is off unless a project asks for it")

        print("verdicts are behavioural, not structural")
        matrix = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        check(platform_status(matrix, "ios", "cached-offline") == "parity",
              "evidence with no location at all reads as parity")
        check(platform_status(matrix, "ios", "hides-while-locked") == "parity",
              "a stale location does not make a tested criterion a gap")
        check(("gap", "location", "ios", "wallet.balance/hides-while-locked") in findings_of(matrix),
              "a stale location is reported separately, as its own low-severity finding")
        check(platform_status(matrix, "ios", "legacy-impl") == "parity",
              "the deprecated `impl` spelling still works")
        check(platform_status(matrix, "ios", "untested") == "gap",
              "implemented without tests is a gap")
        check(("gap", "tests", "ios", "wallet.balance/untested") in findings_of(matrix),
              "...and it is a gap on the tests axis, never on logic")
        check(platform_status(matrix, "ios", "missing-case") == "gap",
              "a named test case that does not exist is a gap")
        check(platform_status(matrix, "ios", "refreshes-on-appear") == "parity",
              "a named test case that does exist is parity")
        check(android_status(matrix, "background-stream") == "deviation",
              "an evidenced deviation is not debt")
        check(android_status(matrix, "hides-while-locked") == "gap",
              "declared debt stays a gap")

        expected = {
            ("unknown", "discovery", "ios", "DemoApp/Features/Settings"),
            ("unknown", "strings", "ios", "settings.title"),
            ("gap", "logic", "android", "wallet.balance/hides-while-locked"),
            ("gap", "tests", "android", "wallet.balance/refreshes-on-appear"),
            ("gap", "tests", "ios", "wallet.balance/untested"),
            ("gap", "tests", "ios", "wallet.balance/missing-case"),
            ("gap", "spec", None, "wallet.balance/missing-case"),
            ("gap", "location", "ios", "wallet.balance/hides-while-locked"),
            ("gap", "strings", "ios", "wallet.locked"),
            ("gap", "strings", "android", "wallet.locked"),
        }
        actual = findings_of(matrix)
        for row in sorted(expected):
            check(row in actual, f"finds {row[0]}·{row[1]} {row[3]} ({row[2]})")
        check(actual == expected, f"finds nothing extra (extra: {sorted(actual - expected)})")
        check(matrix["findings"] == sorted(matrix["findings"], key=lambda f: f["severity"]),
              "findings come back in severity order")
        severities = {f["axis"]: f["severity"] for f in matrix["findings"]}
        check(severities["location"] > severities["tests"],
              "a stale location outranks nothing: it sorts below real debt")

        print("spec docs")
        draft = ios / "parity/use-cases/wallet.balance/cached-offline.md"
        draft.write_text(draft.read_text().replace("status: written", "status: draft"))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        drafted = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        check(("gap", "spec", None, "wallet.balance/cached-offline") in findings_of(drafted),
              "a draft doc does not satisfy the spec axis")
        check(platform_status(drafted, "ios", "cached-offline") == "parity",
              "...and a draft doc does not touch the behavioural verdict")
        draft.write_text(draft.read_text().replace("status: draft", "status: written"))
        draft.with_name("untested.md").unlink()
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        missing_doc = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        check(("gap", "spec", None, "wallet.balance/untested") in findings_of(missing_doc),
              "a missing doc is a spec gap")
        write(draft.with_name("untested.md"),
              "---\nid: wallet.balance/untested\nstatus: written\n---\n# untested\n")

        print("architecture is its own axis, off by default")
        architecture = {"architecture": {
            "roles": {
                "domain": {"ios": ["DemoDomain"], "android": [":core:model"]},
                "design": {"ios": ["DemoDesignSystem"], "android": [":core:designsystem"]},
            },
        }}
        write(ios / "parity/pair.json",
              pair_json(["features", "tests", "strings", "ci", "spec"], architecture))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        quiet = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        check(not any(f["axis"] == "architecture" for f in quiet["findings"]),
              "declaring an architecture map changes nothing while its axis is off")

        write(ios / "parity/pair.json",
              pair_json(["features", "tests", "strings", "ci", "spec", "architecture"], architecture))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        loud = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        architecture_findings = findings_of(loud)
        check(("gap", "architecture", "ios", "design") in architecture_findings
              and ("gap", "architecture", "android", "design") in architecture_findings,
              "a divergent layer is reported once the axis is on")
        check(("gap", "architecture", "ios", "domain") not in architecture_findings,
              "a layer both platforms satisfy is not reported")
        check(all(f["severity"] > severities["tests"]
                  for f in loud["findings"] if f["axis"] == "architecture"),
              "architectural divergence sorts below missing tests")

        architecture["architecture"]["deviations"] = [{
            "platform": "android", "roles": ["design"],
            "reason": "the design system is a compile-time theme here, not a module",
            "constraint": "platform-idiom", "evidence": "docs/architecture.md",
        }]
        write(ios / "parity/pair.json",
              pair_json(["features", "tests", "strings", "ci", "spec", "architecture"], architecture))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        excused = findings_of(audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv))
        check(("gap", "architecture", "android", "design") not in excused,
              "an accepted platform-idiom divergence stops being reported")
        check(("gap", "architecture", "ios", "design") in excused,
              "...for that platform only")

        print("use-case discovery, which never votes")
        pair = json.loads((ios / "parity/pair.json").read_text())
        pair["axes"].append("use_cases")
        pair["platforms"]["ios"]["use_cases"] = {
            "paths": ["**/UseCases/**"], "pattern": r"struct\s+(\w+)"}
        pair["platforms"]["android"]["use_cases"] = {
            "paths": ["**/usecase/**"], "pattern": r"class\s+(\w+)"}
        write(ios / "parity/pair.json", json.dumps(pair, indent=2))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))
        ios_inv, android_inv = export_all(ios, android, out)
        check(json.loads(ios_inv.read_text())["use_cases"]["candidates"]
              == ["FetchBalance", "FormatMoney"], "candidates are enumerated from the code")
        discovered = audit(ios, out / "matrix.json", ios=ios_inv, android=android_inv)
        found = findings_of(discovered)
        check(("unknown", "discovery", "ios", "FormatMoney") in found,
              "a candidate on one platform only surfaces as a question")
        check(("unknown", "discovery", "ios", "FetchBalance") not in found
              and ("unknown", "discovery", "android", "FetchBalance") not in found,
              "a candidate both platforms share is not a finding")
        check(not any(f["axis"] == "discovery" and f["status"] == "gap" for f in found),
              "discovery never produces a gap")
        for criterion in CRITERIA:
            before = platform_status(loud, "ios", criterion)
            after = platform_status(discovered, "ios", criterion)
            if before != after:
                check(False, f"turning discovery on changed the verdict for {criterion}")
                break
        else:
            check(True, "turning discovery on changed no criterion verdict")

        print("list")
        catalogue = json.loads(run(str(SCRIPTS / "list.py"), "--root", f"ios={ios}",
                                   "--root", f"android={android}", "--json").stdout)
        check(catalogue["has_contract"], "list finds the contract on its own")
        wallet = next(row for row in catalogue["mapped"] if row["id"] == "wallet")
        check(wallet["verdict"] == "paired",
              "a feature present on both sides is paired, whatever its module is called")
        check(catalogue["unmapped"]["ios"] == ["DemoApp/Features/Settings"],
              "an unmapped feature is listed as outside the contract")
        check(catalogue["unmapped"]["android"] == [], "a mapped feature is not also listed as unmapped")

        stale = json.loads((ios / "parity/pair.json").read_text())
        stale["features"]["ghost"] = {"ios": ["DemoApp/Features/Ghost"], "android": [":feature:ghost"]}
        stale["features"]["ios-only"] = {"ios": ["DemoApp/Features/Settings"]}
        write(ios / "parity/pair.json", json.dumps(stale, indent=2))
        catalogue = json.loads(run(str(SCRIPTS / "list.py"), "--root", f"ios={ios}",
                                   "--root", f"android={android}", "--json").stdout)
        verdicts = {row["id"]: row["verdict"] for row in catalogue["mapped"]}
        check(verdicts["ghost"] == "stale", "a mapping whose code is gone reads as stale")
        check(verdicts["ios-only"] == "partial", "a feature declared for one platform reads as partial")
        check(catalogue["unmapped"]["ios"] == [], "a now-mapped feature drops off the unmapped list")

        bare_repo = base / "bare"
        shutil.copytree(ios, bare_repo)
        shutil.rmtree(bare_repo / "parity")
        bare = json.loads(run(str(SCRIPTS / "list.py"), "--root", f"ios={bare_repo}", "--json").stdout)
        check(bare["has_contract"] is False and bare["mapped"] == [],
              "list works with no contract and pairs nothing")
        check(sorted(bare["unmapped"]["ios"]) == ["DemoApp/Features/Settings", "DemoApp/Features/Wallet"],
              "list falls back to detected candidates")

        del stale["features"]["ghost"], stale["features"]["ios-only"]
        write(ios / "parity/pair.json", json.dumps(stale, indent=2))
        run(str(SCRIPTS / "sync.py"), "--from", str(ios), "--to", str(android))

        print("guard: self-contained, layout-independent, fails rather than skips")
        shutil.move(str(android / "feature/wallet/src/main/kotlin/WalletViewModel.kt"),
                    str(android / "core/model/src/main/kotlin/WalletViewModel.kt"))
        shutil.rmtree(ios)
        guarded = run(str(android / "parity/guard.py"), cwd=android)
        check(guarded.returncode == 1 and "WalletRefreshTest" in guarded.stdout,
              "guard finds its own debt with the sibling repo deleted")
        check("WalletViewModel" not in guarded.stdout,
              "moving a file between modules does not upset the guard")
        check("skip" not in guarded.stdout.lower(), "guard skips nothing")

        tampered = json.loads((android / "parity/features.json").read_text())
        tampered["features"][0]["id"] = "edited-by-hand"
        write(android / "parity/features.json", json.dumps(tampered))
        check("edited by hand" in run(str(android / "parity/guard.py"), cwd=android).stdout,
              "guard detects a hand-edited contract")

        doc = android / "parity/use-cases/wallet.balance/cached-offline.md"
        doc.write_text(doc.read_text() + "\nedited\n")
        check("cached-offline.md" in run(str(android / "parity/guard.py"), cwd=android).stdout,
              "guard detects a hand-edited use-case doc")

        (android / "parity/pair.json").unlink()
        check(run(str(android / "parity/guard.py"), cwd=android).returncode != 0,
              "guard fails when the contract is gone")

    print()
    if FAILURES:
        print(f"selftest: {len(FAILURES)} failure(s)")
        return 1
    print("selftest: all checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
