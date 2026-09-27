"""React Native repositories: npm packages with a react-native dependency."""

from __future__ import annotations

import re
from pathlib import Path

import common
import parityutil as u

NAME = "rn"
MARKERS = ["package.json"]
SOURCE_SUFFIXES = (".js", ".jsx", ".ts", ".tsx")
DEFAULTS = {
    "feature_globs": ["**/src/features/*", "**/src/screens/*", "**/app/features/*"],
    "test_kinds": [
        {"kind": "ui", "paths": ["**/e2e/**", "**/*.e2e.*"]},
        {"kind": "snapshot", "paths": ["**/__snapshots__/**"]},
        {"kind": "integration", "paths": ["**/*.integration.test.*"]},
    ],
    "default_test_kind": "unit",
    "test_path_globs": ["**/__tests__/**", "**/*.test.*", "**/*.spec.*", "**/e2e/**"],
}

_I18N_KEY = re.compile(r"\"([\w.\-]+)\"\s*:\s*\"")


def detect(root: Path, files: list[str]) -> bool:
    if "package.json" not in files:
        return False
    manifest = u.read_json(root / "package.json")
    dependencies = {**manifest.get("dependencies", {}), **manifest.get("devDependencies", {})}
    return "react-native" in dependencies or "expo" in dependencies


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    found: dict[str, dict] = {}
    for rel in files:
        if Path(rel).name != "package.json":
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
    globs = cfg.get("strings_paths", ["**/locales/**/*.json", "**/i18n/**/*.json"])
    keys: set[str] = set()
    sources: list[str] = []
    for rel in files:
        if not u.any_glob(globs, rel):
            continue
        found = _I18N_KEY.findall(u.read_text(root, rel))
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
