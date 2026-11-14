# Bàn giao T021

- **Trạng thái hiện tại:** `blocked` (toàn bộ backend FastAPI + Alembic SQLite + Gemini 3.8/3.5/Live API đã chạy và vượt qua pytest + smoke check thật; phần Flutter đã hoàn tất code/test nhưng runtime Flutter bị chặn bởi Windows Application Control trên máy hiện tại).

## Phần đã xong và đã kiểm chứng thật

1. **Cấu hình môi trường & bảo mật key:**
   - [services/api/.env.example](../../services/api/.env.example) khai báo đầy đủ biến môi trường backend, DB local/PostgreSQL, Gemini `3.8-flash` / `3.5-flash-lite` / `3.8-live`.
   - `services/api/.env` chứa `GEMINI_API_KEY` thực tế của người dùng trên máy local và được `.gitignore` chặn tuyệt đối khỏi git, client Flutter và response API.
2. **Database local & Container (`docs/06`, `docs/28`):**
   - [services/api/app/db/models.py](../../services/api/app/db/models.py) và [services/api/alembic/versions/0001_initial_schema.py](../../services/api/alembic/versions/0001_initial_schema.py): đủ 11 bảng (`users`, `alarms`, `timetable_slots`, `questions`, `alarm_sessions`, `attempts`, `study_sessions`, `xp_ledger`, `topic_progress`, `idempotency_records`, `consent_events`).
   - [services/api/app/db/seed.py](../../services/api/app/db/seed.py): seed 6 câu `published` (`approved_bank`) đa môn/trình độ (`TOAN`, `TIENG_ANH`, `NGU_VAN`, `VAT_LY`, lớp 7/9/12).
   - [services/api/Dockerfile](../../services/api/Dockerfile) (multi-stage, non-root `appuser`, healthcheck) & [services/api/docker-compose.yml](../../services/api/docker-compose.yml) (PostgreSQL 16 + API tách network `mindclock_internal`/`mindclock_public`).
   - Đã chạy thật `alembic upgrade head` trên SQLite local (`services/api/mindclock_local.db`, git-ignored).
3. **Gemini 3.8 + Câu hỏi cá nhân hóa + Gemini Live (`gemini-3.8-live`):**
   - [services/api/app/services/gemini_service.py](../../services/api/app/services/gemini_service.py): dùng `gemini-3.8-flash` (`thinkingConfig.thinkingLevel = low`) kèm cơ chế tự hạ 1 lần sang `gemini-3.5-flash-lite` nếu `gemini-3.8-flash` quá hạn/lỗi upstream; cấp ephemeral token 1 lần cho `gemini-3.8-live` qua `v1alpha/auth_tokens` với `bidiGenerateContentSetup`.
   - [services/api/app/routes/v1.py](../../services/api/app/routes/v1.py): `POST /v1/questions/personalized`, `GET /v1/questions/personalized`, `POST /v1/sessions/{id}/attempts` (chấm ảnh Gemini Vision `inlineData` khớp multipart `image` của Flutter, không lưu ảnh), chống nhân đôi XP cùng phiên, `GET/PUT /v1/timetable`, `DELETE /v1/me` (`202`), `POST /v1/study/live-token` (`403 CONSENT_REQUIRED`).
   - [services/api/app/demo_ui.py](../../services/api/app/demo_ui.py) & [services/api/run_demo.py](../../services/api/run_demo.py): giao diện sandbox demo tương tác tại `/demo` + `/demo/bermuda.mp3` chạy song song cho PC (`127.0.0.1:8000`) và Android Emulator (`10.0.2.2:8000`).
   - Kết quả kiểm chứng: `.\.venv\Scripts\python.exe -m pytest -v` đạt `13 passed`; máy chủ live `uvicorn` trả HTTP `200` cho `/v1/health`, `/v1/me`, `/v1/questions/personalized` (`model: gemini-3.5-flash-lite`), `/v1/study/help` và `/v1/study/live-token` (`model: gemini-3.8-live`, `isMock: False`).
4. **Nối Flutter frontend (`app/lib/**`, `app/test/**`):**
   - Mở rộng [StudyAiGateway](../../app/lib/domain/services/study_ai_gateway.dart), [RemoteStudyAiGateway](../../app/lib/data/repositories/remote_study_ai_gateway.dart), [DebugFixtureStudyAiGateway](../../app/lib/data/debug/debug_fixture_study_ai_gateway.dart), [StudyFocusViewModel](../../app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart) và [StudySpaceScreen](../../app/lib/ui/features/study_focus/views/study_space_screen.dart) cho nút tạo câu hỏi cá nhân hóa theo môn/lớp & toggle/cấp token Gemini Live (0 XP tự cấp, 0 API key ở client).
   - Bổ sung `INT-TC-08` & `INT-TC-09` trong [backend_integration_contract_test.dart](../../app/test/backend_integration_contract_test.dart) và route mock tương ứng trong [LoopbackV1ContractServer](../../app/test/support/loopback_v1_contract_server.dart).

## Rủi ro & phần chưa xác minh

- `flutter test` và `dart analyze` bị Windows Application Control policy chặn thực thi `.local-sdk/flutter/bin/cache/dart-sdk/bin/dartaotruntime.exe` trên máy này (`exit 254`), nên code Flutter mới sửa chưa được compiler/test runner kiểm chứng trên host.
- `docker compose up -d` (PostgreSQL 16 + Alembic migration trên Postgres trống) chưa chạy kiểm chứng thực tế trên máy này.

## Điểm tiếp tục cụ thể

1. Trên máy/CI có Flutter SDK chạy bình thường, chạy: `cd app && flutter test test/backend_integration_contract_test.dart` và `flutter test`.
2. Trên máy bật Docker Desktop engine, chạy: `cd services/api && docker compose up -d --build` và kiểm tra `/v1/health` trả `dbDialect: "postgresql"`.
