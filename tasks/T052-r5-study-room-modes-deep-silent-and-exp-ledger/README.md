# T052 — R5: Không gian học (`Học một mình` / `Học cùng MindClock`, `Học sâu` im lặng, Server EXP Ledger `study-time-v0.1` & Mặc định THPT Lớp 11)

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. **Mặc định THPT `Lớp 11` ở backend (`services/api`) & fallback UI:**
     - Chuyển mặc định `grade_band` cho tài khoản mới từ `'Lớp 9'` sang `'Lớp 11'` (cohort đầu THPT 10–12 theo `docs/00-start/02-lo-trinh.md` và `AGENTS.md §1`) trong `models.py`, `verify_token.py`, `routes/v1.py`, đồng thời cập nhật fallback `'Lớp 11'` ở `study_space_screen.dart` và `debug_fixture_study_ai_gateway.dart` (và cập nhật test liên quan).
  2. **Server EXP Ledger `study-time-v0.1` (`POST /v1/study/sessions/{id}/finish`):**
     - Thay thế `xpAwarded: 0` cố định bằng tính toán chuẩn trên server theo `docs/01-product/08-phong-hoc-ai-va-ban-be.md` & `docs/02-engineering/07-khong-gian-hoc.md §1`:
       - Chỉ xét phiên có `state in ('completed', 'finished')`, thời gian nhất quán (`in_app_focus_seconds <= elapsed_wall_seconds` khi `elapsed_wall_seconds > 0`, `endedAt` không nằm ở tương lai/trước `startedAt`).
       - Công thức: `min(floor(active_seconds / 300), 12)` khi `active_seconds >= 300` (5 phút trọn vẹn = 1 EXP, dưới 5 phút hoặc `endedEarly` = 0 EXP).
       - Trần ngày `30 EXP/ngày` tính theo múi giờ đã lưu của người dùng (`user.time_zone`, mặc định `Asia/Ho_Chi_Minh`).
       - Đảm bảo **1 ledger entry duy nhất** cho mỗi `(user_id, 'study_session', study_session.id, 'study_time_v0_1')` trong DB transaction; replay cùng hoặc khác `Idempotency-Key` tuyệt đối không nhân đôi EXP; phản hồi kèm `xpAwarded`, `xpStatus`, `dailyStudyXpRemaining`.
  3. **Flutter R5 Không gian học (`StudyRoomMode`, `StudyCadence.deepSilent`, EXP dự kiến/xác nhận):**
     - Thêm `StudyRoomMode` (`solo` — `Học một mình` vs `withAi` — `Học cùng MindClock`) và `StudyCadence` (`interval` — `Học ngắt quãng` vs `deepSilent` — `Học sâu`) vào `study_focus_models.dart` + `StudyFocusSessionSnapshot` + `StudyFocusRecord`.
     - Trong `Học một mình` (`solo`): không hiển thị/khởi tạo phần AI/avatar/gợi ý hay gọi AI sau phiên.
     - Trong `Học sâu` (`deepSilent`): khóa âm hết giờ và nhắc ngoài app về tắt (`endSoundEnabled = false`, `notifyOutsideApp = false`), không gọi `playSessionEndCue()` / `showSingleStudyReminder()`, AI (nếu ở `Học cùng MindClock`) chỉ trả lời bằng chữ khi người học bấm hỏi.
     - Cập nhật `RemoteStudySessionResult` & `StudyFocusRecord` phân biệt `estimatedStudyXp` (khi offline/chờ đồng bộ) và `confirmedXpAwarded` (từ server `/finish`), cùng callback làm mới `PersonalFlowViewModel.refreshProgress()` khi finish đồng bộ xong.
- **Nguồn yêu cầu:** Lộ trình R5 (`docs/00-start/02-lo-trinh.md`), `docs/01-product/08-phong-hoc-ai-va-ban-be.md (ROOM-01..08)`, `docs/02-engineering/07-khong-gian-hoc.md (FOCUS-09, FOCUS-10)`, yêu cầu người dùng 2026-11-18.
- **Chủ sở hữu/reviewer:** Senior Backend & Flutter Systems Architect.
- **Phạm vi file dự kiến:**
  - `services/api/app/db/models.py`
  - `services/api/app/auth/verify_token.py`
  - `services/api/app/schemas.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_api_v1.py`
  - `app/lib/domain/models/study_focus_models.dart`
  - `app/lib/domain/models/study_ai_models.dart`
  - `app/lib/data/repositories/remote_study_ai_gateway.dart`
  - `app/lib/data/debug/debug_fixture_study_ai_gateway.dart`
  - `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/test/study_room_modes_and_exp_test.dart` (mới)
  - `app/lib/app.dart`
  - `docs/00-start/01-hien-trang.md`
  - `tasks/T052-r5-study-room-modes-deep-silent-and-exp-ledger/*`
- **Source refs đã đọc:** `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/07-khong-gian-hoc.md`, `tasks/T041-study-room-deep-silent-exp/*`, `services/api/app/routes/v1.py`, `services/api/app/db/models.py`, `app/lib/domain/models/study_focus_models.dart`, `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`.
- **Điểm tiếp tục:** Hoàn tất AC-01..AC-05 (`50/50` backend PG 16 tests PASS, `77/77` Flutter tests PASS, `flutter analyze` 0 lỗi, `RAW_COLOR_HITS: 0`). Bước tiếp theo: bật Email/Password trên Firebase Console + kiểm thiết bị Android vật lý (`R6`) hoặc tách mở G2 Đấu trường 1v1 online (`R8`).

## Cổng trước coding

- [x] Đã đọc docs chuẩn R5 (`08-phong-hoc-ai-va-ban-be.md`, `07-khong-gian-hoc.md`), T041 handoff, backend `/study/sessions/*` và Flutter `study_focus/*`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-05).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có kết quả thực chạy trên PostgreSQL 16 + Flutter tests.
- [x] `handoff.md` ghi rõ SHA remote và điểm tiếp tục.
