# Kế hoạch T038: Bảng dữ liệu PvP PostgreSQL & Dịch vụ Ghép giao hữu 1v1

## Điểm bắt đầu

- Nền combat T037 (`services/api/app/game/*`) đã được đưa vào Git và xác minh sạch ở T046 (`66bb734`, `0b5b4a3`).
- `models.py`, `pvp_match_service.py`, `routes/v1.py` đã có bản đầu nhưng thiếu migration Alembic (làm FAIL `test_alembic_upgrade_empty_db_and_schema_parity`), thiếu kiểm định rubric/revision/quyền/chương trình, thiếu idempotency khi retry sau chuyển vòng và có nguy cơ kẹt/rò rỉ tài nguyên trong `test_pvp_matchmaking.py`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tái hiện & chẩn đoán lỗi kẹt/chậm `test_pvp_matchmaking.py` và lỗi schema parity; ghi root cause vào `worklog.md` | Có bằng chứng tái hiện + nguyên nhân gốc rõ ràng | [x] |
| 2 | Cập nhật `models.py` (`Match.mode`, `MatchRound.rubric_revision`), `backup.py`, tạo migration `0003_add_pvp_match_tables.py` với đủ unique/FK/indexes & `downgrade()` | `alembic upgrade head` / `downgrade` / `compare_metadata == []` PASS | [x] |
| 3 | Sửa `verify_token.py` (timeout JWKS), `schemas.py` (`extra='forbid'` cho PvP), `pvp_match_service.py` (import `json`, lọc câu published/approved_bank/approved_by/rubric/revision/curriculum/rights, bỏ auto-correct khi thiếu spec, khóa row PG `with_for_update()`, idempotency trước state check, xử lý `uncertain`→`void`, không lộ rubric) | Toàn bộ AC-02..AC-07 đạt trên code thật | [x] |
| 4 | Viết lại & mở rộng `test_pvp_matchmaking.py` và `test_migrations_and_data_invariants.py` (dùng `with TestClient(app)`, dispose engine sạch, test A/B/C, queue/cancel, curriculum/rubric/approved_by, extra field 422, duplicate submit/action sau settle, reconnect, uncertain/void, unique/FK & test live PostgreSQL) | Toàn bộ 49 test backend (gồm 2 test live PostgreSQL 16) PASS, 0 skipped | [x] |
| 5 | Cập nhật `docs/02-engineering/03-du-lieu-sql.md` và `docs/02-engineering/04-hop-dong-api.md` đồng bộ với migration `0003` và route `/v1/pvp/*` | `check_docs_links.py` & `check_task_records.py` PASS | [x] |
| 6 | Rà diff, stage đúng file T038, commit, push và xác minh `origin/main` sau khi xác minh live PostgreSQL 16 | Trạng thái `done`, khớp SHA `origin/main` | [x] |

## Rủi ro và đường lui

- **Rủi ro thiếu PostgreSQL daemon local:** Docker Desktop trên máy Windows đang dừng (`docker-desktop Stopped`, cổng 5432 đóng), nên giữ trạng thái `verifying` (không gắn `done`), chạy kiểm chứng thực tế trên PostgreSQL 16 qua CI job `backend-api-postgres` hoặc khi bật Docker Desktop local.
- **Rủi ro migration làm gãy bảng cũ:** Đã kiểm chứng upgrade `0001 -> 0002 -> 0003` trên DB có sẵn dữ liệu user/alarm/xp rồi downgrade về `0002` và `base` mà dữ liệu cũ vẫn nguyên vẹn.
