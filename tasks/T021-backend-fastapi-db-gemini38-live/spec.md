# Đặc tả nhiệm vụ T021

## Vấn đề và kết quả mong muốn

Hiện tại repo MindClock chưa có thư mục `services/api/`, chưa có migration/CSDL local chạy thật cho backend, chưa có cấu hình `.env` cho backend/Gemini và chưa có đường sinh câu hỏi cá nhân hóa hoặc phiên Gemini Live an toàn qua server.
Sau task T021:
1. Có dịch vụ backend `services/api/` chạy FastAPI + SQLAlchemy 2.x + Alembic, dùng chung được cả **PostgreSQL** (`docker-compose.yml`) lẫn **SQLite local** (`mindclock_local.db`) theo chuẩn `docs/28 §3–4`.
2. Cấu hình Gemini được đặt sạch trong `services/api/.env` (git-ignored) + `services/api/.env.example`, sử dụng `gemini-3.8-flash` (mặc định tạo câu & gợi ý Socratic), `gemini-3.5-flash-lite` (tác vụ nhẹ), và `gemini-3.8-live` (Live API).
3. Hỗ trợ **tạo câu hỏi cá nhân hóa** (`POST /v1/questions/personalized`) theo `user_id` (`grade_band` trình độ hiện tại, `subject_code` môn học tích hợp, chủ đề yếu từ `topic_progress`) — lưu DB tách biệt ở `source_type='ai_personalized_draft'`, `status='draft'`, `xp_awarded=0` — và tự fallback sang ngân hàng câu đã duyệt khi offline/AI lỗi.
4. Hỗ trợ **tích hợp Gemini Live (`gemini-3.8-live`)** qua backend (`POST /v1/study/live-token`) cấp ephemeral token giới hạn một lần (`uses=1`, TTL ngắn, có `system_instruction` theo môn/trình độ, bắt buộc consent opt-in, **không gửi master `GEMINI_API_KEY` về client**).
5. Client Flutter có gateway/UI tương ứng để người dùng chọn môn & trình độ, yêu cầu tạo câu hỏi cá nhân hóa và lấy phiên Gemini Live opt-in mà không giữ API key trên máy.

## Phạm vi

- **Trong phạm vi:** `.gitignore`, `services/api/**`, `app/lib/**` (personalized question & live config gateways + UI triggers), `app/test/**`.
- **Ngoài phạm vi:** chấm ảnh bài thi PvP/ranked, tự động cấp XP từ câu AI draft, hay bật mic nền không có thao tác người dùng.
- **Tài liệu chuẩn:** `AGENTS.md`, `docs/06`, `docs/07`, `docs/14`, `docs/28`, `docs/36`, `docs/45`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| `GM-AC-01` | Khởi động backend từ `.env` | Nạp đúng `DATABASE_URL`, `GEMINI_PRIMARY_MODEL=gemini-3.8-flash`, `GEMINI_LIVE_MODEL=gemini-3.8-live`; `GEMINI_API_KEY` không xuất hiện trong response, log, `app/.env` hay git | `GM-TC-01` |
| `GM-AC-02` | Tạo DB local & seed môn/trình độ | Alembic/khởi tạo bảng tạo đủ bảng `docs/28` + `study_sessions`, seed câu hỏi published đa môn/trình độ; idempotency & owner A/B 403 hoạt động trên `/v1/alarms`, `/v1/challenges/next`, `/v1/study/*` | `GM-TC-02` |
| `GM-AC-03` | Người dùng A (trình độ lớp 9, môn Toán/Anh) gọi `/v1/questions/personalized` | Backend ghép `grade_band`, `subject_code`, `topic_progress` gọi `gemini-3.8-flash` (JSON schema), lưu `questions` với `status='draft'`, `target_user_id=A`; user B không đọc được; lỗi AI trả fallback sạch từ published bank, 0 XP | `GM-TC-03` |
| `GM-AC-04` | Người dùng gọi `POST /v1/study/live-token` | Kiểm tra consent opt-in (`403 CONSENT_REQUIRED` nếu chưa đồng ý); khi hợp lệ tạo ephemeral token cho `gemini-3.8-live` kèm `subject`/`grade`/`task`, không bao giờ trả `GEMINI_API_KEY` gốc | `GM-TC-04` |
| `GM-AC-05` | Client Flutter gọi cá nhân hóa & Live config | Dùng `PersonalApiClient` hiện có, hiển thị trạng thái thật/mẫu/lỗi, tắt khi mất mạng và không giữ key trong bundle | `GM-TC-05` |
