#!/usr/bin/env python3
"""List every feature across the pair, and say which ones the contract pairs up.

Answers "what is on each side, and what lines up" without needing a contract —
and gets sharper once there is one. It never decides whether a feature is at
parity: that is a per-criterion judgment and it belongs to `compare.py`. A
feature present on both sides can still be missing half its behaviour.

    list.py --root ios=<repo> --root android=<repo> [--contract <repo>] [--json]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
sys.path[:0] = [str(SCRIPTS), str(SCRIPTS / "adapters")]

import export  # noqa: E402
import parityutil as u  # noqa: E402

PAIRED, PARTIAL, STALE = "paired", "partial", "stale"


def inventory_for(root: Path, platform: str) -> dict:
    """Prefer the repo's declared config; fall back to detection so this works
    before a pair has ever been initialized."""
    try:
        resolved, config = export.resolve_config(root, platform, None)
    except u.ParityError:
        resolved, config = platform, {}
    return export.build(root, resolved, config)


def collect(roots: dict[str, Path], contract_root: Path | None) -> dict:
    inventories = {platform: inventory_for(root, platform) for platform, root in roots.items()}
    feature_map: dict[str, dict] = {}
    if contract_root is not None:
        feature_map = u.load_pair(contract_root).get("features", {})

    claimed = {platform: set() for platform in inventories}
    rows: list[dict] = []
    for contract_id, mapping in sorted(feature_map.items()):
        row = {"id": contract_id, "platforms": {}}
        for platform, inventory in inventories.items():
            patterns = mapping.get(platform)
            if patterns is None:
                row["platforms"][platform] = {"state": "undeclared"}
                continue
            matched = [
                feature
                for feature in inventory.get("features", [])
                if u.feature_matches(feature, patterns)
            ]
            claimed[platform].update(
                identifier for feature in matched for identifier in u.feature_identifiers(feature)
            )
            row["platforms"][platform] = {
                "state": "found" if matched else "declared-but-absent",
                "declared": patterns,
                "matched": sorted(feature.get("module") or feature["path"] for feature in matched),
            }
        states = {cell["state"] for cell in row["platforms"].values()}
        row["verdict"] = (
            STALE if "declared-but-absent" in states
            else PAIRED if states == {"found"}
            else PARTIAL
        )
        rows.append(row)

    unmapped = {
        platform: sorted(
            feature.get("module") or feature["path"]
            for feature in inventory.get("features", [])
            if not (u.feature_identifiers(feature) & claimed[platform])
        )
        for platform, inventory in inventories.items()
    }
    return {
        "schema": 1,
        "has_contract": contract_root is not None,
        "platforms": sorted(inventories),
        "counts": {
            platform: len(inventory.get("features", [])) for platform, inventory in inventories.items()
        },
        "mapped": rows,
        "unmapped": unmapped,
    }


def render(result: dict) -> str:
    platforms = result["platforms"]
    lines: list[str] = []
    header = "feature".ljust(22) + "".join(platform.ljust(34) for platform in platforms) + "verdict"
    counts = ", ".join(f"{platform}: {result['counts'][platform]}" for platform in platforms)
    lines += [f"Features detected — {counts}", ""]

    if result["mapped"]:
        lines += [header, "-" * len(header)]
        for row in result["mapped"]:
            cells = ""
            for platform in platforms:
                cell = row["platforms"][platform]
                if cell["state"] == "undeclared":
                    text = "—"
                elif cell["state"] == "declared-but-absent":
                    text = f"! {', '.join(cell['declared'])}"
                else:
                    text = ", ".join(cell["matched"])
                cells += text[:32].ljust(34)
            lines.append(row["id"].ljust(22) + cells + row["verdict"])
        lines.append("")
        if any(row["verdict"] == STALE for row in result["mapped"]):
            lines += ["`!` marks a mapping the contract declares and the code no longer has.", ""]

    for platform in platforms:
        entries = result["unmapped"][platform]
        if not entries:
            continue
        label = "not in the contract" if result["has_contract"] else "detected"
        lines += [f"{platform} — {label}:"]
        lines += [f"  {entry}" for entry in entries]
        lines.append("")

    if not result["has_contract"]:
        lines += [
            "No contract in play, so nothing here is paired: these are candidates detected from",
            "directory and module structure. Names rarely correspond across platforms — run",
            "`/parity init` to declare the mapping before reading any of this as a difference.",
            "",
        ]
    else:
        lines += [
            "Pairing is not parity. A feature listed on both sides can still be missing half its",
            "behaviour or all of its tests — `/parity audit` is what rules on that.",
            "",
        ]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", required=True, metavar="PLATFORM=PATH")
    parser.add_argument("--contract", type=Path, help="repo holding parity/pair.json")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args(argv)

    roots: dict[str, Path] = {}
    for spec in args.root:
        if "=" not in spec:
            raise u.ParityError(f"--root expects PLATFORM=PATH, got '{spec}'")
        platform, path = spec.split("=", 1)
        resolved = Path(path).resolve()
        if not resolved.is_dir():
            raise u.ParityError(f"not a directory: {resolved}")
        roots[platform] = resolved

    contract_root = args.contract.resolve() if args.contract else None
    if contract_root is None:
        contract_root = next(
            (root for root in roots.values() if (u.contract_dir(root) / "pair.json").exists()), None
        )

    result = collect(roots, contract_root)
    sys.stdout.write(u.dumps(result) if args.json else render(result))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except u.ParityError as error:
        print(f"parity: {error}", file=sys.stderr)
        raise SystemExit(2)
