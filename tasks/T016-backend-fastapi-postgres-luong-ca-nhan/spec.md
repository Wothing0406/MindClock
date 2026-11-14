# Đặc tả T016 — Backend FastAPI & PostgreSQL luồng cá nhân

## 1. Bối cảnh & Dependency

- Kiểm tra thực tế repo MindClock ngày 14/11/2026 (`Get-ChildItem`, `git branch -a`) cho thấy chưa có thư mục `services/api/`, `backend/` hay migration SQL nào.
- Client Flutter (`T017`) chỉ bám đúng hợp đồng `/v1` trong `docs/07`; task `T016` chịu trách nhiệm triển khai backend thật để mở khóa kiểm thử end-to-end thật cho `T017`.

## 2. Nguồn tài liệu áp dụng

- `docs/06-kien-truc-va-du-lieu.md`, `docs/28-backend-sql.md`: FastAPI + SQLAlchemy 2.x + Alembic + PostgreSQL; Firebase Auth chỉ dùng verify ID token, ánh xạ `uid` -> `users.auth_subject`; không dùng Firestore.
- `docs/07-hop-dong-api-va-ai.md §§1–8`: danh sách endpoint `/v1`, header `Authorization: Bearer <Firebase ID token>`, header `Idempotency-Key` (UUID), mã lỗi `{"error":{"code","message","requestId","retryable"}}`, HTTP `400/401/403/404/409/413/415/429/502/503/504`.
- `docs/17-workflow-va-vong-doi-du-lieu.md`, `docs/18-huong-dan-tich-hop-api.md §§2–5`: deadline AI < 15 giây; không giữ DB transaction mở lúc chờ Gemini; xóa ảnh tạm ở `finally`; không log ảnh, token, lời giải.
- `docs/24-dang-ky-va-quan-ly-tai-khoan.md §§3–4`, `docs/25-bao-mat-va-du-lieu.md §§1–5`: `GET/PATCH/DELETE /v1/me`, `GET /v1/me/delete-status`, `POST /v1/me/export`, `GET /v1/me/exports/{id}`.
- `docs/39-bai-lam-co-trinh-bay-va-cham-cong-bang.md §§1–6`: câu trả lời + trình bày, validator kết hợp AI, 3 trạng thái `correct|incorrect|uncertain`, challenge mode ẩn `firstIssue`/`hint` ở lần sai 1–2 (`uncertain` không cộng lượt sai), `POST /v1/sessions/{id}/feedback` báo chấm sai.

## 3. Acceptance Criteria (AC)

| ID | Yêu cầu nghiệm thu | Nguồn |
| --- | --- | --- |
| `BE-AC-01` | Mọi endpoint (trừ `GET /v1/health`) xác minh Firebase ID token server-side, lấy `uid` từ token và ép owner-scope `user_id` từ DB; token sai/hết hạn trả `401`, truy cập chéo user A/B trả `403`. | `docs/07 §1`, `docs/18 §3`, `docs/25 §2` |
| `BE-AC-02` | Schema PostgreSQL qua Alembic gồm `users`, `alarms`, `timetable_slots`, `questions`, `alarm_sessions`, `attempts`, `xp_ledger`, `topic_progress`, `idempotency_records`, `consent_events`, `grading_decisions`, `grade_reviews`. | `docs/28 §4`, `docs/39 §4` |
| `BE-AC-03` | Đầy đủ endpoint cá nhân: `/v1/health`, `/v1/me` (`GET/PATCH/DELETE`), `/v1/me/delete-status`, `/v1/me/export`, `/v1/me/exports/{id}`, `/v1/alarms`, `/v1/timetable`, `/v1/alarms/wake-suggestions`, `/v1/challenges/next`, `/v1/sessions`, `/v1/sessions/{id}/events`, `/v1/sessions/{id}/answers`, `/v1/sessions/{id}/attempts`, `/v1/sessions/{id}/feedback`, `/v1/progress/summary`. | `docs/07 §2` |
| `BE-AC-04` | `GET /v1/challenges/next` không lộ `answer_spec_json`/`rubric_json`; chỉ chọn câu `status=published`. | `docs/07 §2,§4`, `docs/39 §4` |
| `BE-AC-05` | Mọi `POST` tạo phiên/event/nộp bài/xóa/export bắt buộc `Idempotency-Key` UUID; cùng key + cùng payload trả kết quả cũ; cùng key + payload khác trả `409 IDEMPOTENCY_CONFLICT`; `xp_ledger` có unique constraint chống cấp XP trùng kể cả khi gọi đồng thời. | `docs/07 §1`, `docs/28 §4,§6` |
| `BE-AC-06` | `POST /v1/sessions/{id}/attempts` (multipart <= 5MB, kiểm MIME + magic bytes) và `/answers` chạy Gemini ngoài transaction, qua validator Toán/đáp án xác định, timeout < 15s trả `uncertain`, xóa ảnh tạm trong `finally`, không ghi ảnh/token/lời giải vào log. | `docs/07 §5,§7`, `docs/18 §3`, `docs/25 §2` |
| `BE-AC-07` | Chế độ thử thách ẩn `firstIssue`/`hint` trước lần `incorrect` thứ 3; `uncertain` không tăng lượt sai và không trừ XP; `+2` `complete_ungraded` chỉ cấp khi `attempts`/`events` hợp lệ đã commit server. | `docs/07 §3,§6,§8`, `docs/31`, `docs/39 §2–3` |
