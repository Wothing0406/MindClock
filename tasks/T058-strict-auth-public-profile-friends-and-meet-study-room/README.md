# T058 — Bỏ Guest Mode, Mật khẩu mạnh, Toàn văn Chính sách & Gói B (Profile công khai, Kết bạn, Quét phòng Meet + AI ghép nhóm)

- **Trạng thái:** `in_progress`
- **Mục tiêu:** Loại bỏ luồng Guest dùng thử không tài khoản trên màn hình chính (giữ fallback chỉ dùng báo thức cục bộ khi mất mạng/Auth lỗi), bắt buộc mật khẩu mạnh ($\ge 8$ ký tự, hoa/thường/số/ký tự đặc biệt) kèm modal đọc toàn văn Chính sách Bảo mật & Điều khoản trước khi tích đồng ý, và triển khai đầy đủ **Gói B**: Profile công khai (`avatar` + môn học + mục tiêu), Kết bạn & Tìm bạn, Quét phòng học công khai/riêng tư, AI ghép nhóm theo trình độ, và giao diện phòng học dạng lưới kiểu Google Meet kèm avatar 2D MindClock AI cử động.
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `services/api/alembic/versions/0004_add_community_friends_and_study_rooms.py`
  - `services/api/app/models/entities.py`, `services/api/app/routes/v1.py`, `services/api/app/schemas/*.py`, `services/api/tests/test_community_rooms_and_friends.py`
  - `app/lib/ui/features/guest_shell/views/{welcome_screen.dart,auth_screen.dart,me_guest_screen.dart}`
  - `app/lib/domain/models/community_models.dart`, `app/lib/domain/services/personal_flow_repository.dart`, `app/lib/data/repositories/remote_personal_flow_repository.dart`, `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`, `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/study_focus/views/{study_community_sheet.dart,study_space_screen.dart}`
  - `app/test/{auth_onboarding_flow_test.dart,community_friends_and_meet_room_test.dart}`
  - `docs/00-start/01-hien-trang.md`, `tasks/T058-*/*`.
- **Liên quan:** `T048`, `T051`, `T052`, `T057`.
- **Source refs đã đọc:** `docs/01-product/04-tai-khoan-quyen-rieng-tu.md`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/04-hop-dong-api.md`, `app/lib/ui/features/guest_shell/views/welcome_screen.dart`, `app/lib/ui/features/guest_shell/views/auth_screen.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`.
- **Điểm tiếp tục:** Triển khai Auth chặt (bỏ Guest UI + Strong Password + Policy dialog), backend PostgreSQL migration + API Gói B, và Flutter UI Profile công khai / Kết bạn / Quét phòng Meet + AI 2D avatar cử động.

## Cổng trước coding

- [x] Đã cập nhật canonical docs (`04`, `07`, `08`, `02-engineering/04`) trước khi code.
- [x] Đã đọc kỹ `welcome_screen.dart`, `auth_screen.dart`, `study_space_screen.dart`, `routes/v1.py`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và có bằng chứng test thật (`pytest` PG16 + `flutter test` + `flutter analyze`).
- [ ] Các bước `plan.md` đánh dấu `[x]`.
- [ ] `tests.md` ghi đủ lệnh, kết quả, ngày/môi trường.
- [ ] `docs/00-start/01-hien-trang.md` & `handoff.md` cập nhật kèm SHA remote đã xác minh.
