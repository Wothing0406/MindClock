# T021 — Thiết lập cấu hình Gemini 3.8 + Gemini Live, DB local (PostgreSQL/SQLite) & câu hỏi cá nhân hóa

- **Trạng thái:** `blocked`
- **Mục tiêu:** dựng dịch vụ backend FastAPI (`services/api/`) theo kiến trúc phân lớp (`Router -> Service -> Repository -> DB`), cấu hình `.env` & `.env.example` (giữ `GEMINI_API_KEY` chỉ ở server, git-ignored), DB local chuẩn SQLAlchemy 2.x + Alembic (hỗ trợ PostgreSQL qua Docker Compose và SQLite local fallback), tích hợp `gemini-3.8-flash` (+ fallback `gemini-3.5-flash-lite`) sinh câu hỏi luyện tập cá nhân hóa theo user + môn + trình độ & Socratic `/v1/study/help`, tích hợp `gemini-3.8-live` qua ephemeral token giới hạn một lần (`POST /v1/study/live-token`, opt-in, 0 lộ key tới client), và nối trên Flutter frontend.
- **Nguồn yêu cầu:** yêu cầu người dùng ngày 14/11/2026: cấu hình Gemini (`AQ.` chỉ lưu cục bộ trong `services/api/.env` git-ignored), gọi model `3.8`, tích hợp Gemini Live, thiết lập `.env` đầy đủ, database local phù hợp, tạo câu hỏi cá nhân hóa cho từng user, từng môn học và trình độ hiện tại.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file đã sửa/tạo:** `.gitignore`, `services/api/**`, `tasks/T021-backend-fastapi-db-gemini38-live/*`, `app/lib/domain/models/study_ai_models.dart`, `app/lib/domain/services/study_ai_gateway.dart`, `app/lib/data/repositories/remote_study_ai_gateway.dart`, `app/lib/data/debug/debug_fixture_study_ai_gateway.dart`, `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`, `app/test/backend_integration_contract_test.dart`, `app/test/support/loopback_v1_contract_server.dart`.
- **Liên quan:** hiện thực hóa phần lõi backend cá nhân của `T016` ([README T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md)), nối khớp hợp đồng `T017`/`T019`, mở rộng `/v1/questions/personalized` & `/v1/study/live-token`.
- **Source refs đã đọc:** `AGENTS.md`, `docs/06-kien-truc-va-du-lieu.md`, `docs/07-hop-dong-api-va-ai.md`, `docs/14-vai-tro-va-quy-dinh-ai.md`, `docs/28-backend-sql.md`, `docs/36-diem-khac-biet-hai-huoc-gemini-va-hieu-nang.md`, `docs/45-khong-gian-hoc-va-che-do-tap-trung.md §§4–5`, `tasks/T016-backend-fastapi-postgres-luong-ca-nhan/spec.md`.
- **Điểm tiếp tục:** chạy `flutter test test/backend_integration_contract_test.dart` trên máy/CI không chặn `dartaotruntime.exe`, và chạy `docker compose up -d` trong `services/api/` để kiểm chứng PostgreSQL 16 + Alembic `upgrade/downgrade` trên container thật.

## Cổng trước coding

- [x] Xác minh chuẩn model thực tế trên API (`generativelanguage.googleapis.com`): `gemini-3.8-flash`, `gemini-3.5-flash-lite`, `gemini-3.8-live` và developer key `AQ.` dùng header `x-goog-api-key`.
- [x] Chốt quy tắc bảo mật: `GEMINI_API_KEY` tuyệt đối chỉ nằm trong `services/api/.env` (được `.gitignore` chặn), không đưa vào `app/.env`, mã nguồn Flutter hay git commit; câu AI cá nhân hóa gắn `status='draft'` / `0 XP` không thay ngân hàng báo thức đã duyệt (`docs/14 §1,§5`).
- [x] Lập đủ `spec.md`, `plan.md`, `tests.md` trước khi tạo code.

## Cổng kết thúc

- [x] `alembic upgrade head` (SQLite local) và `pytest -v` backend pass `13/13` test (`tests/test_api_v1.py`, gồm chấm ảnh Gemini Vision, chống nhân đôi XP, `GET/PUT /v1/timetable`, `DELETE /v1/me`, `/demo`, `/demo/bermuda.mp3`).
- [x] Khởi chạy máy chủ `uvicorn` live trên `0.0.0.0:8000` (`http://127.0.0.1:8000/demo` & `http://10.0.2.2:8000/demo`) và smoke check thật (không lộ key): `/v1/health`, `/v1/me`, `/v1/questions/personalized`, `/v1/study/help`, `/v1/study/live-token` đều trả HTTP `200` thật.
- [ ] `flutter test` / `dart analyze` / `flutter build apk` chưa pass trên máy này vì Windows Application Control policy chặn `dartaotruntime.exe` và `app/android/` chưa có Gradle wrapper (`flutter create --platforms=android`).
- [ ] `docker compose` PostgreSQL 16 chưa chạy kiểm chứng thực tế trên máy này.
