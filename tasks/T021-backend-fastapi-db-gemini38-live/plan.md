# Kế hoạch thực hiện T021

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Lập hồ sơ `T021`, cập nhật `.gitignore` bảo vệ `services/api/.env`, SQLite DB local, `.venv`, artifact sinh từ Flutter SDK cục bộ | Zero secret/DB rác lọt git | [x] |
| 2 | Dựng `services/api/` với `pyproject.toml`, `requirements.txt`, `.env.example`, `.env` (chứa key `AQ.` cục bộ không commit), `Dockerfile` (multi-stage + non-root) & `docker-compose.yml` (PostgreSQL 16 + API tách network) | Đủ cấu hình dev & container | [x] |
| 3 | Dựng tầng `db/` (SQLAlchemy 2.x models theo `docs/28`, Alembic initial migration `0001_initial_schema`, seed ngân hàng câu đa môn/trình độ) + `auth/` (`verify_token.py`) | `alembic upgrade head` SQLite pass | [x] |
| 4 | Dựng `services/gemini_service.py` (`gemini-3.8-flash` kèm `thinkingLevel: low` + tự hạ sang `gemini-3.5-flash-lite` khi quá hạn/lỗi upstream, `gemini-3.8-live` qua `v1alpha/auth_tokens` + `bidiGenerateContentSetup`, chuẩn hóa alias mã môn `math/TOAN`) | Prompt có version, không cấp XP từ AI, smoke thật HTTP 200 | [x] |
| 5 | Dựng routes `/v1` (`/health`, `/me`, `/alarms`, `/challenges/next`, `/sessions`, `/study/*`, `/questions/personalized`, `/study/live-token`) + `tests/test_api_v1.py` (`9` pytest) | `9/9` pytest pass | [x] |
| 6 | Nối Flutter frontend (`StudyAiGateway`, `RemoteStudyAiGateway`, `StudyFocusViewModel`, `StudySpaceScreen` card tạo câu cá nhân hóa & Live opt-in) + contract tests (`INT-TC-08`, `INT-TC-09`) | Code xong; chờ máy/CI không chặn `dartaotruntime.exe` để chạy `flutter test` | [~] |
