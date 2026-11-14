# T012 — Chốt ngôn từ, thiết kế và quy chuẩn icon frontend

- **Trạng thái:** `done` (tài liệu chuẩn hóa ngôn từ, thiết kế và icon; chưa sửa code)
- **Mục tiêu:** chuẩn hóa và chốt một nguồn tài liệu duy nhất về ngôn từ (`vi-VN`), bộ chuỗi UI/trạng thái/lỗi, danh sách từ cấm, design tokens, quy tắc accessibility và bộ icon vector cho Flutter frontend trước khi mở task coding `FE-S01`.
- **Nguồn yêu cầu:** yêu cầu người dùng ngày 14/11/2026: *"chốt những vấn đề ngôn từ cho frontend trước giúp tôi, đọc thiết kế và quy chuẩn ngôn ngữ và icon"*.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`, `docs/13-he-thiet-ke-ui.md`, `docs/54-kiem-ke-va-backlog-frontend.md`, `docs/README.md`, `tasks/T012-chot-ngon-tu-thiet-ke-icon-frontend/*`. Chưa sửa code ứng dụng.
- **Liên quan:** giải quyết các mâu thuẫn #2, #3, #5, #9 đã nêu ở `docs/54` (`T011`).
- **Source refs đã đọc:** `docs/04`, `docs/05`, `docs/13`, `docs/23`, `docs/27`, `docs/30`, `docs/31`, `docs/32`, `docs/39`, `docs/41`, `docs/45`, `docs/46`, `docs/51`, `docs/52`, `docs/53`, `docs/54`, `demo/index.html`, `demo/arena.html`. Skill chính: `requirements-writing`.
- **Điểm tiếp tục:** mở `T013` cho lát cắt `FE-S01` (khung app Flutter + `MindClockTheme` + `AppStrings` + 4 tab ẩn Đấu trường theo cohort flag) sau khi cài Flutter SDK/Android SDK và xác nhận licence font `Be Vietnam Pro` + gói icon (Lucide hoặc Material Symbols Rounded).

## Cổng trước coding

- [x] Đã đọc toàn bộ tài liệu thiết kế, ngôn ngữ, icon và bản kiểm kê `docs/54`.
- [x] Đã xác định các điểm mâu thuẫn cần chốt (`Mở câu hỏi` vs `Bắt đầu`, `Dừng khẩn cấp` vs `Tắt khẩn cấp`/`Tắt chuông`, `Chụp nháp` vs `Chụp bài`, `docs/13` trỏ `docs/37`, `44 px` vs `48 dp`, bộ icon & licence font).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể trước khi viết `docs/55`.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt ở mức tài liệu chuẩn hóa.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh và kết quả kiểm tra thực.
- [x] `docs/README.md`, `docs/13`, `docs/54`, `docs/55` nhất quán.
- [x] `handoff.md` nêu cách kiểm tra, giới hạn và điểm tiếp tục cụ thể; đã push lên `origin/main`.
