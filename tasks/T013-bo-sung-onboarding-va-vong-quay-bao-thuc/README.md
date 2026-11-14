# T013 — Bổ sung luồng Login/Onboarding AI, Vòng quay Ngủ–Dậy 24h và Âm thanh Android vào kiểm kê/backlog

- **Trạng thái:** `done`
- **Mục tiêu:** cập nhật kiểm kê màn hình, component (`SleepWakeDial`), backlog lát cắt dọc (AC ↔ test), ngôn từ/icon chuẩn và danh mục skill/plugin phù hợp cho yêu cầu mới của chủ dự án (luồng đăng ký/đăng nhập → trình độ/môn → tải TKB → chọn avatar → dashboard vòng quay ngủ–dậy 24h chuẩn quốc tế theo ảnh mẫu + thêm báo thức tùy chọn giờ + full-screen Android với âm thanh tùy chỉnh); chưa sửa code ứng dụng.
- **Nguồn yêu cầu:** tin nhắn người dùng và ảnh mẫu `media_1794620679858_7b86f075.jpg` ngày 14/11/2026 + lệnh `/find-skills`.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `docs/54-kiem-ke-va-backlog-frontend.md`, `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`, `tasks/T013-bo-sung-onboarding-va-vong-quay-bao-thuc/*`. Không sửa `demo/`, không tạo app code.
- **Liên quan:** mở rộng tiếp `T011` (`docs/54`) và `T012` (`docs/55`).
- **Source refs đã đọc:** `AGENTS.md`, `docs/04, 05, 13, 16, 23, 24, 27, 29, 30, 31, 32, 41, 42, 45, 47, 48, 52, 53, 54, 55`, `.agents/skills/find-skills/SKILL.md`, `.agents/skills/mindclock-android-native/SKILL.md`, `.agents/skills/flutter-custom-design-system/SKILL.md`, ảnh mẫu `media_1794620679858_7b86f075.jpg`. Skill chính: `requirements-writing`; skill bổ trợ: `find-skills`.
- **Điểm tiếp tục:** chốt 4 điểm còn mở (dùng `Email + Biệt danh` hay username cho Firebase Auth; file âm thanh chuông gửi vào `assets/audio/`; chọn `Lucide` vs `Material Symbols Rounded`; cài Flutter/Android SDK), rồi mở `T014` để bắt đầu code `FE-S01`.

## Cổng trước coding

- [x] Đã đọc `.agents/skills/find-skills/SKILL.md`, ảnh mẫu `media_1794620679858_7b86f075.jpg` và toàn bộ tài liệu liên quan.
- [x] Đã xác định các mâu thuẫn giữa yêu cầu mới với quy tắc MindClock (`Khách local` vs ép login; `tên` vs `Email` Firebase Auth; chẩn đoán giấc ngủ vs mục tiêu ngủ tự đặt; UI Apple Health vs MindClock tokens).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể trước khi cập nhật `docs/54` và `docs/55`.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt ở mức tài liệu kiểm kê & backlog.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh và kết quả thực.
- [x] `docs/54` và `docs/55` nhất quán, không vi phạm quy tắc sản phẩm MindClock.
- [x] `handoff.md` nêu giới hạn và điểm tiếp tục; đã push lên `origin/main`.
