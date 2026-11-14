# T014 — Luồng khách thiết lập học tập, cấu hình báo thức local & UI Flutter Android

- **Trạng thái:** `blocked`
- **Mục tiêu:** xây dựng dự án Flutter Android khởi đầu (`app/`) cho luồng khách dùng thử không tài khoản: thiết lập lớp/nhiều môn/môn ưu tiên/mục tiêu (có `Để sau` và `Chỉ báo thức`), thời khóa biểu 7 ngày (ngày nghỉ, thêm/sửa/xóa môn), cấu hình báo thức local (giờ, ngày lặp, âm/rung, thường vs tự chọn thử thách giải thích rõ không Hoãn, kiểm tra môn chưa có câu duyệt), tính gợi ý giờ dậy kèm phép tính & bắt buộc xác nhận, lưu/khôi phục dữ liệu local khi mở lại app, interface `AlarmSchedulerService` (trả trạng thái `Đã lưu cấu hình` khi chưa nối OS, không giả `Đã sẵn sàng` hay đã cấp quyền), lược bỏ hoàn toàn Đấu trường.
- **Nguồn yêu cầu:** yêu cầu nhiệm vụ từ chủ dự án ngày 14/11/2026 (`docs/05, 24, 31, 32, 41`).
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `app/pubspec.yaml`, `app/lib/**`, `app/test/**`, `app/android/**` (tối thiểu cho Flutter Android), `tasks/T014-luong-khach-hoc-tap-bao-thuc/*`, và cập nhật ghi chú `docs/54` / `docs/48` nếu trạng thái repo thay đổi (hoặc ghi rõ trong `handoff.md`).
- **Liên quan:** mở tiếp từ backlog `FE-S01`, `FE-S02`, `FE-S03` trong `docs/54-kiem-ke-va-backlog-frontend.md` và bộ chuỗi/token trong `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`.
- **Source refs đã đọc:** `AGENTS.md`, `tasks/README.md`, `docs/05, 08, 13, 24, 27, 30, 31, 32, 41, 47, 48, 54, 55`, `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md`, `.agents/skills/flutter-custom-design-system/SKILL.md` (skill chính: `flutter-apply-architecture-best-practices`; skill bổ trợ: `flutter-custom-design-system`).
- **Điểm tiếp tục:** cài Flutter SDK + thêm `flutter/bin` vào `PATH`, chạy `flutter create . --platforms=android` (hoặc giữ `app/android/` + sinh wrapper thiếu), `flutter pub get`, `flutter analyze`, `flutter test`, rồi chạy kiểm thử thiết bị thật qua `adb`.

## Cổng trước coding

- [x] Đã đọc `AGENTS.md`, `tasks/README.md`, `docs/05, 24, 31, 32, 41, 47, 54, 55` và kiểm tra repo (`app/` chưa tồn tại).
- [x] Đã kiểm tra công cụ trên máy: có `Android Sdk\platform-tools\adb.exe` và `Android Studio`, nhưng **chưa có `flutter` / `dart` SDK** và chưa có thiết bị Android cắm qua `adb`. Đã ghi rõ giới hạn này để không gắn `done` giả.
- [x] `spec.md`, `plan.md`, `tests.md` đã điền đầy đủ trước khi tạo file code trong `app/`.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` được chứng minh bằng `flutter analyze` + `flutter test` + rà UI `320/360/390/600 dp` và chữ `100/150/200%`.
- [x] Các bước `plan.md` phản ánh đúng trạng thái thực.
- [ ] `tests.md` có kết quả chạy test thật (`flutter test`, `adb`) — hiện bị chặn do thiếu Flutter SDK.
- [x] Tài liệu `tasks/T014-*` đồng nhất, `check_task_records.py` đạt.
- [ ] `handoff.md` hoàn tất và đã backup commit/push lên `origin/main`.
