# Bàn giao nhiệm vụ T060

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Benchmark live danh sách `/v1beta/models` của Gemini API phát hiện `gemini-2.5-*` trả `404` cho user mới và `gemini-3.8-flash` / `3.5-flash-lite` đang trả `503/timeout`, trong khi **`gemini-3.1-flash-lite`** (`2.85s` với `thinkingLevel: low`) và **`gemini-3-flash-preview`** (`5.29s`) trả **HTTP 200** ổn định. Cập nhật `config.py`, `.env.example`, chuỗi fallback đa tầng trong `GeminiService._generate_with_fast_fallback` và giữ `.env` chỉ ở cục bộ không commit.
  2. Nâng cấp `PersonalizedQuestionRequest` + `/v1/questions/personalized` + `generate_personalized_question` với 3 giai đoạn `foundational` / `applied` / `advanced` neo theo `seedQuestionId` từ ngân hàng câu đã duyệt (tái tạo bối cảnh thực tế & số liệu mới, giữ chuẩn rubric GDPT 2018) và chuẩn hóa biểu thức toán/đạo hàm (`3 x^2` = `3x²`) trong `answer_normalizer.py`.
  3. Tạo `MathFormulaText` & `MathInputKeypad` (`x²`, `x³`, `^`, `/`, `%`, `√`, `'`, `π`, `Δ`, `→`, `=`, `(`, `)`, `Xóa`) và gắn vào `PracticeSessionScreen`, `ArenaScreen`, `StudySpaceScreen`, `AlarmConfigScreen`.
- **File/code/docs thay đổi:** `services/api/.env.example`, `services/api/app/{config.py,schemas.py,routes/v1.py,services/gemini_service.py,services/answer_normalizer.py}`, `services/api/tests/test_gemini_regen_and_grading.py`, `app/lib/ui/core/widgets/{math_formula_text.dart,math_input_keypad.dart}`, `app/lib/ui/features/{personal_flow/views/practice_session_screen.dart,arena/views/arena_screen.dart,study_focus/views/study_space_screen.dart,guest_shell/views/alarm_config_screen.dart}`, `app/test/math_formula_and_keypad_test.dart`, `docs/00-start/01-hien-trang.md`, `tasks/T060-*/*`.
- **Test đã chạy:** PostgreSQL 16 `pytest -q` (**64 passed, 0 skipped**), kiểm thử live `GeminiService` với `.env` cục bộ (`stage='advanced'` trả câu thực tế `gemini-3.1-flash-lite` **HTTP 200** không log key), `flutter analyze --no-pub`, `RAW_HEX_COLOR_HITS=0`, `flutter test --no-pub -j 1`.
- **Test chưa chạy/giới hạn:** Bidi Live WebSocket audio thực tế (`gemini-3.1-flash-live-preview`) chưa được test âm thanh hai chiều trên 2 thiết bị thật (để ở gated feature flag).
- **Rủi ro còn lại:** Nếu Google thay đổi model preview/GA theo thời gian, fallback chain sẽ tự trượt qua model kế tiếp nhưng vẫn cần theo dõi `/v1/health` và chi phí token định kỳ.
- **Điểm tiếp tục chính xác:** Chuyển sang **T061** (`tasks/T061-pvp-sprites-original-avatars-battle-map-and-demo-refresh/`).
- **Git:** Nhánh `main`, chuẩn bị commit & push `T060`.
