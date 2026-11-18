# Kế hoạch thực hiện T052

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chuyển mặc định backend sang `Lớp 11` (`models.py`, `verify_token.py`, `routes/v1.py`) + triển khai server EXP ledger `study-time-v0.1` trong `POST /v1/study/sessions/{id}/finish` (`schemas.py`, `routes/v1.py`) và bổ sung unit/PG tests (`test_api_v1.py`) | `pytest` PASS 100% trên PostgreSQL 16 | [x] |
| 2 | Bổ sung `StudyRoomMode` (`solo`/`withAi`), `StudyCadence` (`deepSilent`/`interval`), `estimatedStudyXp`, `confirmedXpAwarded` vào `study_focus_models.dart`, `study_ai_models.dart`, `remote_study_ai_gateway.dart`, `debug_fixture_study_ai_gateway.dart`, và `StudyFocusViewModel` + callback `onStudyXpSynced` (`app.dart`) | `flutter analyze` 0 lỗi | [x] |
| 3 | Cập nhật `StudySpaceScreen` (chọn `Học một mình` / `Học cùng MindClock`, nhịp `Học sâu` im lặng, ẩn AI ở `solo`, sửa check `vm.remainingSeconds > 0` lúc bấm Kết thúc, tổng kết `EXP dự kiến` / `EXP đã xác nhận`, fallback `Lớp 11`) | Tương thích ngược toàn bộ test `study_focus_local_test.dart` & `backend_integration_contract_test.dart` | [x] |
| 4 | Tạo `app/test/study_room_modes_and_exp_test.dart`, cập nhật `docs/00-start/01-hien-trang.md`, chạy full `flutter test`, `flutter analyze --no-pub`, `RAW_COLOR_HITS: 0`, full `pytest` trên PostgreSQL 16, `check_docs_links.py`, `check_task_records.py`, commit & push `origin/main` | 100% test PASS, SHA khớp `origin/main` | [x] |
