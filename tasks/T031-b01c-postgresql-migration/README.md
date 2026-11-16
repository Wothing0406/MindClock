# T031 — B01c: Đồng bộ Alembic migration, kiểm thử dữ liệu/transaction và diễn tập backup/restore

- **Trạng thái:** `verifying`
- **Mục tiêu:** Đồng bộ 100% schema Alembic với SQLAlchemy `Base.metadata` (bổ sung revision `0002_align_question_indexes`), kiểm chứng migration trên DB trống và DB đã có dữ liệu (`0001 -> 0002 -> downgrade -> upgrade`), biên dịch DDL dialect PostgreSQL, kiểm thử bất biến dữ liệu `DATA-01..08` (unique constraints, cascade delete, rollback giữa chừng), và diễn tập backup/restore dữ liệu có kiểm chứng.
- **Nguồn yêu cầu:** Yêu cầu người dùng ngày 16/11/2026; `docs/00-start/05-goi-task-dau-tien.md` (B01c); `docs/00-start/02-lo-trinh.md` (R0/B01); `docs/02-engineering/03-du-lieu-sql.md`.
- **Chủ sở hữu/reviewer:** AI Coding Agent.
- **Phạm vi file dự kiến:** `services/api/alembic/env.py`, `services/api/alembic/versions/0002_align_question_indexes.py`, `services/api/app/db/backup.py`, `services/api/tests/test_migrations_and_data_invariants.py`, `docs/00-start/01-hien-trang.md`, `docs/02-engineering/03-du-lieu-sql.md`, `tasks/T031-b01c-postgresql-migration/*`.
- **Liên quan:** Tiếp nối `T029-b01a-on-dinh-backend-test` và `T030-b01b-flutter-android-build`.
- **Source refs đã đọc:** `AGENTS.md §3, §4`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/05-goi-task-dau-tien.md`, `docs/02-engineering/03-du-lieu-sql.md`, `docs/03-quality/01-ke-hoach-kiem-thu.md`, `docs/03-quality/02-van-hanh-phat-hanh.md`.
- **Điểm tiếp tục:** Khi bật Docker Desktop (`docker compose up -d postgres`) hoặc chạy CI, đặt `POSTGRES_TEST_URL` và chạy lại `pytest -vv tests/test_migrations_and_data_invariants.py -k test_live_postgresql` để đóng cổng PostgreSQL live (`TC-05`).

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
