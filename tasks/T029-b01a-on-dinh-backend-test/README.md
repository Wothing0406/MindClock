# T029 — B01a: Ổn định backend test và khóa route web WIP ở production

- **Trạng thái:** `done`
- **Mục tiêu:** Chẩn đoán và xử lý dứt điểm hiện tượng treo/chậm khi chạy `pytest` trong `services/api/`, xác nhận toàn bộ suite backend `/v1` chạy pass ổn định, và đảm bảo các route web WIP (`/demo`, `/product`) không được mount khi `app_env` là `production`/`staging` (có test kiểm chứng) mà không làm hỏng WIP T022/T023.
- **Nguồn yêu cầu:** Yêu cầu người dùng ngày 16/11/2026; `docs/00-start/05-goi-task-dau-tien.md` (B01a); `docs/00-start/02-lo-trinh.md` (R0/B01).
- **Chủ sở hữu/reviewer:** AI Coding Agent.
- **Phạm vi file dự kiến:** `services/api/app/main.py`, `services/api/app/db/base.py`, `services/api/tests/test_api_v1.py`, `docs/00-start/01-hien-trang.md`, `docs/03-quality/04-moi-truong-chay-thu.md`, `tasks/T029-b01a-on-dinh-backend-test/*`.
- **Liên quan:** Tiếp nối điểm dừng của `T024-production-rebaseline` và `T025-docs-production-system`; bảo vệ WIP của `T022` và `T023`.
- **Source refs đã đọc:** `AGENTS.md §1–4`, `docs/README.md`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/03-quy-trinh-vibe-code.md`, `docs/00-start/04-cau-truc-repo.md`, `docs/00-start/05-goi-task-dau-tien.md`, `docs/02-engineering/01-kien-truc.md`, `docs/03-quality/01-ke-hoach-kiem-thu.md`, `docs/03-quality/02-van-hanh-phat-hanh.md`, `docs/03-quality/03-truy-vet-yeu-cau.md`, `docs/03-quality/04-moi-truong-chay-thu.md`.
- **Điểm tiếp tục:** Chuyển sang `T030` (B01b — Flutter/Android build và test).

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
