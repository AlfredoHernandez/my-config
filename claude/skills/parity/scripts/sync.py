#!/usr/bin/env python3
"""Mirror the parity contract across every repository of a pair.

The contract is one artifact with N byte-identical copies. Each repo owns its
copy so its tests never reach outside itself; this is what keeps the copies the
same bytes, and CONTRACT.lock is what proves they are.

    sync.py --from <repo> --to <repo> [--to <repo> ...] [--check]
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS))

import parityutil as u  # noqa: E402


def contract_members(root: Path) -> list[str]:
    return u.contract_members(u.contract_dir(root))


def diff(source: Path, target: Path) -> dict:
    source_base, target_base = u.contract_dir(source), u.contract_dir(target)
    source_members = set(contract_members(source))
    target_members = set(contract_members(target))
    changed = sorted(
        name
        for name in source_members & target_members
        if not filecmp.cmp(source_base / name, target_base / name, shallow=False)
    )
    return {
        "added": sorted(source_members - target_members),
        "removed": sorted(target_members - source_members),
        "changed": changed,
    }


def apply(source: Path, target: Path, report: dict) -> None:
    source_base, target_base = u.contract_dir(source), u.contract_dir(target)
    for name in report["added"] + report["changed"]:
        destination = target_base / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source_base / name, destination)
    for name in report["removed"]:
        (target_base / name).unlink()
    u.write_json(target_base / u.LOCK_NAME, u.lock_for(target))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from", dest="source", required=True, type=Path)
    parser.add_argument("--to", dest="targets", action="append", required=True, type=Path)
    parser.add_argument("--check", action="store_true", help="report drift without writing")
    args = parser.parse_args(argv)

    source = args.source.resolve()
    if not (u.contract_dir(source) / "pair.json").exists():
        raise u.ParityError(f"no contract to mirror from: {u.contract_dir(source) / 'pair.json'}")

    result = {"source": source.name, "targets": {}, "drift": False}
    for target_arg in args.targets:
        target = target_arg.resolve()
        if target == source:
            continue
        if not target.is_dir():
            raise u.ParityError(f"target is not a directory: {target}")
        report = diff(source, target)
        report["drift"] = bool(report["added"] or report["removed"] or report["changed"])
        result["drift"] = result["drift"] or report["drift"]
        if not args.check and report["drift"]:
            apply(source, target, report)
            report["applied"] = True
        result["targets"][target.name] = report

    if not args.check:
        u.write_json(u.contract_dir(source) / u.LOCK_NAME, u.lock_for(source))
        result["source_lock"] = u.lock_for(source)["contract"]

    sys.stdout.write(u.dumps(result))
    return 1 if (args.check and result["drift"]) else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except u.ParityError as error:
        print(f"parity: {error}", file=sys.stderr)
        raise SystemExit(2)
