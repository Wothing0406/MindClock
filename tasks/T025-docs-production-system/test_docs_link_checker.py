"""Regression: the checker must detect a broken link in nested docs."""

from pathlib import Path
from tempfile import TemporaryDirectory
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from scripts.check_docs_links import check  # noqa: E402


with TemporaryDirectory(dir=ROOT) as temp:
    folder = Path(temp) / "nested"
    folder.mkdir()
    file = folder / "test.md"
    file.write_text("[good](../../README.md)\n", encoding="utf-8")
    assert check([file]) == []
    file.write_text("[broken](missing.md)\n", encoding="utf-8")
    assert len(check([file])) == 1
print("PASS nested local link regression")
