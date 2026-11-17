# Bàn giao nhiệm vụ T038

- **Trạng thái cuối:** `verifying` (chưa gắn `done` vì 2 test trên PostgreSQL 16 thật `TC-09` bị skip trên máy local do Docker Desktop tắt).
- **Đã làm:**
  - Chẩn đoán & khắc phục triệt để nguyên nhân chậm/kẹt/rò rỉ trong `test_pvp_matchmaking.py` và `verify_token.py` (dùng `with TestClient(app)`, đóng/dispose engine sạch, khởi tạo DB qua Alembic `head`, truyền tường minh `local_dev_bearer_uid_fallback=True` + `firebase_project_id=''`, đặt `timeout=5` cho `PyJWKClient`).
  - Bổ sung `Match.mode` (`duel_1v1`) và `MatchRound.rubric_revision` vào `models.py`, cập nhật `backup.py`, tạo migration Alembic `services/api/alembic/versions/0003_add_pvp_match_tables.py` (7 bảng PvP, đủ unique/FK/indexes và `downgrade()` sạch, `compare_metadata == []`).
  - Hardening `pvp_match_service.py` & `schemas.py`: sửa thiếu `import json`, bỏ lỗi auto-correct khi thiếu `accepted_answers`, lọc chặt ngân hàng câu (`status='published'`, `source_type='approved_bank'`, `approved_by`, `revision >= 1`, `rubric_revision >= 1`, `rubric_json` hợp lệ, khớp `curriculum` & `rights_status`), khóa hàng `Match` (`with_for_update()` trên PostgreSQL), kiểm tra idempotency trước khi kiểm tra state chuyển vòng (retry submit/action sau settle không double-settle), chặn payload giả mạo điểm từ client (`extra='forbid'` → 422), xử lý `uncertain` → `void` không đổi HP/armor/qi, không lộ rubric/đáp án trước reveal.
  - Cập nhật `docs/02-engineering/03-du-lieu-sql.md` và `docs/02-engineering/04-hop-dong-api.md` đồng bộ với migration `0003` và 6 route giao hữu `/v1/pvp/*`.
- **File/code/docs thay đổi:**
  - `services/api/alembic/versions/0003_add_pvp_match_tables.py` (mới)
  - `services/api/app/db/models.py`
  - `services/api/app/db/backup.py`
  - `services/api/app/auth/verify_token.py`
  - `services/api/app/schemas.py`
  - `services/api/app/services/pvp_match_service.py`
  - `services/api/tests/test_pvp_matchmaking.py` (mới vào Git, viết lại sạch)
  - `services/api/tests/test_migrations_and_data_invariants.py`
  - `docs/02-engineering/03-du-lieu-sql.md`
  - `docs/02-engineering/04-hop-dong-api.md`
  - `tasks/T038-pvp-database-and-matchmaking/*`
- **Test đã chạy:** Xem chi tiết trong `tasks/T038-pvp-database-and-matchmaking/tests.md` (`47 passed, 2 skipped in 15.73s` gồm 6/6 ca SQLite PvP, 4/4 ca migration/unique/FK/rollback/backup SQLite + DDL PostgreSQL, 9/9 combat engine, 16/16 API v1, 9/9 answer normalizer, 3/3 timetable OCR; `check_docs_links.py` & `check_task_records.py` PASS).
- **Test chưa chạy/giới hạn:** `TC-09` (`test_live_postgresql_migration_and_health_when_configured` và `test_pvp_live_postgresql_two_accounts_when_configured`) bị skip trên máy local vì Docker Desktop / WSL2 `docker-desktop` đang `Stopped` và cổng `127.0.0.1:5432` đóng.
- **Rủi ro còn lại:** Chưa xác minh trực tiếp thời gian chạy `with_for_update()` và migration `0002 -> 0003 -> 0002` trên tiến trình PostgreSQL 16 sống tại máy local (đã cấu hình đầy đủ để chạy tự động trên GitHub Actions job `backend-api-postgres` khi push).
- **Điểm tiếp tục chính xác:**
  1. Bật Docker Desktop và chạy `docker compose -f services/api/docker-compose.yml up -d postgres` (hoặc kiểm tra kết quả GitHub Actions job `backend-api-postgres` sau commit T038).
  2. Chạy `POSTGRES_TEST_URL=postgresql+psycopg://mindclock:mindclock_local_dev@127.0.0.1:5432/mindclock services/api/.venv/Scripts/python.exe -m pytest services/api/tests/test_migrations_and_data_invariants.py services/api/tests/test_pvp_matchmaking.py -vv`.
  3. Khi `TC-09` PASS trên PostgreSQL 16 thật, cập nhật kết quả vào `tasks/T038-pvp-database-and-matchmaking/tests.md`, đánh dấu bước 4 trong `plan.md`, và chuyển `README.md`/`handoff.md` sang `done`.
- **Git:** Sẽ cập nhật SHA commit T038 ngay sau khi push và xác minh trên `origin/main`.
- **Quyết định phải xin người phụ trách:** Không có; giữ ranked tắt (`rank_ledger` chưa thêm).
