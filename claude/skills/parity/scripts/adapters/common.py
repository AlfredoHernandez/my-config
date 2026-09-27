"""Extraction primitives shared by every toolchain adapter.

Everything here is regex-and-filesystem only: no builds, no network, no LLM.
Two runs over an unchanged tree must produce byte-identical output, so nothing
may depend on wall time, absolute paths, or directory iteration order.
"""

from __future__ import annotations

import re
from pathlib import Path

import parityutil as u

_ANNOTATED_LOOKAHEAD = 4

_SWIFT_XCTEST = re.compile(r"\bfunc\s+(test\w*)\s*\(")
_SWIFT_FUNC = re.compile(r"\bfunc\s+(`[^`]+`|[A-Za-z_]\w*)\s*\(")
_KOTLIN_FUN = re.compile(r"\bfun\s+(`[^`]+`|[A-Za-z_]\w*)\s*\(")
_DART_CASE = re.compile(r"\b(?:testWidgets|test)\s*\(\s*(['\"])(.+?)\1")
_JS_CASE = re.compile(r"\b(?:it|test)\s*\(\s*(['\"`])(.+?)\1")

_ANDROID_STRING = re.compile(r"<(?:string|plurals|string-array)\s+[^>]*name\s*=\s*\"([^\"]+)\"")
_APPLE_STRINGS = re.compile(r"^\s*\"((?:[^\"\\]|\\.)*)\"\s*=", re.MULTILINE)
_USES_PERMISSION = re.compile(r"<uses-permission[^>]*android:name\s*=\s*\"([^\"]+)\"")
_MANIFEST_COMPONENT = re.compile(r"<(service|receiver|provider)\s+[^>]*android:name\s*=\s*\"([^\"]+)\"")
_PLIST_KEY = re.compile(r"<key>([^<]+)</key>")
_WORKFLOW_JOB = re.compile(r"^  ([A-Za-z_][\w-]*):\s*$")
_WORKFLOW_JOB_IF = re.compile(r"^    if:(.*)$")
_WORKFLOW_STEP_NAME = re.compile(r"^\s*-?\s*name:\s*(.+)$")
_MAKE_TARGET = re.compile(r"^([a-zA-Z][\w.-]*):(?!=)")
_FASTLANE_LANE = re.compile(r"^\s*lane\s+:(\w+)")


def _unbacktick(name: str) -> str:
    return name[1:-1] if name.startswith("`") else name


def annotated_cases(text: str, annotation: str, func_pattern: re.Pattern) -> list[str]:
    """Names of functions carrying `annotation` within the next few lines."""
    lines = text.splitlines()
    names: list[str] = []
    for index, line in enumerate(lines):
        if annotation not in line:
            continue
        stripped = line.lstrip()
        if not stripped.startswith(annotation) and f" {annotation}" not in line:
            continue
        for ahead in lines[index : index + 1 + _ANNOTATED_LOOKAHEAD]:
            match = func_pattern.search(ahead)
            if match:
                names.append(_unbacktick(match.group(1)))
                break
    return names


def swift_cases(text: str) -> list[str]:
    cases = set(annotated_cases(text, "@Test", _SWIFT_FUNC))
    cases.update(_SWIFT_XCTEST.findall(text))
    return sorted(cases)


def kotlin_cases(text: str) -> list[str]:
    return sorted(set(annotated_cases(text, "@Test", _KOTLIN_FUN)))


def dart_cases(text: str) -> list[str]:
    return sorted({match[1] for match in _DART_CASE.findall(text)})


def js_cases(text: str) -> list[str]:
    return sorted({match[1] for match in _JS_CASE.findall(text)})


_EXTRACTORS = {
    ".swift": swift_cases,
    ".kt": kotlin_cases,
    ".java": kotlin_cases,
    ".dart": dart_cases,
    ".js": js_cases,
    ".jsx": js_cases,
    ".ts": js_cases,
    ".tsx": js_cases,
}


def classify(rel: str, rules: list[dict], default: str) -> str:
    """First matching rule wins, so config order is the precedence."""
    for rule in rules:
        if u.any_glob(rule.get("paths", []), rel):
            return rule["kind"]
    return default


def collect_tests(root: Path, files: list[str], kind_rules: list[dict], default_kind: str) -> list[dict]:
    tests: list[dict] = []
    for rel in files:
        extractor = _EXTRACTORS.get(Path(rel).suffix)
        if not extractor:
            continue
        cases = extractor(u.read_text(root, rel))
        if not cases:
            continue
        tests.append(
            {
                "suite": Path(rel).stem,
                "path": rel,
                "kind": classify(rel, kind_rules, default_kind),
                "cases": cases,
            }
        )
    return sorted(tests, key=lambda t: (t["path"], t["suite"]))


def android_string_keys(root: Path, files: list[str]) -> dict:
    keys: set[str] = set()
    sources: list[str] = []
    for rel in files:
        if not rel.endswith(".xml") or "/res/values/" not in f"/{rel}":
            continue
        found = _ANDROID_STRING.findall(u.read_text(root, rel))
        if found:
            sources.append(rel)
            keys.update(found)
    return {"keys": sorted(keys), "sources": sorted(sources)}


def apple_string_keys(root: Path, files: list[str]) -> dict:
    keys: set[str] = set()
    sources: list[str] = []
    for rel in files:
        if rel.endswith(".xcstrings"):
            catalog = u.read_json(root / rel)
            found = [key for key in catalog.get("strings", {}) if key]
        elif rel.endswith(".strings"):
            found = _APPLE_STRINGS.findall(u.read_text(root, rel))
        else:
            continue
        if found:
            sources.append(rel)
            keys.update(found)
    return {"keys": sorted(keys), "sources": sorted(sources)}


def _is_falsy_condition(value: str) -> bool:
    """Whether a GitHub `if:` expression is a constant that never runs."""
    text = value.strip()
    if text.startswith("${{") and text.endswith("}}"):
        text = text[3:-2].strip()
    return bool(re.match(r"^false\s*(\)|&&|$)", text))


def workflow_jobs(root: Path, files: list[str]) -> dict:
    """CI jobs and which systems are wired, by file presence and shape."""
    jobs: list[dict] = []
    systems: set[str] = set()
    for rel in files:
        if rel.startswith(".github/workflows/") and rel.endswith((".yml", ".yaml")):
            systems.add("github-actions")
            in_jobs = False
            current: dict | None = None
            pending_if: list[str] | None = None
            for line in u.read_text(root, rel).splitlines():
                if re.match(r"^jobs:\s*$", line):
                    in_jobs = True
                    continue
                if in_jobs and line and not line.startswith((" ", "\t")):
                    in_jobs = False
                if not in_jobs:
                    continue
                match = _WORKFLOW_JOB.match(line)
                if match:
                    pending_if = None
                    current = {"system": "github-actions", "workflow": rel,
                               "id": match.group(1), "enabled": True}
                    jobs.append(current)
                    continue
                if current is None:
                    continue
                # A job-level `if:` decides whether the job runs at all. Without
                # it a workflow gated off with `if: false` reads as a pipeline
                # that satisfies its role while running nothing — a green that
                # verifies less than no pipeline, because it is believed.
                cond = _WORKFLOW_JOB_IF.match(line)
                if cond:
                    inline = cond.group(1).strip()
                    if inline in ("", ">", ">-", "|", "|-"):
                        pending_if = []
                    else:
                        current["enabled"] = not _is_falsy_condition(inline)
                        pending_if = None
                    continue
                if pending_if is not None:
                    if line.strip() and not line.startswith(" " * 6):
                        current["enabled"] = not _is_falsy_condition(" ".join(pending_if))
                        pending_if = None
                    else:
                        pending_if.append(line.strip())
                        continue
                step = _WORKFLOW_STEP_NAME.match(line)
                if step:
                    current.setdefault("steps", []).append(step.group(1).strip().strip("\'\""))
            if current is not None and pending_if:
                current["enabled"] = not _is_falsy_condition(" ".join(pending_if))
        elif rel == "Makefile":
            systems.add("make")
            for line in u.read_text(root, rel).splitlines():
                match = _MAKE_TARGET.match(line)
                if match:
                    jobs.append({"system": "make", "workflow": rel, "id": match.group(1)})
        elif rel.endswith("fastlane/Fastfile"):
            systems.add("fastlane")
            for line in u.read_text(root, rel).splitlines():
                match = _FASTLANE_LANE.match(line)
                if match:
                    jobs.append({"system": "fastlane", "workflow": rel, "id": match.group(1)})
        elif rel.startswith("ci_scripts/"):
            systems.add("xcode-cloud")
            jobs.append({"system": "xcode-cloud", "workflow": rel, "id": Path(rel).stem})
        elif rel == ".circleci/config.yml":
            systems.add("circleci")
        elif rel in ("bitrise.yml", "codemagic.yaml", ".gitlab-ci.yml"):
            systems.add(Path(rel).stem.lstrip("."))
    return {
        "systems": sorted(systems),
        "jobs": sorted(jobs, key=lambda j: (j["system"], j["workflow"], j["id"])),
    }


def android_capabilities(root: Path, files: list[str]) -> dict:
    permissions: set[str] = set()
    components: set[str] = set()
    for rel in files:
        if not rel.endswith("AndroidManifest.xml"):
            continue
        text = u.read_text(root, rel)
        permissions.update(_USES_PERMISSION.findall(text))
        components.update(f"{kind}:{name}" for kind, name in _MANIFEST_COMPONENT.findall(text))
    return {"permissions": sorted(permissions), "components": sorted(components)}


def apple_capabilities(root: Path, files: list[str]) -> dict:
    permissions: set[str] = set()
    entitlements: set[str] = set()
    for rel in files:
        if rel.endswith(".entitlements"):
            entitlements.update(_PLIST_KEY.findall(u.read_text(root, rel)))
        elif rel.endswith("Info.plist"):
            permissions.update(
                key for key in _PLIST_KEY.findall(u.read_text(root, rel)) if key.endswith("UsageDescription")
            )
    return {"permissions": sorted(permissions), "components": sorted(entitlements)}


def declared_matches(root: Path, files: list[str], spec: dict | None) -> list[str]:
    """Opt-in axis: pull capture group 1 of `pattern` out of files under `paths`.

    Axes like telemetry and design tokens have no portable shape, so they stay
    off until a project declares how to find them. A guessed default here would
    manufacture gaps that do not exist.
    """
    if not spec:
        return []
    pattern = re.compile(spec["pattern"])
    paths = spec.get("paths", ["**"])
    found: set[str] = set()
    for rel in files:
        if not u.any_glob(paths, rel):
            continue
        for match in pattern.finditer(u.read_text(root, rel)):
            found.add(match.group(1))
    return sorted(found)
