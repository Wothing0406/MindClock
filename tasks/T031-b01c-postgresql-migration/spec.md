# Đặc tả nhiệm vụ — T031 (B01c: PostgreSQL & Alembic migration, bất biến SQL và backup/restore)

## Vấn đề và kết quả mong muốn

Theo `docs/00-start/05-goi-task-dau-tien.md` (B01c) và `docs/02-engineering/03-du-lieu-sql.md §§2, 4, 5`:
1. Bản migration `0001_initial_schema.py` hiện đang thiếu 5 chỉ mục đơn lẻ trên bảng `questions` (`ix_questions_subject_code`, `ix_questions_grade_band`, `ix_questions_topic_id`, `ix_questions_status`, `ix_questions_source_type`) so với định nghĩa trong `services/api/app/db/models.py`.
2. Chưa có test tự động kiểm chứng `alembic upgrade head` từ DB trống, nâng cấp từ revision cũ (`0001_initial_schema -> head`) khi DB đã có dữ liệu thật mà không mất dữ liệu, `alembic downgrade` về revision trước và về `base`, kiểm tra khớp schema bằng `alembic.autogenerate.compare_metadata`, cũng như biên dịch DDL sang dialect `postgresql`.
3. Chưa có test kiểm chứng trực tiếp các bất biến SQL (`DATA-02` unique constraints, `DATA-04` rollback khi lỗi giữa transaction, `DATA-06` cascade delete & diễn tập backup/restore, `DATA-08` câu `draft` không cấp XP).

## Phạm vi

- **Trong phạm vi:**
  - Tạo revision Alembic `0002_align_question_indexes.py` bổ sung 5 index của `questions` để `compare_metadata` trả về `0` chênh lệch.
  - Tạo tiện ích backup/restore dữ liệu chuẩn JSON có kiểm tra toàn vẹn (`services/api/app/db/backup.py`) phục vụ diễn tập sao lưu/phục hồi trước migration (`docs/02-engineering/03-du-lieu-sql.md §4`, `docs/03-quality/02-van-hanh-phat-hanh.md §3.5`).
  - Viết bộ kiểm thử `services/api/tests/test_migrations_and_data_invariants.py` phủ `DATA-02`, `DATA-04`, `DATA-05`, `DATA-06`, `DATA-08` và hỗ trợ chạy trực tiếp trên PostgreSQL khi có biến `POSTGRES_TEST_URL`.
  - Kiểm tra trạng thái Docker Desktop / PostgreSQL runtime trên máy hiện tại và ghi nhận trung thực kết quả.
- **Ngoài phạm vi:**
  - Tạo trước các bảng trống cho PvP/ranked (`rank_ledger`) hoặc social room khi feature chưa mở.
- **Dữ liệu/role/quyền liên quan:**
  - Không lưu ảnh bài làm hoặc mật khẩu trong DB hay bản backup; `Cascade Delete` xóa sạch dữ liệu phụ thuộc khi xóa `User`.
- **Tài liệu chuẩn:**
  - `AGENTS.md §3, §4`
  - `docs/00-start/02-lo-trinh.md` (R0/B01)
  - `docs/00-start/05-goi-task-dau-tien.md` (B01c)
  - `docs/02-engineering/03-du-lieu-sql.md §§1–5`

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi chạy `alembic upgrade head` trên DB trống và so sánh với `Base.metadata` | Tạo đủ 11 bảng, khóa ngoại, unique constraint và index; `compare_metadata` trả danh sách rỗng `[]`; biên dịch offline sang dialect `postgresql` thành công | TC-01 |
| AC-02 | Khi DB đang ở revision `0001_initial_schema` và có dữ liệu (`users`, `alarms`, `questions`, `alarm_sessions`, `attempts`, `xp_ledger`), chạy `alembic upgrade head` rồi `downgrade 0001_initial_schema` | Dữ liệu hiện có được giữ nguyên 100%, không lỗi khóa ngoại hay mất bản ghi | TC-02 |
| AC-03 | Khi vi phạm unique constraint (`uq_alarm_session_local`, `uq_attempt_client`, `uq_xp_ledger_idempotent`, `uq_idempotency_user_route_key`) hoặc xảy ra lỗi giữa transaction chấm bài | Database ném `IntegrityError` và rollback toàn bộ transaction, không ghi nửa vời `Attempt` hoặc `XpLedger` | TC-03 |
| AC-04 | Khi thực hiện diễn tập backup → xóa/hỏng DB → migration + restore | Bản backup khôi phục đúng số lượng và nội dung bản ghi của tất cả 11 bảng theo thứ tự khóa ngoại và có kiểm tra checksum SHA-256 | TC-04 |
| AC-05 | Khi chạy trên PostgreSQL thật (`POSTGRES_TEST_URL` hoặc Docker Compose) | Nếu có PostgreSQL đang chạy thì chạy toàn bộ migration + `GET /v1/health` (`dbDialect=postgresql`); nếu máy local tắt Docker daemon thì ghi nhận `verifying` cho cổng PostgreSQL live trên máy local (đã cấu hình CI service `postgres:16-alpine`) | TC-05 |

## Hợp đồng và trường hợp biên

- Giữ nguyên cấu trúc 11 bảng hiện hành, chỉ bổ sung index còn thiếu ở `0002_align_question_indexes.py`.
- Hỗ trợ truyền `sqlalchemy.url` trực tiếp qua `alembic.config.Config` trong `services/api/alembic/env.py` để test và script backup/restore không bị phụ thuộc cứng vào biến môi trường toàn cục.

## Quyết định/mâu thuẫn

- Trên máy Windows hiện tại, `docker info` báo `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified` và không có dịch vụ PostgreSQL local đang chạy. Theo đúng quy tắc trung thực của `AGENTS.md §3` ("SQLite không thay PostgreSQL"), chúng ta hoàn thiện toàn bộ migration, kiểm tra `compare_metadata`, kiểm tra PostgreSQL DDL compilation, kiểm tra upgrade/downgrade/backup/restore/transaction invariants trên SQLite VÀ giữ trạng thái cổng PostgreSQL live là `verifying` cho đến khi bật Docker Desktop hoặc chạy CI.
