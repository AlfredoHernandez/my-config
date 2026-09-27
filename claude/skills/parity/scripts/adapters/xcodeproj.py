"""Xcode project or workspace repositories without package manifests."""

from __future__ import annotations

from pathlib import Path

import common
import swift_spm

NAME = "xcodeproj"
MARKERS = ["*.xcodeproj", "*.xcworkspace"]
SOURCE_SUFFIXES = swift_spm.SOURCE_SUFFIXES
DEFAULTS = dict(swift_spm.DEFAULTS)

_PROJECT_SUFFIXES = (".xcodeproj", ".xcworkspace")


def detect(root: Path, files: list[str]) -> bool:
    return any(entry.name.endswith(_PROJECT_SUFFIXES) for entry in root.iterdir())


def modules(root: Path, files: list[str], cfg: dict) -> list[dict]:
    found = {m["id"]: m for m in swift_spm.modules(root, files, cfg)}
    for entry in sorted(root.iterdir(), key=lambda p: p.name):
        if entry.name.endswith(_PROJECT_SUFFIXES):
            stem = entry.name.rsplit(".", 1)[0]
            found.setdefault(stem, {"id": stem, "kind": "project", "path": entry.name})
    for rel in files:
        top = Path(rel).parts[0]
        if rel.endswith(".swift") and "/" in rel:
            found.setdefault(top, {"id": top, "kind": "group", "path": top})
    return sorted(found.values(), key=lambda m: m["id"])


features = swift_spm.features
strings = swift_spm.strings
capabilities = swift_spm.capabilities
