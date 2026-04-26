#!/usr/bin/env python3
"""Scan the repository for hidden / bidirectional / zero-width Unicode.

This repo distributes AI agent instructions. Invisible Unicode in those
files is a credible attack surface (bidi controls and zero-width joiners
can hide content from human reviewers while still influencing tokenizers).

Run from the repo root:

    python3 scripts/check-hidden-unicode.py

Exits 0 if clean, 1 with a list of file:line:column hits otherwise.
Suitable for use as a CI check.
"""

from __future__ import annotations

import pathlib
import sys

# Suspicious code-point ranges and individual code points.
BIDI = set(range(0x202A, 0x202F)) | set(range(0x2066, 0x206A))
ZERO_WIDTH = {0x200B, 0x200C, 0x200D, 0xFEFF}
TAG_CHARS = set(range(0xE0000, 0xE0080))

SUSPICIOUS = BIDI | ZERO_WIDTH | TAG_CHARS

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", ".mypy_cache"}

# Extensions worth scanning. Binary formats are skipped automatically when
# they fail UTF-8 decoding, but listing extensions cheaply prunes the walk.
SCANNED_EXTENSIONS = {
    ".md", ".mdc", ".txt", ".sh", ".yml", ".yaml", ".json",
    ".py", ".toml", ".ini", ".cfg", ".html",
}

# Files without an extension that we still care about.
SCANNED_NAMES = {
    "AGENTS.md", "CODEOWNERS", ".version", "LICENSE",
    ".gitignore",
}


def should_scan(path: pathlib.Path) -> bool:
    if any(part in SKIP_DIRS for part in path.parts):
        return False
    if not path.is_file():
        return False
    if path.suffix.lower() in SCANNED_EXTENSIONS:
        return True
    if path.name in SCANNED_NAMES:
        return True
    return False


def scan(root: pathlib.Path) -> list[str]:
    failures: list[str] = []
    for path in root.rglob("*"):
        if not should_scan(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for offset, ch in enumerate(text):
            code = ord(ch)
            if code in SUSPICIOUS:
                line = text.count("\n", 0, offset) + 1
                col = offset - text.rfind("\n", 0, offset)
                rel = path.relative_to(root)
                failures.append(f"{rel}:{line}:{col}: U+{code:04X}")
    return failures


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    failures = scan(root)
    if failures:
        print("Suspicious Unicode characters found:", file=sys.stderr)
        for item in failures:
            print(f"  {item}", file=sys.stderr)
        return 1
    print("No hidden / bidirectional / zero-width Unicode found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
