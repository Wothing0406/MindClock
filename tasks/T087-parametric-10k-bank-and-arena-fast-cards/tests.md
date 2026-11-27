# Kiểm thử T087

| Test ID | Mapping AC | Lệnh kiểm tra | Trạng thái | Ngày / Môi trường |
| --- | --- | --- | --- | --- |
| `TC-01` | `AC-01` | `.\.venv\Scripts\python.exe -m pytest -q` | `passed` (`93 passed, 10 skipped`) | `2026-11-27` / Windows SQLite + FastAPI `TestClient` |
| `TC-02` | `AC-02` | `flutter analyze --no-pub ; flutter test --no-pub -j 1` | `passed` (`No issues found`, `183 passed`) | `2026-11-27` / Windows Flutter `TestWidgets` |
| `TC-03` | Repo checks | `python scripts/check_docs_links.py ; python scripts/check_task_records.py ; python scripts/check_game_assets.py` | `passed` (`742 Markdown files`, `Task records OK`) | `2026-11-27` / Windows Python |
