# T016 — Backend FastAPI & PostgreSQL cho luồng cá nhân (`/v1`)

- **Trạng thái:** `planned`
- **Mục tiêu:** xây dựng dịch vụ FastAPI + PostgreSQL + Alembic cho toàn bộ luồng cá nhân theo đúng hợp đồng [docs/07](../../docs/07-hop-dong-api-va-ai.md) và [docs/28](../../docs/28-backend-sql.md) để app Flutter (`T017`) kết nối thật, thay thế hoàn toàn fixture local.
- **Nguồn yêu cầu:** kiểm tra repo ngày 14/11/2026 xác nhận chưa có mã backend (`services/api/` chưa tồn tại); mở task backend riêng theo hợp đồng chuẩn `docs/06, 07, 17, 18, 24, 25, 28, 39`.
- **Chủ sở hữu/reviewer:** backend agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `services/api/app/**`, `services/api/alembic/**`, `services/api/tests/**`, `services/api/pyproject.toml`.
- **Liên quan:** `T017` (client Flutter luồng cá nhân) phụ thuộc trực tiếp vào task này để xác minh end-to-end trên server thật; xem thêm [T021](../T021-backend-fastapi-db-gemini38-live/README.md) đã dựng mã nguồn `services/api/` (SQLite + Docker Compose Postgres 16 + Gemini 3.8/Live) nhưng còn chờ chạy kiểm chứng thực tế trên PostgreSQL container.
- **Source refs:** `docs/06 §§1–5`, `docs/07 §§1–8`, `docs/17 §§1–6`, `docs/18 §§1–5`, `docs/24 §§1–4`, `docs/25 §§1–5`, `docs/28 §§1–7`, `docs/39 §§1–6`. Skill gợi ý: `api-design-principles`.
- **Điểm tiếp tục:** khởi tạo `services/api/` với FastAPI, SQLAlchemy 2.x, Alembic và PostgreSQL migration đầu tiên, sau đó viết contract tests trước khi nối Gemini server-side.

## Cổng trước coding

- [x] Đã kiểm tra repo xác nhận chưa có `services/api/` và đối chiếu đầy đủ hợp đồng `/v1` ở `docs/07`, `docs/28`, `docs/39`.
- [ ] Chốt môi trường hosting PostgreSQL, Firebase Auth project (`FIREBASE_PROJECT_ID`) và Secret Manager cho Gemini key (tuyệt đối không dùng Firestore nghiệp vụ, không dùng free tier cho ảnh học sinh thật nếu chưa đánh giá consent).

## Cổng kết thúc

- [ ] Migration Alembic chạy sạch trên PostgreSQL trống (`upgrade`/`downgrade`) và test transaction/unique thật trên PostgreSQL (SQLite không thay cho test concurrency `xp_ledger`).
- [ ] Pass toàn bộ contract tests: token A/B (`401`/`403`), `Idempotency-Key` cùng payload trả lại kết quả & khác payload trả `409`, không lộ `answerSpec`/`rubric` trước reveal, `uncertain` không tăng lượt sai, xóa ảnh tạm kể cả nhánh lỗi, `DELETE /v1/me` idempotent `202`.
