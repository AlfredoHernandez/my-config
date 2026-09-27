#!/usr/bin/env python3
"""Compare N platform inventories against the shared parity contract.

This is the only component that sees more than one platform, and it lives
outside every repository on purpose: no app's test suite should need a sibling
checkout to be green.

Deterministic by construction — same inputs, byte-identical output.

    compare.py --contract <repo-with-parity-dir> \
               --inventory ios=ios.json --inventory android=android.json \
               [--out-json matrix.json] [--out-md report.md]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPTS))

import parityutil as u  # noqa: E402

PARITY, GAP, DEVIATION, UNKNOWN = "parity", "gap", "deviation", "unknown"

# Lower sorts first. Unknown outranks every gap: undecided is worse than known
# debt, because known debt has already been looked at and priced.
SEVERITY = {
    (UNKNOWN, "contract"): 0,
    (UNKNOWN, "logic"): 1,
    (UNKNOWN, "discovery"): 2,
    (UNKNOWN, "strings"): 3,
    (UNKNOWN, "telemetry"): 3,
    (GAP, "logic"): 4,
    (GAP, "tests"): 5,
    (GAP, "ci"): 6,
    (GAP, "spec"): 7,
    (GAP, "architecture"): 8,
    (GAP, "capabilities"): 9,
    (GAP, "strings"): 10,
    (GAP, "telemetry"): 10,
    # Last on purpose: code that moved is not a product problem. It is a note so
    # the contract stays useful for navigation, never a reason to fail anything.
    (GAP, "location"): 11,
}
DEFAULT_SEVERITY = 12


def severity(status: str, axis: str) -> int:
    return SEVERITY.get((status, axis), DEFAULT_SEVERITY)


class Findings:
    def __init__(self) -> None:
        self.rows: list[dict] = []

    def add(self, *, status, axis, platform, subject, detail, feature=None, criterion=None, next_step=None):
        self.rows.append(
            {
                "status": status,
                "axis": axis,
                "platform": platform,
                "feature": feature,
                "criterion": criterion,
                "subject": subject,
                "detail": detail,
                "next_step": next_step,
                "severity": severity(status, axis),
            }
        )

    def sorted(self) -> list[dict]:
        return sorted(
            self.rows,
            key=lambda r: (r["severity"], r["axis"], r["platform"] or "", r["feature"] or "", r["subject"]),
        )


def check_locks(inventories: dict[str, dict], findings: Findings) -> dict:
    """Contract drift across repos: the mirrors must be the same bytes."""
    locks = {platform: inv.get("contract") for platform, inv in inventories.items()}
    distinct = {value for value in locks.values() if value}
    missing = sorted(platform for platform, value in locks.items() if not value)
    for platform in missing:
        findings.add(
            status=UNKNOWN, axis="contract", platform=platform, subject="CONTRACT.lock",
            detail="this repository carries no contract lock, so its copy cannot be trusted",
            next_step="/parity sync",
        )
    if len(distinct) > 1:
        findings.add(
            status=UNKNOWN, axis="contract", platform=None, subject="CONTRACT.lock",
            detail=f"contract mirrors diverge across platforms: {sorted(distinct)}",
            next_step="/parity sync",
        )
    return {"locks": locks, "aligned": len(distinct) <= 1 and not missing}


def _places(inventory: dict) -> list[str]:
    """Everywhere a location hint could point. Used for navigation notes only."""
    return (
        list(inventory.get("sources", []))
        + [module["path"] for module in inventory.get("modules", [])]
        + [module["id"] for module in inventory.get("modules", [])]
        + [feature["path"] for feature in inventory.get("features", [])]
    )


def _suites(inventory: dict) -> dict[str, dict]:
    return {test["suite"]: test for test in inventory.get("tests", [])}


def _location(owner: dict) -> list[str]:
    """`location`, or the deprecated `impl` spelling it replaced."""
    declared = owner.get("location", owner.get("impl")) or []
    return [declared] if isinstance(declared, str) else list(declared)


def _missing_evidence(references: list[str], suites: dict[str, dict]) -> list[str]:
    """Which named tests this platform does not actually have.

    A reference is `Suite` or `Suite#case name`. The case form is much stronger
    evidence, because a suite can exist without the one case that matters.
    """
    absent: list[str] = []
    for reference in references:
        suite, _, case = reference.partition("#")
        if suite not in suites:
            absent.append(reference)
        elif case and case not in suites[suite]["cases"]:
            absent.append(reference)
    return absent


def _deviation_for(feature: dict, platform: str, criterion_id: str) -> dict | None:
    for deviation in feature.get("deviations", []):
        if deviation.get("platform") != platform:
            continue
        scope = deviation.get("criteria")
        if scope is None or criterion_id in scope:
            return deviation
    return None


def check_features(contract: dict, inventories: dict[str, dict], findings: Findings) -> list[dict]:
    matrix: list[dict] = []
    for feature in contract.get("features", []):
        row = {"id": feature["id"], "story": feature.get("story"), "criteria": []}
        for criterion in feature.get("criteria", []):
            cell = {"id": criterion["id"], "platforms": {}}
            owners = criterion.get("owners", {})
            for platform, inventory in inventories.items():
                deviation = _deviation_for(feature, platform, criterion["id"])
                if deviation:
                    cell["platforms"][platform] = {"status": DEVIATION, "reason": deviation.get("reason")}
                    if not deviation.get("evidence"):
                        findings.add(
                            status=UNKNOWN, axis="contract", platform=platform,
                            feature=feature["id"], criterion=criterion["id"],
                            subject="deviation without evidence",
                            detail=f"deviation '{deviation.get('reason')}' carries no evidence",
                            next_step=f"/parity spec {feature['id']}",
                        )
                    continue

                label = f"{feature['id']}/{criterion['id']}"
                owner = owners.get(platform)
                if owner is None:
                    cell["platforms"][platform] = {"status": UNKNOWN}
                    findings.add(
                        status=UNKNOWN, axis="logic", platform=platform,
                        feature=feature["id"], criterion=criterion["id"], subject=label,
                        detail="the contract says nothing about this platform: neither owner, nor debt, nor deviation",
                        next_step=f"/parity spec {feature['id']}",
                    )
                    continue

                # A location hint is navigation, never evidence. It is checked
                # here so a rotted hint still gets reported, and reported apart
                # from the verdict so moving code can never read as a gap.
                declared_location = _location(owner)
                if declared_location and not any(
                    u.any_glob(declared_location, place) for place in _places(inventory)
                ):
                    findings.add(
                        status=GAP, axis="location", platform=platform,
                        feature=feature["id"], criterion=criterion["id"], subject=label,
                        detail=f"the location hint {declared_location} no longer matches anything here",
                        next_step=f"/parity spec {feature['id']}",
                    )

                if owner.get("status") == "missing":
                    cell["platforms"][platform] = {"status": GAP, "reason": "not implemented"}
                    findings.add(
                        status=GAP, axis="logic", platform=platform,
                        feature=feature["id"], criterion=criterion["id"], subject=label,
                        detail="declared as not implemented on this platform",
                        next_step=f"/parity port {feature['id']} --to {platform}",
                    )
                    continue

                suites = _suites(inventory)
                named = owner.get("tests", [])
                absent = _missing_evidence(named, suites)
                if not named or absent:
                    cell["platforms"][platform] = {"status": GAP, "reason": "untested"}
                    detail = (
                        "implemented here but the contract names no test as evidence"
                        if not named
                        else f"the evidence the contract names does not exist: {absent}"
                    )
                    findings.add(
                        status=GAP, axis="tests", platform=platform,
                        feature=feature["id"], criterion=criterion["id"], subject=label,
                        detail=detail,
                        next_step=f"/parity port {feature['id']} --to {platform}",
                    )
                    continue

                resolved = [reference.partition("#")[0] for reference in named]
                cell["platforms"][platform] = {
                    "status": PARITY,
                    "tests": named,
                    "kinds": sorted({suites[suite]["kind"] for suite in resolved}),
                    "cases": sum(len(suites[suite]["cases"]) for suite in resolved),
                }
            row["criteria"].append(cell)
        matrix.append(row)
    return matrix


def check_orphans(pair: dict, inventories: dict[str, dict], findings: Findings) -> None:
    """Directories and modules the contract has never heard of.

    Discovery, not a verdict. These are things the exporter noticed by structure,
    and structure is not behaviour: a folder here may be a whole feature, an
    implementation detail, or nothing at all. The other platform may well have
    the same behaviour somewhere shaped differently. Only reading both sides
    settles it, which is why this reports a question and never a gap.
    """
    mapped: dict[str, set[str]] = {platform: set() for platform in inventories}
    for entry in pair.get("features", {}).values():
        for platform, targets in entry.items():
            if platform in mapped:
                mapped[platform].update(targets)
    for platform, inventory in inventories.items():
        for feature in inventory.get("features", []):
            if u.feature_matches(feature, mapped[platform]):
                continue
            findings.add(
                status=UNKNOWN, axis="discovery", platform=platform,
                subject=feature.get("module") or feature["path"],
                detail="detected in the code and absent from the contract; it may or may not be a feature",
                next_step="/parity init",
            )


def check_keyed_axis(axis: str, contract: dict, inventories: dict[str, dict], findings: Findings) -> dict:
    """Strings and telemetry: one neutral key, one resource per platform.

    Each platform is checked against the contract, never against another
    platform's catalog — the same check a repo runs on its own, here run for all.
    """
    field = {"strings": "keys", "telemetry": "events"}[axis]
    inventory_field = {"strings": ("strings", "keys"), "telemetry": ("telemetry", "events")}[axis]
    table = contract.get(field, {})
    summary: dict[str, dict] = {}
    for platform, inventory in inventories.items():
        section = inventory.get(inventory_field[0], {})
        present = set(section.get(inventory_field[1], []))
        expected = {
            neutral: mapping[platform]
            for neutral, mapping in table.items()
            if platform in mapping and mapping[platform] is not None
        }
        missing = sorted(neutral for neutral, resource in expected.items() if resource not in present)
        unmapped = sorted(present - set(expected.values()))
        for neutral in missing:
            findings.add(
                status=GAP, axis=axis, platform=platform, subject=neutral,
                detail=f"contract maps it to '{expected[neutral]}', which this platform does not define",
                next_step=f"/parity port {neutral} --to {platform}",
            )
        for resource in unmapped:
            findings.add(
                status=UNKNOWN, axis=axis, platform=platform, subject=resource,
                detail="defined here but absent from the contract, so no other platform can be held to it",
                next_step="/parity spec",
            )
        summary[platform] = {"expected": len(expected), "missing": missing, "unmapped": unmapped}
    return summary


def _roles_and_deviations(section) -> tuple[dict, list[dict]]:
    """Accept either a flat role map or `{"roles": ..., "deviations": [...]}`."""
    if isinstance(section, dict) and "roles" in section:
        return section.get("roles") or {}, section.get("deviations") or []
    return section or {}, []


def check_mapped_axis(axis: str, pair_key: str, pair: dict, inventories: dict[str, dict],
                      findings: Findings, extract) -> dict:
    """A declared role each platform is expected to satisfy, however it does it.

    Roles carry patterns per platform, so two platforms satisfy the same role with
    completely different names. A role a platform deliberately does not carry is
    recorded as a deviation rather than left to read as debt.
    """
    roles, deviations = _roles_and_deviations(pair.get(pair_key))
    excused = {
        (deviation["platform"], role)
        for deviation in deviations
        for role in (deviation.get("roles") or list(roles))
    }
    for deviation in deviations:
        if not deviation.get("evidence"):
            findings.add(
                status=UNKNOWN, axis="contract", platform=deviation.get("platform"),
                subject=f"{axis} deviation without evidence",
                detail=f"deviation '{deviation.get('reason')}' carries no evidence",
                next_step="/parity init",
            )
    summary: dict[str, dict] = {}
    for role, mapping in roles.items():
        for platform, inventory in inventories.items():
            if (platform, role) in excused:
                summary.setdefault(platform, {})[role] = "deviation"
                continue
            patterns = mapping.get(platform)
            if patterns is None:
                findings.add(
                    status=UNKNOWN, axis=axis, platform=platform, subject=role,
                    detail=f"role '{role}' is undeclared for this platform",
                    next_step="/parity init",
                )
                continue
            available = extract(inventory)
            matched = sorted(value for value in available if u.any_glob(patterns, value))
            if patterns and not matched:
                findings.add(
                    status=GAP, axis=axis, platform=platform, subject=role,
                    detail=f"nothing here satisfies '{role}' (expected {patterns})",
                    next_step=f"/parity guard --platform {platform}",
                )
            summary.setdefault(platform, {})[role] = matched
    return summary


def ci_candidates(inventory: dict) -> list[str]:
    """Job ids, workflow paths and workflow names.

    A role is often carried by a workflow whose jobs are named for their steps
    rather than their purpose — `release.yml` running a job called `publish`.
    Matching ids alone reports that as a missing release pipeline, which is
    false and trains people to ignore the CI axis. A role implemented as a step
    inside another job is not discoverable this way at all: declare it against
    the job that carries it, the same way every other mapping is declared.
    """
    candidates: set[str] = set()
    for job in inventory.get("ci", {}).get("jobs", []):
        # A job gated off with a constant-false `if:` runs nothing. Counting it
        # would report the role satisfied by a pipeline that is switched off,
        # which under-reports real debt — the direction that costs the most.
        if job.get("enabled") is False:
            continue
        candidates.add(job["id"])
        workflow = job.get("workflow")
        if workflow:
            candidates.add(workflow)
            candidates.add(Path(workflow).stem)
    for system in inventory.get("ci", {}).get("systems", []):
        candidates.add(system)
    return sorted(candidates)


def build_report(pair: dict, matrix: list[dict], findings: list[dict], summaries: dict) -> str:
    platforms = sorted(pair.get("platforms", {}))
    lines = [f"# Parity audit — {pair.get('product', 'unnamed product')}", ""]
    lines += [f"Platforms: {', '.join(platforms)}", ""]

    counts: dict[str, int] = {}
    for row in matrix:
        for cell in row["criteria"]:
            for state in cell["platforms"].values():
                counts[state["status"]] = counts.get(state["status"], 0) + 1
    total = sum(counts.values()) or 1
    lines += ["## Verdict", ""]
    for status in (PARITY, DEVIATION, GAP, UNKNOWN):
        count = counts.get(status, 0)
        lines.append(f"- **{status}**: {count} ({100 * count // total}% of criterion/platform cells)")
    lines += ["", "Cells cover the feature matrix only. Findings also cover the axes that sit",
              "outside it — contract drift, orphaned code, resources, CI — so the two counts",
              "are not meant to agree:", ""]
    by_status: dict[str, int] = {}
    for row in findings:
        by_status[row["status"]] = by_status.get(row["status"], 0) + 1
    for status in (UNKNOWN, GAP, DEVIATION):
        if status in by_status:
            lines.append(f"- **{status}** findings: {by_status[status]}")
    lines += ["", "A score is a trend, never a target: `deviation` is as healthy as `parity`.", ""]

    lines += ["## Matrix", "", "| feature | criterion | " + " | ".join(platforms) + " |",
              "|---|---|" + "---|" * len(platforms)]
    for row in matrix:
        for cell in row["criteria"]:
            cells = [cell["platforms"].get(p, {}).get("status", UNKNOWN) for p in platforms]
            lines.append(f"| {row['id']} | {cell['id']} | " + " | ".join(cells) + " |")
    lines.append("")

    lines += ["## Backlog", ""]
    if not findings:
        lines.append("Nothing actionable. Every cell is `parity` or a recorded `deviation`.")
    for index, row in enumerate(findings, start=1):
        where = " / ".join(filter(None, [row["platform"], row["feature"], row["criterion"]]))
        lines.append(f"{index}. **[{row['status']}·{row['axis']}]** `{row['subject']}` — {row['detail']}")
        if where:
            lines.append(f"   - where: {where}")
        if row["next_step"]:
            lines.append(f"   - next: `{row['next_step']}`")
    lines.append("")

    lines += ["## Axis summaries", "", "```json", u.dumps(summaries).rstrip(), "```", ""]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--contract", required=True, type=Path, help="repo holding the parity/ contract")
    parser.add_argument("--inventory", action="append", required=True, metavar="PLATFORM=PATH")
    parser.add_argument("--out-json", type=Path)
    parser.add_argument("--out-md", type=Path)
    args = parser.parse_args(argv)

    contract_root = args.contract.resolve()
    pair = u.load_pair(contract_root)
    features = u.read_json(u.contract_dir(contract_root) / "features.json")
    strings_path = u.contract_dir(contract_root) / "strings.json"
    telemetry_path = u.contract_dir(contract_root) / "telemetry.json"

    inventories: dict[str, dict] = {}
    for spec in args.inventory:
        if "=" not in spec:
            raise u.ParityError(f"--inventory expects PLATFORM=PATH, got '{spec}'")
        platform, path = spec.split("=", 1)
        inventories[platform] = u.read_json(Path(path))

    undeclared = sorted(set(inventories) - set(pair.get("platforms", {})))
    if undeclared:
        raise u.ParityError(f"inventories for undeclared platforms: {undeclared}")

    findings = Findings()
    summaries = {"contract": check_locks(inventories, findings)}
    matrix = check_features(features, inventories, findings)
    check_orphans(pair, inventories, findings)

    axes = pair.get("axes", [])
    if "strings" in axes and strings_path.exists():
        summaries["strings"] = check_keyed_axis("strings", u.read_json(strings_path), inventories, findings)
    if "telemetry" in axes and telemetry_path.exists():
        summaries["telemetry"] = check_keyed_axis("telemetry", u.read_json(telemetry_path), inventories, findings)
    if "ci" in axes:
        summaries["ci"] = check_mapped_axis(
            "ci", "ci_roles", pair, inventories, findings, ci_candidates
        )
    if "capabilities" in axes:
        summaries["capabilities"] = check_mapped_axis(
            "capabilities", "capability_roles", pair, inventories, findings,
            lambda inv: inv.get("capabilities", {}).get("permissions", [])
            + inv.get("capabilities", {}).get("components", []),
        )

    ordered = findings.sorted()
    result = {
        "schema": 1,
        "product": pair.get("product"),
        "platforms": sorted(inventories),
        "matrix": matrix,
        "findings": ordered,
        "summaries": summaries,
    }
    if args.out_json:
        u.write_json(args.out_json, result)
    report = build_report(pair, matrix, ordered, summaries)
    if args.out_md:
        args.out_md.parent.mkdir(parents=True, exist_ok=True)
        args.out_md.write_text(report, encoding="utf-8")
    if not args.out_json and not args.out_md:
        sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except u.ParityError as error:
        print(f"parity: {error}", file=sys.stderr)
        raise SystemExit(2)
