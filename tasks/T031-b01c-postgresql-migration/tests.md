# Kế hoạch và kết quả kiểm thử — T031 (B01c)

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Chạy `alembic upgrade head` trên DB trống, kiểm tra `compare_metadata` và biên dịch SQL sang dialect `postgresql` | `compare_metadata` trả `[]`; SQL PostgreSQL chứa đủ `CREATE TABLE`, `UNIQUE`, `FOREIGN KEY ... ON DELETE CASCADE` và `CREATE INDEX` | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_migrations_and_data_invariants.py -k test_alembic_upgrade_empty_db_and_schema_parity` | Pass (`0.28s`, 16/11/2026) |
| TC-02 | AC-02 | Nâng cấp `0001_initial_schema` có sẵn dữ liệu lên `head` (`0002`), sau đó `downgrade` về `0001` và `base` | Dữ liệu giữ nguyên sau khi lên `0002` và về `0001`; về `base` xóa sạch bảng | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_migrations_and_data_invariants.py -k test_alembic_upgrade_with_existing_data_and_downgrade` | Pass (`0.55s`, 16/11/2026) |
| TC-03 | AC-03 | Kiểm tra unique constraints (`DATA-02`) và rollback khi lỗi giữa transaction (`DATA-04`) | `IntegrityError` khi trùng khóa; transaction lỗi giữa chừng không để sót `Attempt` hay `XpLedger` | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_migrations_and_data_invariants.py -k test_unique_constraints_and_atomic_rollback` | Pass (`0.20s`, 16/11/2026) |
| TC-04 | AC-04 | Diễn tập backup DB có dữ liệu → tạo DB mới qua `alembic upgrade head` → restore từ snapshot và kiểm tra checksum (`DATA-06`) | Khôi phục đầy đủ dữ liệu 11 bảng, sai checksum bị từ chối | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_migrations_and_data_invariants.py -k test_backup_and_restore_rehearsal` | Pass (`0.44s`, 16/11/2026) |
| TC-05 | AC-05 | Chạy migration và `/v1/health` trên PostgreSQL thật khi có `POSTGRES_TEST_URL` / Docker | Pass khi có PostgreSQL; skip có lý do rõ ràng khi Docker daemon tắt trên máy local | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_migrations_and_data_invariants.py -k test_live_postgresql` | Skipped trên local Windows do Docker Desktop daemon tắt (`open //./pipe/dockerDesktopLinuxEngine`); đã cấu hình chạy tự động trên GitHub Actions `postgres:16-alpine` (`.github/workflows/ci.yml`, 16/11/2026) |

## Cổng theo rủi ro

- Dữ liệu/SQL: `DATA-02`, `DATA-04`, `DATA-05`, `DATA-06` đã pass (`19 passed, 1 skipped in 7.65s`).
- Giới hạn môi trường: Theo `AGENTS.md §3` ("SQLite không thay PostgreSQL"), giữ trạng thái `T031` là `verifying` cho tới khi `TC-05` chạy trên instance PostgreSQL thật (Docker Desktop hoặc CI).
