# T035 — Chuẩn hóa luồng Đăng nhập, Đăng ký và Onboarding THPT Lớp 10–12 làm Happy Path chính

- **Trạng thái:** `done`
- **Mục tiêu:** Chuyển đổi luồng khởi động đầu tiên từ "Mặc định chế độ khách" sang Happy Path: Chào mừng -> Đăng ký/Đăng nhập -> Onboarding THPT 10-12 (môn, mức tự đánh giá, avatar, xác nhận kế hoạch) -> Vào Hôm nay không thẻ kỹ thuật debug. Báo thức local vẫn có đường dùng cứu sinh khi offline.
- **Nguồn yêu cầu:** Phản hồi người dùng trên Android Emulator ngày 2026-11-16: Hôm nay còn ghi 'chế độ khách/local', thiếu báo thức, giao diện nhỏ nhiều thẻ kỹ thuật.
- **Chủ sở hữu/reviewer:** Senior Mobile & Backend Systems Architect.
- **Phạm vi file dự kiến:**
  - `app/lib/domain/models/study_profile.dart`
  - `app/lib/domain/models/subject_catalog.dart`
  - `app/lib/ui/features/guest_shell/views/auth_screen.dart`
  - `app/lib/ui/features/guest_shell/views/welcome_screen.dart`
  - `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
- **Liên quan:** T014, T015, T017, T019, T020.
- **Source refs đã đọc:** `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`, `docs/01-product/02-hanh-trinh-ux.md`, `docs/01-product/03-he-thiet-ke.md`, `docs/02-engineering/04-hop-dong-api.md`, `AGENTS.md §1 & §3`.
- **Điểm tiếp tục:** Mở task `T036-dashboard-multisubject-schedule` (Dashboard & Cá nhân hóa nhiều môn, TKB ngày/tuần và quy tắc chọn câu ôn sáng).

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
