"""Fallback adapter: everything comes from what pair.json declares.

This is the escape hatch that keeps the tool honest about unknown stacks. It
infers nothing from names, so a project on a toolchain nobody wrote an adapter
for still audits correctly as long as it declares its own globs.
"""

from __future__ import annotations

from pathlib import Path

import common
import parityutil as u

NAME = "generic"
MARKERS: list[str] = []
SOURCE_SUFFIXES = (".swift", ".kt", ".java", ".dart", ".ts", ".tsx", ".js", ".jsx")
DEFAULTS = {
    "feature_globs": [],
    "test_kinds": [],
    "default_test_kind": "unit",
    "test_path_globs": ["**/test/**", "**/tests/**", "**/Tests/**"],
}


def detect(root: Path, files: list[str]) -> bool:
    return True


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    return [
        {"id": entry["id"], "kind": "declared", "path": entry["path"]}
        for entry in cfg.get("declared_modules", [])
    ]


def features(root: Path, files: list[str], cfg: dict, _modules: list[dict]) -> list[dict]:
    globs = cfg.get("feature_globs", [])
    seen: dict[str, dict] = {}
    for rel in files:
        parts = Path(rel).parts
        for index in range(1, len(parts)):
            candidate = "/".join(parts[:index])
            if candidate not in seen and globs and u.any_glob(globs, candidate):
                seen[candidate] = {"id": parts[index - 1], "path": candidate}
    return sorted(seen.values(), key=lambda f: f["path"])


def strings(root: Path, files: list[str], cfg: dict) -> dict:
    globs = cfg.get("strings_paths", [])
    if not globs:
        return {"keys": [], "sources": []}
    subset = [rel for rel in files if u.any_glob(globs, rel)]
    android = common.android_string_keys(root, subset)
    apple = common.apple_string_keys(root, subset)
    return {
        "keys": sorted(set(android["keys"]) | set(apple["keys"])),
        "sources": sorted(set(android["sources"]) | set(apple["sources"])),
    }


def capabilities(root: Path, files: list[str], cfg: dict) -> dict:
    android = common.android_capabilities(root, files)
    apple = common.apple_capabilities(root, files)
    return {
        "permissions": sorted(set(android["permissions"]) | set(apple["permissions"])),
        "components": sorted(set(android["components"]) | set(apple["components"])),
    }
