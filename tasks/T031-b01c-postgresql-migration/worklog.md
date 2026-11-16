# Nhật ký thực hiện và vòng sửa — T031 (B01c)

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 2026-11-16 | Soát `0001_initial_schema.py` và `models.py`; kiểm tra `docker info` trên máy Windows | `0001_initial_schema.py` thiếu 5 index trên bảng `questions`; Docker Desktop daemon trên máy host hiện đang tắt | Tạo `0002_align_question_indexes.py`, cập nhật `alembic/env.py`, tạo `app/db/backup.py` và `tests/test_migrations_and_data_invariants.py` | `19 passed, 1 skipped in 7.65s` | Đạt AC-01..AC-04; giữ `verifying` cho TC-05 (cần Docker/PostgreSQL daemon) |
