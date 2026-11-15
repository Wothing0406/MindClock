"""Check local Markdown links in canonical docs, archive, task records and entrypoints."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def local_target(raw: str, source: Path) -> Path | None:
    raw = raw.strip()
    if raw.startswith("<"):
        url = raw.split(">", 1)[0][1:]
    else:
        url = raw.split(" ", 1)[0]
    url = url.split("#", 1)[0]
    if not url or url.startswith(("#", "mailto:", "data:")) or "://" in url:
        return None
    return (source.parent / unquote(url)).resolve()


def check(files: list[Path]) -> list[str]:
    missing: list[str] = []
    for file in files:
        if not file.is_file():
            missing.append(f"Missing Markdown file: {file}")
            continue
        body = file.read_text(encoding="utf-8")
        for raw in LINK.findall(body):
            target = local_target(raw, file)
            if target is not None and not target.exists():
                missing.append(f"{file.relative_to(ROOT) if file.is_relative_to(ROOT) else file} -> {raw}")
    return missing


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", action="append", type=Path, help="Check only this Markdown file")
    args = parser.parse_args()
    files = (
        [path.resolve() for path in args.file]
        if args.file
        else [
            ROOT / "README.md",
            ROOT / "AGENTS.md",
            *sorted((ROOT / ".agents" / "skills").rglob("*.md")),
            *sorted((ROOT / "docs").rglob("*.md")),
            *sorted((ROOT / "tasks").rglob("*.md")),
        ]
    )
    missing = check(files)
    if missing:
        print("Missing local links:\n" + "\n".join(missing))
        return 1
    print(f"PASS local links in {len(files)} Markdown files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
