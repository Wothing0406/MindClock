# Kế hoạch thực hiện T048

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật `app/lib/ui/features/guest_shell/views/welcome_screen.dart` thêm thẻ `Giải thích quyền` gọn rõ theo `ON-01` (không bật hộp thoại OS lúc mở app, tương thích `320dp` chữ `200%` và giữ nút điều hướng trong màn đầu `360x780`) | `guest_flow_widget_test.dart` và `study_focus_local_test.dart` không hồi quy | [x] |
| 2 | Cập nhật `app/lib/ui/features/guest_shell/views/auth_screen.dart` (thêm 2 ô xác nhận điều khoản v1 & độ tuổi THPT khi đăng ký, đổi nút Hiện/Ẩn sang `MindClockPressable`, đổi nút dự phòng thành `Chỉ dùng báo thức trên máy`, thay header `Row` sang `Wrap` sửa tràn 59px) và sửa lỗi cô lập tài khoản A/B (`ON-06`) trong `guest_workspace_repository.dart` + `guest_workspace_view_model.dart` | `dart analyze lib test` 0 lỗi, 0 overflow, 0 rò hồ sơ A→B | [x] |
| 3 | Tạo `app/test/auth_onboarding_flow_test.dart` kiểm `ON-01..ON-06` (giải thích quyền, validation form, lỗi `CONFIGURATION_NOT_FOUND` → fallback chuông local, happy path đăng ký → onboarding → Hôm nay, đổi tài khoản A/B cô lập hồ sơ & giữ chuông local) | 100% ca test mới + toàn bộ 65 test Flutter PASS | [x] |
| 4 | Cập nhật `docs/00-start/01-hien-trang.md` với bảng hiện trạng xác thực ngày 2026-11-18 | `check_docs_links.py` PASS | [x] |
| 5 | Chạy trọn bộ `flutter test --no-pub`, `dart analyze lib test`, `check_docs_links.py`, `check_task_records.py`; stage đúng file T048, commit, xác minh trên **detached clean Git worktree** (không có untracked files), rồi push `origin/main` | Clean worktree `dart analyze` 0 lỗi + full `flutter test` PASS; SHA khớp `origin/main` | [x] |
