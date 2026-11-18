# T048 — R0/R2: Khôi phục clean-clone Flutter, giải thích quyền mở đầu và chuẩn hóa luồng Đăng ký/Onboarding (ON-01..ON-06)

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. Khắc phục triệt để lỗi biên dịch bản clone sạch `origin/main` ở `app/` (đưa `auth_screen.dart`, `morning_question_selector.dart`, `morning_question_selector_test.dart` vào Git và xác minh trên detached clean Git worktree).
  2. Hoàn thiện cổng R2 (`ON-01..ON-06`): bổ sung phần **Giải thích quyền** không tự bật hộp thoại OS trên `WelcomeScreen`; bổ sung ô **Đồng ý điều khoản & quyền dữ liệu (v1)** và **Xác nhận độ tuổi THPT** trên `AuthScreen` kèm nút `Chỉ dùng báo thức trên máy` và nút Hiện/Ẩn mật khẩu chuẩn `MindClockPressable`; sửa lỗi tràn `Row` 59px trên `AuthScreen`; sửa lỗi rò rỉ hồ sơ/TKB khi đổi tài khoản A → B (`ON-06`) bằng cơ chế lưu tách theo `ownerScopeKey` trong `GuestWorkspaceRepository` & `GuestWorkspaceViewModel` mà vẫn giữ nguyên báo thức local trên máy; viết bộ test đầy đủ `app/test/auth_onboarding_flow_test.dart`.
  3. Cập nhật `docs/00-start/01-hien-trang.md` phản ánh đúng bằng chứng thực tế ngày 2026-11-18.
- **Nguồn yêu cầu:** Yêu cầu triển khai theo lộ trình R0–R5 ngày 2026-11-18, `AGENTS.md §1–§4`, `docs/00-start/02-lo-trinh.md (R0, R2 / B06)`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md (ON-01..ON-06)`, `docs/01-product/04-tai-khoan-quyen-rieng-tu.md`.
- **Chủ sở hữu/reviewer:** Flutter & Backend Systems Architect.
- **Phạm vi file thực tế:**
  - `app/lib/data/repositories/guest_workspace_repository.dart`
  - `app/lib/domain/services/morning_question_selector.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/welcome_screen.dart`
  - `app/lib/ui/features/guest_shell/views/auth_screen.dart`
  - `app/test/morning_question_selector_test.dart`
  - `app/test/auth_onboarding_flow_test.dart`
  - `docs/00-start/01-hien-trang.md`
  - `tasks/T048-r2-auth-onboarding-clean-clone/*`
- **Liên quan:** Không động tới web `/demo`, `/product`, `google-services.json`, hay các task WIP khác (`T022`, `T023`, `T035`, `T036`, `T037`); giữ nguyên báo thức local hoạt động offline/không cần Auth.
- **Source refs đã đọc:** `AGENTS.md §1–§4`, `docs/README.md`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/03-quy-trinh-vibe-code.md`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`, `app/lib/ui/features/guest_shell/views/welcome_screen.dart`, `app/lib/ui/features/guest_shell/views/auth_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/data/services/firebase_auth_gateway.dart`, `app/lib/data/repositories/guest_workspace_repository.dart`, `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`, `app/lib/domain/services/morning_question_selector.dart`.
- **Điểm tiếp tục:** Bước tiếp theo trong cổng R1/R2/R3: (1) bật Email/Password + xác minh email thật trên Firebase Console và nối đồng bộ hồ sơ/TKB/xóa tài khoản đầu-cuối với FastAPI/PostgreSQL; (2) kiểm chứng báo thức native AD01–AD09 trên 2 máy Android vật lý; (3) hoàn thiện luồng R3/R4 (ngân hàng câu `published` đủ môn + OCR ảnh TKB thực tế + AI eval) trước khi mở G2 1v1 và phòng bạn bè cho người dùng.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định 2 broken import trên bản clone sạch (`mindclock_shell_screen.dart -> auth_screen.dart`, `today_screen.dart -> morning_question_selector.dart`) và các điểm thiếu so với `ON-01..ON-06`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-06).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường (`65/65 flutter test PASS`, `dart analyze 0 issues`, xác minh detached clean Git worktree).
- [x] `docs/00-start/01-hien-trang.md` được cập nhật đồng bộ.
- [x] `handoff.md` nêu cách kiểm tra, giới hạn (Firebase Console live & máy Android thật) và điểm tiếp tục.
