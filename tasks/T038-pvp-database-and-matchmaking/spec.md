# Đặc tả T038: Bảng dữ liệu PvP PostgreSQL & Dịch vụ Ghép giao hữu 1v1

## Vấn đề và kết quả mong muốn

### Hiện trạng trước khi hoàn thiện T038
- Model SQLAlchemy (`models.py`), `PvpMatchService` (`pvp_match_service.py`) và 6 route `/v1/pvp/*` (`routes/v1.py`) đã có mã cơ bản, nhưng:
  1. **Chưa có Alembic migration cho 7 bảng PvP** -> `test_alembic_upgrade_empty_db_and_schema_parity` FAIL (`compare_metadata != []`), chưa kiểm chứng trên PostgreSQL thật (DB trống, nâng cấp từ `0002`, unique/FK, rollback).
  2. **Lỗi cấu hình/rò rỉ tài nguyên trong `test_pvp_matchmaking.py`**: tạo 2 SQLAlchemy engine song song trên cùng file SQLite không `dispose()`, dùng `TestClient(app)` không có `with` context manager (không chạy lifespan shutdown), không gán tường minh `local_dev_bearer_uid_fallback=True` & `firebase_project_id=''` khiến khi env tắt dev fallback sẽ gọi mạng JWKS (timeout 30s) hoặc trả 401.
  3. **Thiếu sót nghiệp vụ trong `pvp_match_service.py`**:
     - Thiếu `import json` (dòng 496).
     - Khi câu thiếu `accepted_answers`, dòng 505 gán `accepted_answers = [clean_answer]` (tự chấm đúng mọi đáp án!).
     - Chưa lọc đủ điều kiện ngân hàng câu PvP (`source_type='approved_bank'`, `approved_by`, `revision >= 1`, `rubric_revision >= 1`, `rubric_json` không rỗng, `answer_spec_json.accepted` không rỗng, khớp `curriculum` & `rights_status`).
     - `Match` chưa có cột `mode` (`duel_1v1`), `MatchRound` chưa đóng băng `rubric_revision`.
     - Chưa kiểm tra idempotency (`existing_sub`, `existing_act`) trước khi kiểm tra state chuyển vòng -> retry sau khi round settle/mở action window trả lỗi 400 thay vì idempotent replay; chưa khóa hàng `Match` (`with_for_update()` trên PostgreSQL) khi settle.
     - `get_match_snapshot` chưa reveal `grade_status` khi `state == 'void'`, và chưa gửi `question_id` / `question_revision` / `rubric_revision` để client kiểm tra đồng nhất câu hỏi.
     - `PvpRoundSubmitRequest` / `PvpRoundActionRequest` chưa chặn tường minh các field có thẩm quyền giả từ client (`extra='forbid'`).

### Kết quả mong muốn
- Migration `0003_add_pvp_match_tables` đạt 100% parity với `Base.metadata` (`compare_metadata == []`), upgrade/downgrade an toàn trên PostgreSQL thật (DB trống & từ `0002_align_question_indexes`), cưỡng chế toàn bộ unique/FK constraints.
- Bộ test `test_pvp_matchmaking.py` và `test_migrations_and_data_invariants.py` chạy nhanh, ổn định, không kẹt, bao phủ toàn bộ yêu cầu GAME-01–05/07 và DATA-05.

## Phạm vi

- **Trong phạm vi:** Alembic migration `0003_add_pvp_match_tables.py`, SQLAlchemy models PvP (`models.py`), `backup.py`, `verify_token.py` (timeout JWKS), `schemas.py` (`extra='forbid'` cho PvP requests), `pvp_match_service.py`, `routes/v1.py`, `test_pvp_matchmaking.py`, `test_migrations_and_data_invariants.py`, cập nhật `docs/02-engineering/03-du-lieu-sql.md` và `docs/02-engineering/04-hop-dong-api.md`.
- **Ngoài phạm vi:** Ranked/RP/leaderboard (`rank_ledger`), chế độ đội 2v2 (G3), Flutter UI (G2 Flutter slice), art/asset (G4), web WIP.
- **Dữ liệu/role/quyền liên quan:** Mọi endpoint `/v1/pvp/*` xác thực Bearer token lấy owner từ token; người ngoài trận bị chặn 403 trên mọi thao tác đọc/nộp/chọn chiêu; không lộ `rubric_json`/`answer_spec_json` trước reveal.
- **Tài liệu chuẩn:** `docs/04-game/01-pvp-gdd.md §1–§4`, `docs/02-engineering/03-du-lieu-sql.md §1, §4, §5`, `docs/02-engineering/04-hop-dong-api.md §1, §2, §4`, `docs/03-quality/05-ca-nghiem-thu.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Chạy `alembic upgrade head` trên DB trống và từ `0002_align_question_indexes`, rồi `downgrade` trên PostgreSQL thật & SQLite | Tạo đủ 7 bảng PvP khớp `Base.metadata` (`compare_metadata == []`), giữ nguyên dữ liệu cũ khi upgrade/downgrade, cưỡng chế unique & FK (`uq_match_player`, `uq_match_round_no`, `uq_round_submission`, `uq_round_action`, `uq_match_event_sequence`, `match_queue.user_id` unique, `match_rounds.question_id RESTRICT`) | TC-01, TC-02, TC-09 |
| AC-02 | Ngân hàng câu không đủ 6 câu hợp lệ (draft, thiếu `approved_by`, thiếu rubric/accepted, sai khối hoặc sai chương trình `curriculum`, hoặc `rights_status='revoked'`) | `POST /v1/pvp/matchmake` từ chối với `400 INSUFFICIENT_APPROVED_QUESTIONS`, không ghép trận và không gọi Gemini sinh câu | TC-03 |
| AC-03 | Hai tài khoản A/B cùng môn/khối/chương trình vào hàng đợi; khác khối/chương trình không ghép; hủy hàng đợi | A vào hàng đợi nhận `waiting`; hủy nhận `cancelled: true` (lần 2 `false`); A và B cùng môn/khối/chương trình ghép thành công (`in_progress`, `mode='duel_1v1'`, `rule_version='solo-three-v0.1'`), nhận cùng `question_id`, `question_revision`, `rubric_revision`, `prompt`, `deadline_at`, không lộ `rubric_json`/`answer_spec_json` | TC-04, TC-05 |
| AC-04 | Người ngoài trận (User C) gọi snapshot, events, submit hoặc action của trận A & B | Trả `403 FORBIDDEN`, không lộ dữ liệu và không làm đổi trạng thái trận | TC-04 |
| AC-05 | Nộp bài không có bước giải (`reasoningText` rỗng/<3 ký tự) hoặc client gửi thêm field có thẩm quyền (`hp`, `damage`, `grade`, `winner`) | Thiếu bước giải → `incorrect` (không kích hoạt chiêu); gửi field có thẩm quyền giả → bị từ chối `422` (`extra='forbid'`); server luôn tự tính HP/armor/qi/result | TC-06 |
| AC-06 | Submit/action kép (kể cả retry sau khi round đã chuyển state/settle), reconnect đọc snapshot + `events?after_sequence=N` | Retry trả `is_duplicate: true`, round chỉ settle đúng 1 lần (`round_settled` xuất hiện đúng 1 lần trong `match_events`), HP/armor/qi không bị trừ nhân đôi, reconnect nhận đủ event tuần tự không mất/lặp | TC-07 |
| AC-07 | Một bên gặp `uncertain` (rubric/revision câu bị đổi giữa round hoặc câu thiếu `answer_spec.accepted`) | Round chuyển sang `state='void'`, phát event `round_voided`, HP/armor/qi giữ nguyên, mọi lệnh `action` trên round `void` bị từ chối `400 ACTION_WINDOW_CLOSED` | TC-08 |
| AC-08 | Cập nhật docs chuẩn & kiểm soát Git sạch | `03-du-lieu-sql.md` và `04-hop-dong-api.md` đồng bộ đúng schema/routes thực tế; `check_docs_links.py` & `check_task_records.py` PASS; stage đúng file T038 | TC-10 |

## Hợp đồng và trường hợp biên

- Các schema request PvP (`PvpMatchmakeRequest`, `PvpRoundSubmitRequest`, `PvpRoundActionRequest`) dùng `model_config = ConfigDict(populate_by_name=True, extra='forbid')` để chặn tuyệt đối mọi payload cố tình nhồi `hp`, `damage`, `grade`, `rp`, `winner`.
- `MatchEvent` loại `round_settled` ghi đầy đủ `rule_version`, `round_no`, `is_secret_round`, `delta_a`, `delta_b`, `match_finished`, `winner_user_id`, `finish_reason` để tương thích 100% với `RoundSettleSnapshot.fromJson` trên Flutter Dart.
- Mọi kiểm thử đều dùng `with TestClient(app) as client:` và đóng/dispose engine sạch sẽ, truyền tường minh `local_dev_bearer_uid_fallback=True` và `firebase_project_id=''` để không bao giờ kẹt mạng JWKS hay khóa file SQLite.

## Quyết định/mâu thuẫn

- `docs/02-engineering/03-du-lieu-sql.md §1` ghi "Bảng hiện có không có PvP/rank" và `docs/02-engineering/04-hop-dong-api.md §4` đặt PvP ở bảng B; khi hoàn thiện T038 cần cập nhật rõ 7 bảng PvP giao hữu 1v1 (`0003_add_pvp_match_tables`, không có `rank_ledger`) và 6 route giao hữu `/v1/pvp/*` ở trạng thái dev/contract (ranked vẫn tắt).
- Chưa thêm `rank_ledger` vì giao hữu 1v1 không đổi RP; `rank_ledger` chỉ thêm khi mở ranked sau cổng playtest.
