#!/usr/bin/env python3
"""Export one repository's parity inventory.

Reads a single repository and nothing else. It never looks for a sibling
platform, never needs one on disk, and never emits an absolute path — that is
the property which lets a repo's own gate run green in a clean checkout.

    export.py --root <repo> [--platform ios] [--out inventory.json]
    export.py --root <repo> --detect-only
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
sys.path[:0] = [str(SCRIPTS), str(SCRIPTS / "adapters")]

import common  # noqa: E402
import parityutil as u  # noqa: E402

import flutter, generic, gradle_groovy, gradle_kts, rn, swift_spm, xcodeproj  # noqa: E402

ADAPTERS = (swift_spm, gradle_kts, gradle_groovy, flutter, rn, xcodeproj, generic)
BY_NAME = {adapter.NAME: adapter for adapter in ADAPTERS}
SCHEMA = 1


def detect_adapter(root: Path, files: list[str]):
    for adapter in ADAPTERS:
        if adapter.detect(root, files):
            return adapter
    return generic


def feature_list(adapter, root: Path, files: list[str], settings: dict) -> list[dict]:
    """Feature candidates with test trees excluded.

    A mirrored test tree looks exactly like a feature tree to any path-based
    heuristic, and counting it as one invents features on both platforms.
    """
    return [
        feature
        for feature in adapter.features(root, files, settings, adapter.modules(root, files, settings))
        if not u.any_glob(settings["test_path_globs"], feature["path"])
    ]


def resolve_config(root: Path, platform: str | None, toolchain: str | None) -> tuple[str, dict]:
    """Platform config from pair.json when present, otherwise adapter defaults.

    Exporting has to work before a contract exists, or `init` could never
    bootstrap a repository that has never heard of parity.
    """
    pair_path = u.contract_dir(root) / "pair.json"
    if not pair_path.exists():
        return platform or root.name, {"toolchain": toolchain} if toolchain else {}
    pair = u.load_pair(root)
    platforms = pair.get("platforms", {})
    if platform is None:
        if len(platforms) != 1:
            raise u.ParityError(
                f"--platform is required: pair.json declares {sorted(platforms)}"
            )
        platform = next(iter(platforms))
    if platform not in platforms:
        raise u.ParityError(f"platform '{platform}' is not declared in {pair_path}")
    config = dict(platforms[platform])
    config.setdefault("axes", pair.get("axes", []))
    return platform, config


def build(root: Path, platform: str, config: dict) -> dict:
    files = u.walk(root)
    adapter = BY_NAME[config["toolchain"]] if config.get("toolchain") else detect_adapter(root, files)
    defaults = adapter.DEFAULTS
    settings = {**defaults, **config}
    axes = settings.get("axes") or [
        "features", "tests", "strings", "ci", "capabilities",
    ]

    module_list = adapter.modules(root, files, settings)
    inventory = {
        "schema": SCHEMA,
        "platform": platform,
        "toolchain": adapter.NAME,
        "modules": module_list,
    }

    if "features" in axes:
        inventory["features"] = feature_list(adapter, root, files, settings)
    inventory["sources"] = [
        rel
        for rel in files
        if rel.endswith(adapter.SOURCE_SUFFIXES)
        and not u.any_glob(settings["test_path_globs"], rel)
    ]

    if "tests" in axes:
        test_files = [rel for rel in files if u.any_glob(settings["test_path_globs"], rel)]
        inventory["tests"] = common.collect_tests(
            root, test_files, settings["test_kinds"], settings["default_test_kind"]
        )
    if "strings" in axes:
        inventory["strings"] = adapter.strings(root, files, settings)
    if "ci" in axes:
        inventory["ci"] = common.workflow_jobs(root, files)
    if "capabilities" in axes:
        inventory["capabilities"] = adapter.capabilities(root, files, settings)
    if "telemetry" in axes:
        inventory["telemetry"] = {
            "events": common.declared_matches(root, files, settings.get("telemetry"))
        }
    if "design_tokens" in axes:
        inventory["design_tokens"] = {
            "tokens": common.declared_matches(root, files, settings.get("design_tokens"))
        }

    lock_path = u.contract_dir(root) / u.LOCK_NAME
    if lock_path.exists():
        inventory["contract"] = u.read_json(lock_path).get("contract")
    return inventory


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--platform")
    parser.add_argument("--toolchain", choices=sorted(BY_NAME))
    parser.add_argument("--out", type=Path)
    parser.add_argument("--detect-only", action="store_true")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    if not root.is_dir():
        raise u.ParityError(f"not a directory: {root}")

    if args.detect_only:
        files = u.walk(root)
        adapter = BY_NAME[args.toolchain] if args.toolchain else detect_adapter(root, files)
        report = {
            "toolchain": adapter.NAME,
            "modules": adapter.modules(root, files, adapter.DEFAULTS),
            "feature_candidates": feature_list(adapter, root, files, adapter.DEFAULTS),
            "has_contract": (u.contract_dir(root) / "pair.json").exists(),
        }
        sys.stdout.write(u.dumps(report))
        return 0

    platform, config = resolve_config(root, args.platform, args.toolchain)
    inventory = build(root, platform, config)
    if args.out:
        u.write_json(args.out, inventory)
    else:
        sys.stdout.write(u.dumps(inventory))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except u.ParityError as error:
        print(f"parity: {error}", file=sys.stderr)
        raise SystemExit(2)
