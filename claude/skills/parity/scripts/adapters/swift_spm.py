"""Swift Package Manager repositories (one or more Package.swift manifests)."""

from __future__ import annotations

import re
from pathlib import Path

import common
import parityutil as u

NAME = "swift_spm"
MARKERS = ["Package.swift", "*/Package.swift"]
SOURCE_SUFFIXES = (".swift",)
DEFAULTS = {
    "feature_globs": ["**/Features/*", "**/Scenes/*", "**/Screens/*"],
    "test_kinds": [
        {"kind": "ui", "paths": ["**/*UITests/**", "**/*UITests.swift"]},
        {"kind": "acceptance", "paths": ["**/*AcceptanceTests/**", "**/*Acceptance*Tests.swift"]},
        {"kind": "integration", "paths": ["**/*IntegrationTests/**", "**/*EndToEnd*/**", "**/*Integration*Tests.swift"]},
        {"kind": "contract", "paths": ["**/*ContractTests*/**", "**/*Contract*Tests.swift"]},
    ],
    "default_test_kind": "unit",
    "test_path_globs": ["**/Tests/**", "**/*Tests/**", "**/*Tests.swift"],
}

_TARGET = re.compile(r"\.(testTarget|target|executableTarget)\s*\(\s*name:\s*\"([^\"]+)\"")


def detect(root: Path, files: list[str]) -> bool:
    return any(rel == "Package.swift" or rel.endswith("/Package.swift") for rel in files)


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    found: dict[str, dict] = {}
    for rel in files:
        if not (rel == "Package.swift" or rel.endswith("/Package.swift")):
            continue
        package_dir = Path(rel).parent.as_posix()
        package_id = Path(rel).parent.name or root.name
        found[package_id] = {"id": package_id, "kind": "package", "path": package_dir}
        for _, name in _TARGET.findall(u.read_text(root, rel)):
            found.setdefault(name, {"id": name, "kind": "target", "path": package_dir})
    return sorted(found.values(), key=lambda m: m["id"])


def features(root: Path, files: list[str], cfg: dict, _modules: list[dict]) -> list[dict]:
    globs = cfg.get("feature_globs", DEFAULTS["feature_globs"])
    seen: dict[str, dict] = {}
    for rel in files:
        parts = Path(rel).parts
        for index in range(1, len(parts)):
            candidate = "/".join(parts[:index])
            if candidate in seen or not u.any_glob(globs, candidate):
                continue
            seen[candidate] = {"id": parts[index - 1], "path": candidate}
    return sorted(seen.values(), key=lambda f: f["path"])


def strings(root: Path, files: list[str], cfg: dict) -> dict:
    return common.apple_string_keys(root, files)


def capabilities(root: Path, files: list[str], cfg: dict) -> dict:
    return common.apple_capabilities(root, files)
