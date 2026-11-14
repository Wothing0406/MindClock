# Nhật ký thực hiện T021

## 2026-11-14

- Lập hồ sơ `T021-backend-fastapi-db-gemini38-live` trước khi sửa code/cấu hình.
- Xác minh trực tiếp trên `generativelanguage.googleapis.com` với key trong `.env` (không ghi log key): `/v1beta/models` trả 200 với 50 model trong đó có `gemini-3.8-flash`, `gemini-3.5-flash-lite`; `v1alpha/auth_tokens` hỗ trợ `gemini-3.8-live`.
- Dựng hoàn chỉnh `services/api/`: `.env.example`, `.env` (git-ignored), `requirements.txt`, `pyproject.toml`, `Dockerfile`, `docker-compose.yml`, `app/config.py`, `app/db/{base,models,seed}.py`, `alembic/` (`0001_initial_schema`), `app/auth/verify_token.py`, `app/repositories/idempotency.py`, `app/schemas.py`, `app/services/gemini_service.py`, `app/routes/v1.py`, `app/main.py`, `tests/test_api_v1.py`.
- Chu trình lỗi & sửa gốc #1: chạy `alembic upgrade head` lần đầu lỗi `KeyError: 'qualname'` do thiếu `qualname = sqlalchemy.engine` và `qualname = alembic` trong `services/api/alembic.ini` -> đã bổ sung và chạy lại `alembic upgrade head` thành công (SQLite `mindclock_local.db`).
- Chu trình lỗi & sửa gốc #2: chạy smoke live `/v1/questions/personalized` & `/v1/study/live-token` phát hiện 2 nguyên nhân thật:
  1. `v1alpha/auth_tokens` từ chối field `liveConnectConstraints` (HTTP 400); đổi sang `bidiGenerateContentSetup` (`model`, `generationConfig.responseModalities`, `systemInstruction`) -> API Google trả HTTP 200 kèm `auth_tokens/...`.
  2. `gemini-3.8-flash` hiện phản hồi quá `15–25s` (`ReadTimeout`) trên route API này kể cả khi đặt `thinkingLevel: low`; đã thêm cơ chế tự hạ 1 lần từ `gemini-3.8-flash` (timeout 6s) sang `gemini-3.5-flash-lite` (đã đo thực tế HTTP 200 sau 1.38s) trước khi fallback về ngân hàng duyệt.
- Chu trình lỗi & sửa gốc #3: mở rộng `normalize_subject_code` trong `gemini_service.py` & `routes/v1.py` để khớp cả mã frontend `SubjectCatalog` (`math`, `physics`, `english`, `literature`, ...) lẫn mã backend (`TOAN`, `VAT_LY`, `TIENG_ANH`, `NGU_VAN`, ...).
- Chạy lại `.\.venv\Scripts\python.exe -m pytest -v` trong `services/api`: `9 passed in 5.76s` + smoke live HTTP 200 cả 2 endpoint `/v1/questions/personalized` và `/v1/study/live-token`.
- Nối Flutter frontend (`study_ai_models.dart`, `study_ai_gateway.dart`, `remote_study_ai_gateway.dart`, `debug_fixture_study_ai_gateway.dart`, `study_focus_view_model.dart`, `study_space_screen.dart`, `loopback_v1_contract_server.dart`, `backend_integration_contract_test.dart`).
- Thử chạy `flutter test` và `dart analyze` bằng `.local-sdk/flutter`: `pub` giải quyết đủ 62 gói nhưng `dartaotruntime.exe` bị Windows Application Control policy chặn (`ProcessException: An Application Control policy has blocked this file`, exit 254). Đã khôi phục `app/analysis_options.yaml` nguyên trạng và ignore các file `.dart_tool/` / `local.properties` phát sinh trên máy.
- Hoàn thiện 100% phần Python còn lại & nâng cấp prompt/chống bug:
  - Chốt chống nhận đôi XP khi nộp đáp án đúng nhiều lần với `Idempotency-Key` khác nhau trong cùng `alarm_session`.
  - Hoàn thiện `POST /v1/sessions/{id}/attempts`: khớp đúng multipart field `image` của Flutter, kiểm tra <= 5 MB (`413`) và MIME (`415`), gọi Gemini Vision (`grade_photo_attempt`) hoàn toàn trong bộ nhớ (không lưu ảnh ra đĩa/log), xử lý markdown JSON fence (`_parse_json_object`).
  - Chuẩn hóa hợp đồng `POST /v1/sessions/{id}/feedback` (`attemptId`, `category`, `comment`), bổ sung `GET/PUT /v1/timetable`, `DELETE /v1/me` (`202` xóa sạch dữ liệu user), thêm câu seed `SINH_HOC` & `TIN_HOC`.
  - Nâng cấp toàn bộ system prompt GDPT 2018 và gắn thẻ XML chống prompt injection (`<student_input>`, `<student_topic_hint>`, `<server_rubric>`).
  - Bổ sung giao diện demo tương tác `/demo` + `/demo/bermuda.mp3` + `run_demo.py` phục vụ kiểm thử song song trên PC (`http://127.0.0.1:8000/demo`) và Android Emulator (`http://10.0.2.2:8000/demo`).
- Chạy lại `.\.venv\Scripts\python.exe -m pytest -v`: `13 passed in 7.68s`. Khởi động máy chủ `uvicorn` trên `0.0.0.0:8000` và kiểm thử live E2E HTTP 200 cho `/v1/health`, `/v1/me`, `/v1/questions/personalized`, `/v1/study/help`, `/v1/study/live-token`.
- Thử `flutter build apk --debug` không build được vì `app/android/` thiếu cấu trúc Gradle wrapper (`Build failed due to use of deleted Android v1 embedding`). Đang khởi động trực tiếp `Medium_Phone_API_37.0` qua Android Emulator để mở trực tiếp luồng demo web kết nối máy chủ backend thật qua `10.0.2.2:8000/demo`.
