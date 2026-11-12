"""Check local Markdown links in project documentation and root README."""
from pathlib import Path
from urllib.parse import unquote
import re

ROOT = Path(__file__).resolve().parents[1]
files = [ROOT / "README.md", *sorted((ROOT / "docs").glob("*.md"))]
missing = []
for file in files:
    body = file.read_text(encoding="utf-8")
    for raw in re.findall(r"(?<!!)\[[^\]]*\]\(([^)]+)\)", body):
        url = raw.split("#", 1)[0].split(" ", 1)[0].strip("<>")
        if not url or "://" in url or url.startswith(("mailto:", "#")):
            continue
        target = (file.parent / unquote(url)).resolve()
        if not target.exists():
            missing.append(f"{file.relative_to(ROOT)} -> {url}")
if missing:
    print("Missing local links:\n" + "\n".join(missing))
    raise SystemExit(1)
print(f"PASS local links in {len(files)} documentation files")
