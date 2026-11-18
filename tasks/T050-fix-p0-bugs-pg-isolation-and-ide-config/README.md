# T050 — Sửa nhóm lỗi P0 từ báo cáo rà soát, cô lập DB test PostgreSQL và cấu hình IDE

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. Khắc phục triệt để lỗi `DependentObjectsStillExist: cannot drop table questions` khi chạy pytest live PostgreSQL trên DB dev `mindclock` (guard `create_all` trong `main.py` không chạy đè khi đã có `alembic_version`, và cô lập 2 ca live PostgreSQL vào DB tạm `mindclock_pytest_<hex>` tự dọn `WITH (FORCE)` trong `finally:`).
  2. Sửa lỗi 404 `POST /v1/v1/timetable/parse-image` → `/timetable/parse-image` trong `app/lib/data/services/personal_api_client.dart` kèm unit test xác minh URI chính xác.
  3. Sửa 3 bug thật trong `pvp_match_service.py`: (a) round `void` do `uncertain` tự mở round kế tiếp (hoặc kết thúc gọn ở round 6) không để trận treo chết; (b) `submit_round_answer` trả `'grading_pending'` và không lộ `feedback_vi` trước khi cả 2 bên nộp; (c) xóa 4 import thừa (`dataclass`, `and_`, `or_`, `ChampionId`).
  4. Xóa màu hardcode cuối cùng `Color(0xFF22C55E)` trong `app/lib/ui/features/guest_shell/views/today_screen.dart` sang token `mc.primary`.
  5. Thêm `.vscode/settings.json` cấu hình đúng `.venv`, `extraPaths: ["services/api"]` và `.local-sdk/flutter` để dập sạch 285 cảnh báo cấu hình IDE.
- **Nguồn yêu cầu:** Báo cáo rà soát toàn diện ngày 2026-11-18, lỗi thực tế terminal `pwsh` (`DependentObjectsStillExist`) và ảnh bảng Problems IDE.
- **Chủ sở hữu/reviewer:** Senior Backend & Flutter Architect.
- **Phạm vi file thực tế:**
  - `services/api/app/main.py`
  - `services/api/app/services/pvp_match_service.py`
  - `services/api/tests/test_migrations_and_data_invariants.py`
  - `services/api/tests/test_pvp_matchmaking.py`
  - `app/lib/data/services/personal_api_client.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/test/timetable_ocr_and_realtime_clock_test.dart`
  - `.vscode/settings.json`
  - `tasks/T050-fix-p0-bugs-pg-isolation-and-ide-config/*`
- **Liên quan:** Tiếp nối trực tiếp `T038`, `T048`, `T049`.
- **Source refs đã đọc:** `AGENTS.md §3–§4`, `docs/02-engineering/03-du-lieu-sql.md`, `docs/02-engineering/04-hop-dong-api.md`, `docs/04-game/01-pvp-gdd.md`, `services/api/app/main.py`, `services/api/app/services/pvp_match_service.py`, `services/api/tests/test_migrations_and_data_invariants.py`, `services/api/tests/test_pvp_matchmaking.py`, `app/lib/data/services/personal_api_client.dart`, `app/lib/ui/features/guest_shell/views/today_screen.dart`.
- **Điểm tiếp tục:** Tiếp tục các gói R2/R3 (nối `PATCH /v1/me`, `PUT /v1/timetable`, `DELETE /v1/me` và cập nhật mặc định/seed THPT 10–12 ở backend) hoặc R5 (Không gian học `Học sâu` im lặng + server EXP ledger thay cho `xpAwarded: 0`).

## Cổng trước coding

- [x] Đã tái hiện nguyên nhân gốc `DependentObjectsStillExist` trực tiếp trên `api-postgres-1` (`alembic_version=0002` + 7 bảng PvP do `create_all`).
- [x] Đã xác nhận lỗi `/v1/v1/timetable/parse-image` và các bug PvP/UI trực tiếp trong mã nguồn.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-05).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có kết quả chạy thật trên live PostgreSQL 16 (12/12 + 49/49 PASS) và Flutter (70/70 PASS + 0 lỗi analyze).
- [x] `handoff.md` nêu rõ kết quả, SHA remote và điểm tiếp tục.
