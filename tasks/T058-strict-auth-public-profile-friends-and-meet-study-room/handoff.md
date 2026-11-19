# Bàn giao nhiệm vụ T058

- **Trạng thái cuối:** `in_progress`
- **Đã làm:** Hoàn thiện tài liệu đặc tả chuẩn & hồ sơ T058 trước khi viết code.
- **File/code/docs thay đổi:** `docs/01-product/{04,07,08}*.md`, `docs/02-engineering/04-hop-dong-api.md`, `tasks/T058-*/*`.
- **Test đã chạy:** xem `tests.md` (chưa code).
- **Test chưa chạy/giới hạn:** Toàn bộ test triển khai của T058 sẽ chạy sau từng bước code.
- **Rủi ro còn lại:** Cần rà soát các widget test cũ có dùng đường tắt `guest-skip-later` / `guest-start-setup` và cập nhật chúng sang luồng đăng nhập/đăng ký hoặc tài khoản test hợp lệ.
- **Điểm tiếp tục chính xác:** Bước 1 trong `plan.md` — cập nhật `WelcomeScreen` & `AuthScreen`.
- **Git:** Nhánh `main`, chuẩn bị commit Docs-First backup trước khi code.
