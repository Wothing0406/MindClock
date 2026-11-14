# Kế hoạch thực hiện T016

## Điểm bắt đầu

- Chưa có mã backend trong repo; mới có thiết kế ở `docs/07`, `docs/18`, `docs/25`, `docs/28`, `docs/39` và client Flutter `T017` chờ kết nối.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Khởi tạo `services/api/` (FastAPI, Pydantic v2, SQLAlchemy 2.x async/sync, Alembic, Docker/Compose PostgreSQL local test) | `GET /v1/health` trả `200`, `pytest` chạy được | [ ] |
| 2 | Viết SQLAlchemy models + Alembic migration đầu tiên theo `docs/28 §4` & `docs/39 §4` | `alembic upgrade head` & `downgrade` chạy sạch trên PostgreSQL | [ ] |
| 3 | Viết Auth dependency verify Firebase ID token (`app/auth/verify_token.py`), owner guard mặc định deny-all và error envelope chuẩn `docs/07 §1` | Token thiếu/hết hạn -> `401`, cross-account -> `403` | [ ] |
| 4 | Triển khai `/v1/me`, `/v1/alarms`, `/v1/timetable`, `/v1/alarms/wake-suggestions` cùng `Idempotency-Key` middleware/store và revision `409` | Pass unit + contract test `/v1/me`, `/v1/alarms`, `/v1/timetable` | [ ] |
| 5 | Triển khai `/v1/challenges/next`, `/v1/sessions`, `/events`, `/answers`, `/attempts` (multipart <= 5MB + magic bytes + xóa ảnh tạm), `/feedback`, `/progress/summary`, Gemini adapter (deadline < 15s) + validator + `xp_ledger` transaction | Pass test `G01–G08`, test đồng thời XP, A/B isolation, no-leak logs | [ ] |
| 6 | Kết nối thử thực tế với `app/` (`T017`) trên dev/staging và xác nhận pass end-to-end | Chuyển `T017` từ `blocked` sang `verifying`/`done` | [ ] |
