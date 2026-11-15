"""One-time, idempotent migration of numbered docs to the 2026-11 archive.

Rewrites local Markdown links from their original resolved target to the new
relative path. Run from any working directory; never moves files outside repo.
"""

from __future__ import annotations

import os
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
ARCHIVE = DOCS / "archive" / "2026-11"
LINK = re.compile(r"(!?\[[^\]]*\]\()([^)]+)(\))")


def within_repo(path: Path) -> bool:
    return path.resolve().is_relative_to(ROOT.resolve())


def remap_link(raw: str, old_source: Path, new_source: Path, mapping: dict[Path, Path]) -> str:
    # Markdown links in this repo use paths without a title. Keep external and
    # anchor-only URLs untouched; do not reinterpret query strings.
    if raw.startswith(("https://", "http://", "mailto:", "#", "data:")):
        return raw
    body, hashmark, fragment = raw.partition("#")
    if not body or "://" in body or " " in body:
        return raw
    old_target = (old_source.parent / body).resolve()
    new_target = mapping.get(old_target, old_target)
    if not within_repo(new_target):
        return raw
    relative = Path(os.path.relpath(new_target, new_source.parent)).as_posix()
    return relative + (hashmark + fragment if hashmark else "")


def main() -> None:
    old_files = sorted(DOCS.glob("[0-9][0-9]-*.md"))
    mapping = {path.resolve(): (ARCHIVE / path.name).resolve() for path in old_files}
    for source, target in mapping.items():
        if not within_repo(source) or not within_repo(target):
            raise RuntimeError("Refusing path outside workspace")
        if target.exists():
            raise RuntimeError(f"Archive target already exists: {target}")
    ARCHIVE.mkdir(parents=True, exist_ok=True)

    sources = [ROOT / "README.md", ROOT / "AGENTS.md"]
    sources.extend(DOCS.rglob("*.md"))
    sources.extend((ROOT / "tasks").rglob("*.md"))
    rewrites: dict[Path, str] = {}
    for source in sources:
        if not source.is_file():
            continue
        new_source = mapping.get(source.resolve(), source.resolve())
        original = source.read_text(encoding="utf-8")
        rewritten = LINK.sub(
            lambda match: match.group(1)
            + remap_link(match.group(2), source, new_source, mapping)
            + match.group(3),
            original,
        )
        if rewritten != original:
            rewrites[new_source] = rewritten

    for source, target in mapping.items():
        source.rename(target)
    for target, body in rewrites.items():
        target.write_text(body, encoding="utf-8")
    print(f"Archived {len(mapping)} numbered docs; rewrote links in {len(rewrites)} Markdown files")


if __name__ == "__main__":
    main()
