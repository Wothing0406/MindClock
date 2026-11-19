# Bàn giao nhiệm vụ T059

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Thêm `StudyTimingMode` (`countdown` vs `candleCountup`) vào `StudyFocusSessionSnapshot` & `StudyFocusViewModel`, gỡ giới hạn 120p (`5–360p` ở countdown và đếm tiến không giới hạn ở `Đốt nến · Đếm giờ tự do` kèm nhắc nghỉ mắt trung tính sau 120p).
  2. Lọc bộ môn hiển thị trong `StudyTaskChoice.buildSuggestions` & `StudySpaceScreen` đúng theo `StudyProfile.selectedSubjectCodes`.
  3. Tạo `StudyCandleTimer` vẽ nến cháy chu kỳ 60 phút, tôn trọng `Reduce Motion` / `enablePeriodicTicker` và zero màu hex ngoài `MindClockTheme`.
  4. Tích hợp bản xem trước câu thử thách AI theo TKB + Hồ sơ (`MorningQuestionSelector` + `StudyAiGateway.generatePersonalizedQuestion` + fallback offline an toàn) ngay trên `AlarmConfigScreen`, đồng thời nới `target_minutes <= 360` trên `services/api/app/schemas.py`.
- **File/code/docs thay đổi:** `app/lib/domain/models/study_focus_models.dart`, `app/lib/ui/features/study_focus/{view_models/study_focus_view_model.dart,views/study_candle_timer.dart,views/study_space_screen.dart}`, `app/lib/ui/features/guest_shell/views/{alarm_config_screen.dart,mindclock_shell_screen.dart}`, `app/test/{alarm_ai_preview_and_candle_test.dart,study_focus_local_test.dart}`, `services/api/app/schemas.py`, `docs/00-start/01-hien-trang.md`, `tasks/T059-*/*`.
- **Test đã chạy:** `flutter analyze --no-pub` (`No issues found!`), `RAW_HEX_COLOR_HITS=0`, `flutter test --no-pub -j 1` (**91/91 passed**), PostgreSQL 16 `pytest -q` (**62/62 passed, 0 skipped**).
- **Test chưa chạy/giới hạn:** Chưa build lại APK riêng cho T059 (sẽ build APK tổng sau T061 trên `emulator-5554` / máy thật); EXP trên server giữ nguyên trần công bằng mỗi phiên/ngày bất kể nến cháy vượt 120p.
- **Rủi ro còn lại:** Cần đồng bộ `modelVersion` Gemini thật ở **T060** để phần xem trước câu AI trên `AlarmConfigScreen` và `StudySpaceScreen` dùng model thật khi chạy server kèm key.
- **Điểm tiếp tục chính xác:** Chuyển sang **T060** (`tasks/T060-gemini-live-models-hard-bank-regen-and-math-keypad/`).
- **Git:** Nhánh `main`, commit `e9c7cdc78da365ec64dfe76bdfc2006727288abb` đã push lên `origin/main`.
