# T038: Bảng dữ liệu PvP PostgreSQL & Dịch vụ Ghép giao hữu 1v1

- **Trạng thái:** `done`
- **Mục tiêu:**
  - Hoàn thiện schema & Alembic migration (`0003_add_pvp_match_tables`) cho 7 bảng PvP (`match_queue`, `matches`, `match_players`, `match_rounds`, `round_submissions`, `round_actions`, `match_events`) có kiểm chứng PostgreSQL thật (DB trống, nâng cấp từ `0002_align_question_indexes`, unique/FK, rollback/downgrade).
  - Tái hiện, xác định nguyên nhân gốc và sửa triệt để vấn đề kẹt/chậm khi chạy `pytest tests/test_pvp_matchmaking.py -vv -x`.
  - Siết kiểm định ngân hàng câu đã duyệt (`status='published'`, `source_type='approved_bank'`, `approved_by`, `revision >= 1`, `rubric_revision >= 1`, `rubric_json` hợp lệ, `answer_spec_json.accepted` không rỗng, khớp khối/chương trình/quyền).
  - Khóa bất biến server-authoritative: hai tài khoản A/B cùng câu/revision/rubric_revision/deadline, không lộ đáp án/rubric trước reveal, người ngoài trận 403, submit cần bước trình bày, idempotent submit/action không settle 2 lần, reconnect/snapshot theo sequence, `uncertain` → `void` không đổi HP/RP, client không thể tự gửi HP/damage/result.
- **Nguồn yêu cầu:** `docs/04-game/01-pvp-gdd.md §1–§4`, `docs/02-engineering/03-du-lieu-sql.md §1, §4, §5`, `docs/02-engineering/04-hop-dong-api.md §1, §2, §4`, `docs/03-quality/05-ca-nghiem-thu.md (GAME-01–05, GAME-07)`, `AGENTS.md §3–§4`.
- **Chủ sở hữu/reviewer:** Senior Backend Systems & Cloud DevOps Architect.
- **Phạm vi file dự kiến:**
  - `services/api/app/db/models.py`
  - `services/api/app/db/backup.py`
  - `services/api/alembic/versions/0003_add_pvp_match_tables.py`
  - `services/api/app/auth/verify_token.py`
  - `services/api/app/schemas.py`
  - `services/api/app/services/pvp_match_service.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_pvp_matchmaking.py`
  - `services/api/tests/test_migrations_and_data_invariants.py`
  - `docs/02-engineering/03-du-lieu-sql.md`
  - `docs/02-engineering/04-hop-dong-api.md`
  - `tasks/T038-pvp-database-and-matchmaking/*`
- **Liên quan:** Phụ thuộc nền combat T037 đã được đưa vào Git và xác minh sạch ở `T046-fix-t037-combat-git-tracking` (`66bb734`, `0b5b4a3`).
- **Source refs đã đọc:** `AGENTS.md §1–§4`, `docs/04-game/01-pvp-gdd.md §1–§6`, `docs/02-engineering/03-du-lieu-sql.md §1–§5`, `docs/02-engineering/04-hop-dong-api.md §1–§5`, `docs/03-quality/05-ca-nghiem-thu.md (GAME-01–07)`, `services/api/app/db/models.py`, `services/api/app/services/pvp_match_service.py`, `services/api/app/routes/v1.py`, `services/api/tests/test_pvp_matchmaking.py`.
- **Điểm tiếp tục:** Toàn bộ cổng SQL/API/migration/live PostgreSQL 16 (`TC-01..TC-10`) đã đạt (`49 passed, 0 skipped`). Bước kế tiếp cho PvP là G2 (kết nối Flutter Android với 6 route `/v1/pvp/*` và playtest 2 máy thật), nhưng theo lộ trình ưu tiên chốt cổng R2 (Auth/Onboarding thật) và R1–R5 trước khi mở giao hữu cho người dùng.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt 100% (bao gồm `TC-09` trên PostgreSQL 16 thật `postgres:16-alpine`).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả thực tế và môi trường.
- [x] Docs chuẩn (`03-du-lieu-sql.md`, `04-hop-dong-api.md`) được cập nhật đồng bộ.
- [x] `handoff.md` nêu cách kiểm tra, trạng thái Git và điểm tiếp tục chính xác.
