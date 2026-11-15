# T024 — Chuyển repo sang hướng sản phẩm Android

- **Trạng thái:** `verifying`
- **Mục tiêu:** bỏ hai thư mục demo, giữ tài sản game có thể dùng lại, tổ chức repo theo app Android/API và chốt tài liệu production phản ánh đúng mã hiện có.
- **Nguồn yêu cầu:** người dùng ngày 15/11/2026.
- **Chủ sở hữu/reviewer:** Codex / chủ dự án.
- **Phạm vi:** `demo/`, `demo_video/`, `assets/`, các script asset, README, docs chỉ mục/kiến trúc/cấu trúc/roadmap, task này.
- **Liên quan:** T009 (web arena/art), T014–T021 (Flutter/API), T022–T023 (web local đang làm dở).
- **Source refs:** `docs/README.md`, `docs/06`, `docs/08`, `docs/28`, `docs/50`, `tasks/README.md`, `app/lib/app.dart`, `services/api/app/main.py`.
- **Điểm tiếp tục:** mã tái cấu trúc đã qua asset/docs/task QA. Kiểm lại API test đang treo ngay ở ca health trong môi trường hiện tại, rồi xác nhận Git/push; không sửa WIP T022/T023 trong task này.

## Cổng trước coding

- [x] Đã đọc docs/task/code liên quan và kiểm tra `git status`.
- [x] Đã xác định `demo/` và `demo_video/` là hai thư mục người dùng muốn bỏ; `demo/assets/game/` chứa art cần chuyển trước khi xóa.
- [x] Đã ghi spec, plan, tests trước khi sửa code/cấu trúc.

## Cổng kết thúc

- [x] AC-01–03 đạt; TC-04 ghi rõ API test hiện treo, không do file task này sửa.
- [x] Docs định tuyến sản phẩm về Flutter/API, web nội bộ được ghi đúng trạng thái.
- [x] Handoff ghi trạng thái, rủi ro và điểm tiếp tục.
