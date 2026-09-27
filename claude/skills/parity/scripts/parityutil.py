"""Shared helpers for the parity toolchain. Stdlib only, deterministic output."""

from __future__ import annotations

import hashlib
import json
import os
import re
from pathlib import Path

CONTRACT_FILES = ("pair.json", "features.json", "strings.json", "telemetry.json")
LOCK_NAME = "CONTRACT.lock"
# Directories whose contents are part of the contract, and the extension that
# counts. `templates/guard.py` restates this rule because it must stay
# dependency-free; the selftest checks the two never drift apart.
MEMBER_DIRS = (("fixtures", "*.json"), ("use-cases", "*.md"))
FIXTURES_DIR = "fixtures"

PRUNE = {
    ".git", ".gradle", ".idea", ".svn", "build", "out", "dist", "node_modules",
    "Pods", "Carthage", "DerivedData", ".build", "xcuserdata", ".venv",
    "__pycache__", ".dart_tool", ".next", "vendor",
}


class ParityError(Exception):
    """Raised for conditions the caller must surface rather than swallow."""


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ParityError(f"missing file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ParityError(f"malformed JSON in {path}: {exc}") from exc


def dumps(obj) -> str:
    return json.dumps(obj, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def write_json(path: Path, obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dumps(obj), encoding="utf-8")


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_text(text: str) -> str:
    return sha256_bytes(text.encode("utf-8"))


def walk(root: Path, suffixes: tuple[str, ...] | None = None) -> list[str]:
    """Repo-relative POSIX paths, sorted, with build and VCS noise pruned."""
    found: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in PRUNE and not d.endswith(".xcodeproj"))
        for name in filenames:
            if suffixes and not name.endswith(suffixes):
                continue
            found.append(Path(dirpath, name).relative_to(root).as_posix())
    return sorted(found)


def read_text(root: Path, rel: str) -> str:
    return (root / rel).read_text(encoding="utf-8", errors="replace")


def glob_matches(pattern: str, path: str) -> bool:
    """Glob match where ** spans separators and * does not."""
    regex = ["^"]
    i = 0
    while i < len(pattern):
        char = pattern[i]
        if pattern.startswith("**/", i):
            regex.append("(?:.*/)?")
            i += 3
        elif pattern.startswith("**", i):
            regex.append(".*")
            i += 2
        elif char == "*":
            regex.append("[^/]*")
            i += 1
        elif char == "?":
            regex.append("[^/]")
            i += 1
        else:
            regex.append(re.escape(char))
            i += 1
    regex.append("$")
    return re.match("".join(regex), path) is not None


def any_glob(patterns, path: str) -> bool:
    return any(glob_matches(p, path) for p in patterns)


def contract_dir(root: Path) -> Path:
    return root / "parity"


def contract_members(base: Path) -> list[str]:
    """Every file the contract consists of, as paths relative to `parity/`."""
    members = [name for name in CONTRACT_FILES if (base / name).exists()]
    for directory, pattern in MEMBER_DIRS:
        root = base / directory
        if root.is_dir():
            members += [path.relative_to(base).as_posix() for path in root.rglob(pattern)]
    return sorted(members)


def lock_for(root: Path) -> dict:
    """Checksum every contract file. Self-contained: reads one repo only."""
    base = contract_dir(root)
    entries = {name: sha256_bytes((base / name).read_bytes()) for name in contract_members(base)}
    if not entries:
        raise ParityError(f"no contract found under {base}")
    aggregate = sha256_text("".join(f"{k}:{v}\n" for k, v in sorted(entries.items())))
    return {"schema": 1, "files": entries, "contract": aggregate}


def load_pair(root: Path) -> dict:
    pair = read_json(contract_dir(root) / "pair.json")
    for field in ("platforms", "axes"):
        if field not in pair:
            raise ParityError(f"pair.json is missing required field '{field}'")
    return pair


def load_local(root: Path) -> dict:
    """Machine-specific sibling paths. Never read by a repo's own test suite."""
    path = root / ".parity.local.json"
    return read_json(path) if path.exists() else {}


def feature_identifiers(feature: dict) -> set[str]:
    """The names a feature can be referred to by in the contract's feature map."""
    return {value for value in (feature.get("id"), feature.get("path"), feature.get("module")) if value}


def feature_matches(feature: dict, patterns) -> bool:
    """Whether a contract mapping entry claims this inventory feature.

    Shared by the comparator and the listing on purpose: two different answers
    to "is this feature mapped" would put the audit and the list in
    disagreement, and the person reading them would have no way to tell which
    one was lying.
    """
    identifiers = feature_identifiers(feature)
    patterns = list(patterns)
    return bool(identifiers & set(patterns)) or any(any_glob(patterns, value) for value in identifiers)
