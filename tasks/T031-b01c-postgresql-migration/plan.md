# Kế hoạch thực hiện — T031 (B01c)

## Điểm bắt đầu

- Code hiện tại: `services/api/alembic/env.py`, `services/api/alembic/versions/0001_initial_schema.py`, `services/api/app/db/models.py`.
- Hiện trạng: `0001_initial_schema.py` thiếu 5 index đơn trên `questions`; `alembic/env.py` luôn ghi đè `sqlalchemy.url` bằng `get_settings().database_url`; chưa có tiện ích diễn tập backup/restore và bộ test migration/transaction.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật `services/api/alembic/env.py` ưu tiên URL truyền vào `Config` nếu khác mặc định và thêm `0002_align_question_indexes.py` | `alembic upgrade head` khớp 100% `Base.metadata` | [x] |
| 2 | Xây dựng `services/api/app/db/backup.py` hỗ trợ xuất/nhập snapshot JSON có SHA-256 checksum theo thứ tự FK cho 11 bảng | Backup và restore idempotent, kiểm tra được bằng test | [x] |
| 3 | Viết `services/api/tests/test_migrations_and_data_invariants.py` kiểm tra AC-01..AC-05 (`DATA-02`, `DATA-04`, `DATA-05`, `DATA-06`, PostgreSQL DDL) | Toàn bộ `pytest` chạy pass | [x] |
| 4 | Cập nhật `docs/00-start/01-hien-trang.md`, `docs/02-engineering/03-du-lieu-sql.md`, chạy `check_docs_links.py` + `check_task_records.py` và điền `handoff.md` | Hồ sơ và tài liệu khớp thực tế | [x] |

## Rủi ro và đường lui

- **Rủi ro:** `alembic/env.py` gọi `fileConfig(config.config_file_name)` có thể tắt logger của pytest khi chạy programmatic migration trong test.
- **Đường lui:** Truyền `disable_existing_loggers=False` vào `fileConfig` trong `services/api/alembic/env.py`.
