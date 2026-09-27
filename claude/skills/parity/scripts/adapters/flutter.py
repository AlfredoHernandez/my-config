"""Flutter repositories: pubspec-defined packages with Dart sources."""

from __future__ import annotations

import re
from pathlib import Path

import common
import parityutil as u

NAME = "flutter"
MARKERS = ["pubspec.yaml"]
SOURCE_SUFFIXES = (".dart",)
DEFAULTS = {
    "feature_globs": ["**/features/*", "**/lib/features/*", "**/screens/*"],
    "test_kinds": [
        {"kind": "ui", "paths": ["**/integration_test/**"]},
        {"kind": "golden", "paths": ["**/*_golden_test.dart", "**/goldens/**"]},
        {"kind": "integration", "paths": ["**/*_integration_test.dart"]},
    ],
    "default_test_kind": "unit",
    "test_path_globs": ["**/test/**", "**/integration_test/**"],
}

_ARB_KEY = re.compile(r"\"([^\"@][^\"]*)\"\s*:")


def detect(root: Path, files: list[str]) -> bool:
    return "pubspec.yaml" in files


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    found: dict[str, dict] = {}
    for rel in files:
        if Path(rel).name != "pubspec.yaml":
            continue
        parent = Path(rel).parent
        module_id = parent.name or root.name
        found[module_id] = {"id": module_id, "kind": "package", "path": parent.as_posix()}
    return sorted(found.values(), key=lambda m: m["id"])


def features(root: Path, files: list[str], cfg: dict, _modules: list[dict]) -> list[dict]:
    globs = cfg.get("feature_globs", DEFAULTS["feature_globs"])
    seen: dict[str, dict] = {}
    for rel in files:
        parts = Path(rel).parts
        for index in range(1, len(parts)):
            candidate = "/".join(parts[:index])
            if candidate not in seen and u.any_glob(globs, candidate):
                seen[candidate] = {"id": parts[index - 1], "path": candidate}
    return sorted(seen.values(), key=lambda f: f["path"])


def strings(root: Path, files: list[str], cfg: dict) -> dict:
    keys: set[str] = set()
    sources: list[str] = []
    for rel in files:
        if not rel.endswith(".arb"):
            continue
        found = _ARB_KEY.findall(u.read_text(root, rel))
        if found:
            sources.append(rel)
            keys.update(found)
    return {"keys": sorted(keys), "sources": sorted(sources)}


def capabilities(root: Path, files: list[str], cfg: dict) -> dict:
    android = common.android_capabilities(root, files)
    apple = common.apple_capabilities(root, files)
    return {
        "permissions": sorted(set(android["permissions"]) | set(apple["permissions"])),
        "components": sorted(set(android["components"]) | set(apple["components"])),
    }
