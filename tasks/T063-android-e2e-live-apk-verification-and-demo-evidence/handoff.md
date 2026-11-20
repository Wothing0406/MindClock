# Bàn giao nhiệm vụ T063

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Xác minh Kotlin native unit tests `:app:testDebugUnitTest` sau T058–T062 đạt **12/12 PASS** (`AlarmOccurrenceCalculatorTest` 3/3, `AlarmRingPrivacyAndStateTest` 3/3, `AlarmSoundResolverTest` 4/4, `MindClockWidgetFormatterTest` 2/2).
  2. Cập nhật `app/integration_test/arena_game_e2e_test.dart` để kiểm chứng chọn bộ đếm `arena-timer-30` (`Thời gian còn: 30s`) trong chuỗi E2E thật trên `emulator-5554` — đạt **`02:24 +1: All tests passed!`**.
  3. Cài đặt lại `dist/mindclock-debug.apk` (`152.37 MB`) lên `emulator-5554`, điều hướng trực tiếp qua Welcome → Cấu hình báo thức → Luyện tập (đối chiếu offline bank + bàn phím Toán học) → Đấu trường Hub → Luyện đơn Setup (chips `30s/45s/60s/90s`), chụp & đọc trực quan 4 ảnh PNG mới trong `test_demo_android/screenshots/` (`19_t063_apk_launch.png`, `20_t063_practice_clean_ui.png`, `21_t063_arena_hub.png`, `22_t063_arena_timer_setup.png`).
- **File/code/docs thay đổi:** `app/integration_test/arena_game_e2e_test.dart`, `test_demo_android/README.md`, `test_demo_android/screenshots/{19_t063_apk_launch.png,20_t063_practice_clean_ui.png,21_t063_arena_hub.png,22_t063_arena_timer_setup.png}`, `docs/00-start/01-hien-trang.md`, `tasks/T063-*/*`.
- **Test đã chạy:**
  - Kotlin `:app:testDebugUnitTest`: **12/12 PASS**.
  - Android Emulator E2E `arena_game_e2e_test.dart -d emulator-5554`: **PASS (`02:24 +1`)**.
  - `check_docs_links.py` & `check_task_records.py` (chạy trước commit).
- **Test chưa chạy/giới hạn:** Emulator không thay thế **2 máy Android vật lý thật** (báo thức màn khóa/Doze/boot/DND và PvP 1v1 live đồng thời hai máy) và vẫn còn **1 cổng xác nhận ở T061** (`assets/game/` nghiên cứu vs bộ asset gốc `app/assets/`).
- **Điểm tiếp tục chính xác:** Nếu muốn cài APK lên điện thoại Android thật để tự tay test AI + đồng bộ từ ngoài mạng localhost, build bằng `.\scripts\build_android_apk.ps1 -Mode release -ApiBaseUrl https://<domain-backend-staging>` (trước đó cấu hình Firebase dự án thật & keystore phát hành), đồng thời phản hồi quyết định asset cho T061.
- **Git:** Nhánh `main` — đã push `cb2f3a00d269c83f8d8c41ab10ba078a77abf8e1` (`origin/main`).
