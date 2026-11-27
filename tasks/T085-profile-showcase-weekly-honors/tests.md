# Kiểm thử T085

| Test ID | Mapping AC | Lệnh kiểm tra | Trạng thái | Ngày / Môi trường |
| --- | --- | --- | --- | --- |
| `TC-01` | `AC-01`, `AC-02` | `.\.venv\Scripts\python.exe -m pytest -q` | `passed` (`92 passed, 10 skipped`) | `2026-11-27` / Windows SQLite + FastAPI `TestClient` |
| `TC-02` | `AC-03` | `flutter analyze --no-pub` | `passed` (`No issues found`) | `2026-11-27` / Windows Flutter SDK |
| `TC-03` | `AC-03` | `flutter test --no-pub -j 1` | `passed` (`181 passed`, bao gồm `t085_profile_showcase_test.dart` và `t078_real_profile_and_sync_test.dart`) | `2026-11-27` / Windows Flutter `TestWidgets` |
