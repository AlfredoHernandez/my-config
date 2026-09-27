"""Gradle repositories, Kotlin or Groovy DSL, single or multi-module."""

from __future__ import annotations

import re
from pathlib import Path

import common
import parityutil as u

NAME = "gradle_kts"
MARKERS = ["settings.gradle.kts", "settings.gradle"]
SOURCE_SUFFIXES = (".kt", ".java")
DEFAULTS = {
    "feature_globs": [":feature:*", ":features:*"],
    "test_kinds": [
        {"kind": "ui", "paths": ["**/src/androidTest/**"]},
        {"kind": "screenshot", "paths": ["**/*Screenshot*Test*", "**/*Roborazzi*"]},
        {"kind": "acceptance", "paths": ["**/*Acceptance*Test*"]},
        {"kind": "integration", "paths": ["**/*Integration*Test*", "**/*EndToEnd*Test*"]},
        {"kind": "contract", "paths": ["**/*Contract*Test*"]},
    ],
    "default_test_kind": "unit",
    "test_path_globs": ["**/src/test/**", "**/src/androidTest/**", "**/src/testDebug/**"],
}

_INCLUDE = re.compile(r"""include\s*\(?\s*["']([^"']+)["']""")


def detect(root: Path, files: list[str]) -> bool:
    return any(rel in ("settings.gradle.kts", "settings.gradle") for rel in files)


def _module_path(module_id: str) -> str:
    return module_id.lstrip(":").replace(":", "/")


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    found: dict[str, dict] = {}
    for name in ("settings.gradle.kts", "settings.gradle"):
        if name not in files:
            continue
        for module_id in _INCLUDE.findall(u.read_text(root, name)):
            if not module_id.startswith(":"):
                module_id = f":{module_id}"
            found[module_id] = {"id": module_id, "kind": "gradle-module", "path": _module_path(module_id)}
    if not found:
        found[":"] = {"id": ":", "kind": "gradle-module", "path": "."}
    return sorted(found.values(), key=lambda m: m["id"])


def features(root: Path, files: list[str], cfg: dict, module_list: list[dict]) -> list[dict]:
    globs = cfg.get("feature_globs", DEFAULTS["feature_globs"])
    return [
        {"id": module["id"].rsplit(":", 1)[-1], "path": module["path"], "module": module["id"]}
        for module in module_list
        if u.any_glob(globs, module["id"])
    ]


def strings(root: Path, files: list[str], cfg: dict) -> dict:
    return common.android_string_keys(root, files)


def capabilities(root: Path, files: list[str], cfg: dict) -> dict:
    return common.android_capabilities(root, files)
