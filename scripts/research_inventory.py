"""Inventory local research corpora without copying question text into Git.

Run from repository root: python scripts/research_inventory.py
Only reads data/research/raw and writes a metadata-only manifest.
"""

from __future__ import annotations

import collections
import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "research" / "raw"
OUT = ROOT / "data" / "research" / "research-manifest.json"


def head(path: Path) -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=path, text=True
    ).strip()


def digest_files(files: list[Path], base: Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(files):
        relative = path.relative_to(base).as_posix()
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def vnhsge() -> dict:
    repo = RAW / "vnhsge"
    base = repo / "Dataset" / "VNHSGE-V" / "JSON format"
    files = list(base.rglob("*.json"))
    if not files:
        raise RuntimeError("VNHSGE JSON files missing")
    splits = collections.Counter()
    subjects = collections.Counter()
    schemas = collections.Counter()
    parse_errors = []
    item_count = 0
    for path in files:
        parts = path.relative_to(base).parts
        try:
            rows = json.loads(path.read_text(encoding="utf-8-sig"))
            if not isinstance(rows, list):
                raise ValueError("top-level JSON is not a list")
            item_count += len(rows)
            splits[parts[0]] += len(rows)
            subjects[parts[1]] += len(rows)
            for row in rows:
                if isinstance(row, dict):
                    schemas["|".join(sorted(row.keys()))] += 1
        except (UnicodeError, json.JSONDecodeError, ValueError) as exc:
            parse_errors.append({"file": path.relative_to(repo).as_posix(), "error": type(exc).__name__})
    return {
        "source_id": "vnhsge",
        "source_url": "https://github.com/Xdao85/VNHSGE",
        "commit": head(repo),
        "scope": "Vietnamese JSON files only; images and Word files excluded",
        "file_count": len(files),
        "item_count_parsed": item_count,
        "by_split": dict(sorted(splits.items())),
        "by_subject": dict(sorted(subjects.items())),
        "schema_key_signatures": dict(sorted(schemas.items())),
        "parse_errors": parse_errors,
        "sha256_file_set": digest_files(files, repo),
        "publication_status": "research_only_not_app_approved",
    }


def vmlu() -> dict:
    repo = RAW / "vmlu-hf-mirror"
    files = list(repo.glob("*.jsonl"))
    if not files:
        raise RuntimeError("VMLU JSONL files missing")
    splits = {}
    ids = set()
    duplicate_ids = 0
    schemas = collections.Counter()
    errors = []
    for path in files:
        count = 0
        with path.open(encoding="utf-8") as stream:
            for line_no, line in enumerate(stream, 1):
                try:
                    row = json.loads(line)
                    count += 1
                    schemas["|".join(sorted(row.keys()))] += 1
                    item_id = row.get("id")
                    if item_id in ids:
                        duplicate_ids += 1
                    ids.add(item_id)
                except (json.JSONDecodeError, AttributeError):
                    errors.append({"file": path.name, "line": line_no})
        splits[path.name] = count
    return {
        "source_id": "vmlu",
        "source_url": "https://huggingface.co/datasets/tridm/VMLU",
        "provenance_note": "Third-party public mirror; not the official VMLU download",
        "commit": head(repo),
        "file_count": len(files),
        "item_count_parsed": sum(splits.values()),
        "by_file": dict(sorted(splits.items())),
        "duplicate_ids": duplicate_ids,
        "schema_key_signatures": dict(sorted(schemas.items())),
        "parse_errors": errors,
        "sha256_file_set": digest_files(files, repo),
        "publication_status": "research_only_not_app_approved",
    }


def main() -> None:
    manifest = {
        "inventory_version": 1,
        "checked_at": "2026-11-11",
        "notice": "Metadata only. Raw corpus is local and gitignored. Counts are parsed, not approved questions.",
        "sources": [vnhsge(), vmlu()],
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    for source in manifest["sources"]:
        print(source["source_id"], source["file_count"], source["item_count_parsed"], len(source["parse_errors"]))


if __name__ == "__main__":
    main()
