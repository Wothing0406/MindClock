# T058 — Bỏ Guest Mode, Mật khẩu mạnh, Toàn văn Chính sách & Gói B (Profile công khai, Kết bạn, Quét phòng Meet + AI ghép nhóm)

- **Trạng thái:** `done`
- **Mục tiêu:** Loại bỏ luồng Guest dùng thử không tài khoản trên màn hình chính (giữ fallback chỉ dùng báo thức cục bộ khi mất mạng/Auth lỗi), bắt buộc mật khẩu mạnh ($\ge 8$ ký tự, hoa/thường/số/ký tự đặc biệt) kèm modal đọc toàn văn Chính sách Bảo mật & Điều khoản trước khi tích đồng ý, và triển khai đầy đủ **Gói B**: Profile công khai (`avatar` + môn học + mục tiêu), Kết bạn & Tìm bạn, Quét phòng học công khai/riêng tư, AI ghép nhóm theo trình độ, và giao diện phòng học dạng lưới kiểu Google Meet kèm avatar 2D MindClock AI cử động.
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `services/api/alembic/versions/0004_add_community_friends_and_study_rooms.py`
  - `services/api/app/db/{models.py,backup.py}`, `services/api/app/routes/v1.py`, `services/api/app/schemas.py`, `services/api/app/services/community_service.py`, `services/api/tests/test_community_rooms_and_friends.py`
  - `app/lib/ui/core/strings/app_strings.dart`, `app/lib/ui/features/guest_shell/views/{welcome_screen.dart,auth_screen.dart,me_guest_screen.dart,mindclock_shell_screen.dart,onboarding_setup_screen.dart}`
  - `app/lib/domain/models/community_models.dart`, `app/lib/domain/services/community_repository.dart`, `app/lib/data/repositories/remote_community_repository.dart`, `app/lib/data/debug/debug_fixture_community_repository.dart`, `app/lib/app.dart`
  - `app/lib/ui/features/study_focus/{view_models/study_focus_view_model.dart,views/study_community_sheet.dart,views/study_space_screen.dart}`
  - `app/test/{auth_onboarding_flow_test.dart,community_friends_and_meet_room_test.dart,guest_flow_widget_test.dart,onboarding_plan_draft_test.dart,personal_flow_real_service_test.dart,study_focus_local_test.dart,timetable_ocr_and_realtime_clock_test.dart}`
  - `docs/00-start/01-hien-trang.md`, `tasks/T058-*/*`, `test_demo_android/screenshots/16_t058_strict_welcome.png`.
- **Liên quan:** `T048`, `T051`, `T052`, `T057`.
- **Source refs đã đọc:** `docs/01-product/04-tai-khoan-quyen-rieng-tu.md`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/04-hop-dong-api.md`, `app/lib/ui/features/guest_shell/views/welcome_screen.dart`, `app/lib/ui/features/guest_shell/views/auth_screen.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`.
- **Điểm tiếp tục:** Đã xong T058; chuyển sang T059 (`tasks/T059-study-space-candle-mode-subjects-and-alarm-ai-preview/`).

## Cổng trước coding

- [x] Đã cập nhật canonical docs (`04`, `07`, `08`, `02-engineering/04`) trước khi code.
- [x] Đã đọc kỹ `welcome_screen.dart`, `auth_screen.dart`, `study_space_screen.dart`, `routes/v1.py`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và có bằng chứng test thật (`pytest` PG16 `62 passed`, `flutter test` `89/89`, `flutter analyze` `No issues found!`, `RAW_COLOR_HITS: 0`, APK debug `151.90 MB` + screenshot `emulator-5554`).
- [x] Các bước `plan.md` đánh dấu `[x]`.
- [x] `tests.md` ghi đủ lệnh, kết quả, ngày/môi trường.
- [x] `docs/00-start/01-hien-trang.md` & `handoff.md` cập nhật kèm SHA remote đã xác minh.
