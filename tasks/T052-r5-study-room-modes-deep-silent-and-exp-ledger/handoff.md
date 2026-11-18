# Bàn giao nhiệm vụ T052

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Chuyển mặc định `grade_band` tài khoản mới và fallback câu/AI sang **THPT `Lớp 11`** ở backend (`models.py`, `verify_token.py`, `routes/v1.py`) và Flutter (`study_space_screen.dart`, `debug_fixture_study_ai_gateway.dart`).
  2. Triển khai **server EXP ledger `study-time-v0.1`** cho `POST /v1/study/sessions/{id}/finish` trong `services/api/app/routes/v1.py` (5 phút tập trung = 1 EXP, tối đa 12/phiên và 30/ngày theo timezone user; kiểm timestamp nhất quán; 1 `XpLedger` duy nhất cho mỗi `study_session`; phản hồi `xpAwarded`, `xpStatus`, `dailyStudyXpRemaining`).
  3. Bổ sung `StudyRoomMode` (`solo` — `Học một mình` vs `withAi` — `Học cùng MindClock`) và `StudyCadence` (`deepSilent` — `Học sâu im lặng` vs `interval` — `Học ngắt quãng`) trong `study_focus_models.dart`, `StudyFocusViewModel`, và `StudySpaceScreen` (ẩn hoàn toàn AI ở `solo`; tắt cố định âm/nhắc & chỉ AI chữ ở `deepSilent`; sửa bug đọc `remainingSec` cũ khi bấm `Kết thúc`).
  4. Bổ sung `estimatedStudyXp` vs `confirmedXpAwarded` trên `StudyFocusRecord`, parse `xpAwarded` từ `/finish` trong `RemoteStudySessionResult`, nối `onStudyXpSynced` trong `app.dart`, và tạo `app/test/study_room_modes_and_exp_test.dart`.
- **File/code/docs thay đổi:**
  - `services/api/app/db/models.py`
  - `services/api/app/auth/verify_token.py`
  - `services/api/app/schemas.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_api_v1.py`
  - `app/lib/app.dart`
  - `app/lib/domain/models/study_focus_models.dart`
  - `app/lib/domain/models/study_ai_models.dart`
  - `app/lib/data/repositories/remote_study_ai_gateway.dart`
  - `app/lib/data/debug/debug_fixture_study_ai_gateway.dart`
  - `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/test/study_room_modes_and_exp_test.dart`
  - `docs/00-start/01-hien-trang.md`
  - `tasks/T052-r5-study-room-modes-deep-silent-and-exp-ledger/*`
- **Test đã chạy (2026-11-18, Windows 11, PostgreSQL 16 `127.0.0.1:5432` & Flutter SDK cục bộ):**
  - Toàn bộ 7 file backend tracked trên PG 16: **50 passed in 18.65s** (0 skipped)
  - `flutter analyze --no-pub`: **No issues found**
  - `flutter test`: **77/77 PASS**
  - Quét `Color(0x` ngoài `MindClockTheme`: **RAW_COLOR_HITS: 0**
  - `python scripts/check_docs_links.py` & `python scripts/check_task_records.py` (sẽ xác nhận lại trước push)
- **Rủi ro còn lại:**
  - Chưa test đầu-cuối trên **2 máy Android vật lý** (chuông màn khóa, Dừng khẩn cấp offline, Firebase Auth Email/Password thật trên Firebase Console).
  - Phòng bạn bè qua QR/link (`R7`), avatar AI Live Audio (`R7`) và Đấu trường G2–G4 (`R8`) vẫn nằm ở các lát tiếp theo sau cổng R6.
- **Điểm tiếp tục chính xác:** Bật Email/Password trên Firebase Console + kiểm thiết bị Android vật lý (`R6`: B02/ON-01..06/FOCUS-09..10) hoặc triển khai client G2 Đấu trường 1v1 online (`R8`).
- **Git:** Đang chuẩn bị commit & push lên `origin/main` (cập nhật SHA sau push).
