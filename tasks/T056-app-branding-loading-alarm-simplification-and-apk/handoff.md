# Bàn giao nhiệm vụ T056

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Tạo đủ bộ Android Launcher Icon (`mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` & `ic_launcher_round.png`, Adaptive Icon `mipmap-anydpi-v26/ic_launcher*.xml` + VectorDrawable `ic_launcher_{foreground,background}.xml` từ `assets/brand/mindclock-mark.svg`, `assets/brand/mindclock-mark-512.png`), gắn vào `AndroidManifest.xml`.
  2. Thêm Android `LaunchTheme` (`drawable/launch_background.xml`, `drawable/splash_mark.xml`, `values/styles.xml`) và nâng cấp Flutter Boot Screen (`MindClockBrandMark` + `MindClockLoadingProgressBar` dùng 100% token `MindClockTheme`) trong `MindClockShellScreen`.
  3. Bổ sung màn **Loading Game (`ArenaSection.loading`)** trong `SoloArenaViewModel` & `ArenaScreen` với `AnimationController` 60fps, precache ảnh sân đấu/tướng/kỹ năng, hiển thị cặp đối đầu và hỗ trợ Reduce Motion + `320dp/200%`.
  4. Tinh gọn màn Cấu hình báo thức `AlarmConfigScreen` (`@11_alarm_config_challenge_and_sound`): xóa card chọn 11 môn thủ công & card chọn chế độ thường/thử thách; mặc định auto `AlarmMode.challenge` + `AlarmSubjectRule.todaySchedule` (tự động từ hồ sơ + TKB sáng) kèm card `Thử thách buổi sáng tự động` và giữ **Dừng khẩn cấp 1 chạm**. Cập nhật `docs/01-product/09-giac-ngu-va-bao-thuc.md` & `docs/00-start/01-hien-trang.md`.
  5. Viết E2E Game `app/integration_test/arena_game_e2e_test.dart`, chạy trực tiếp trên `emulator-5554`, thêm `scripts/build_android_apk.ps1` (xuất `dist/mindclock-debug.apk`, gitignored `.gitignore`), chụp ảnh kiểm chứng và ghi `test_demo_android/game_emulator_test_report.md`.
- **File/code/docs thay đổi:** `app/android/app/src/main/{AndroidManifest.xml,res/**}`, `assets/brand/mindclock-mark-512.png`, `app/lib/ui/core/{strings/app_strings.dart,widgets/mindclock_brand_mark.dart}`, `app/lib/ui/features/guest_shell/views/{mindclock_shell_screen.dart,alarm_config_screen.dart}`, `app/lib/ui/features/arena/{view_models/solo_arena_view_model.dart,views/arena_screen.dart}`, `app/test/{guest_flow_widget_test.dart,solo_arena_widget_test.dart}`, `app/integration_test/arena_game_e2e_test.dart`, `scripts/build_android_apk.ps1`, `.gitignore`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/00-start/01-hien-trang.md`, `test_demo_android/{README.md,game_emulator_test_report.md,screenshots/{11,29,30}}`, `tasks/T056-*/*`.
- **Test đã chạy (2026-11-19):**
  - `flutter analyze --no-pub`: **0 issues (`No issues found!`)**
  - `flutter test --no-pub -j 1`: **84/84 All tests passed!**
  - `Color(0x` scan ngoài `mindclock_theme.dart`: **`RAW_COLOR_HITS: 0`**
  - `.\gradlew.bat :app:testDebugUnitTest --no-daemon --no-watch-fs`: **`BUILD SUCCESSFUL`**, XML **`10/10` pass**
  - `flutter test integration_test/arena_game_e2e_test.dart -d emulator-5554 --no-pub --reporter expanded`: **PASS (`00:54 +1: All tests passed!`)**
  - `.\scripts\build_android_apk.ps1 -Mode debug`: **PASS (`dist/mindclock-debug.apk`, `151.77 MB`)**
  - `python scripts/check_docs_links.py` & `python scripts/check_task_records.py`: **PASS**
- **Test chưa chạy/giới hạn:** Chưa test trên 2 máy Android vật lý thật, chưa ký release keystore để phát hành Store, chưa host backend HTTPS public.
- **Rủi ro còn lại:** Để điện thoại thật dùng được AI & đồng bộ tài khoản, khi build APK phải truyền `-ApiBaseUrl https://<domain-backend-public>`.
- **Điểm tiếp tục chính xác:** Triển khai sprint mới (T057+) cho **R6/Social & Clock-First Calendar**: giao diện Kết bạn / Tìm bạn học theo trình độ / Phòng học công khai nhiều người, màn Lịch trình ngày theo giờ + To-Do done công việc + Android Home Screen Widget (`AppWidgetProvider`).
- **Git:** Nhánh `main` · commit triển khai `c3ae885` (`c3ae885a3eec60166c454827871cfefd8b303781`) đã push & xác minh trên `origin/main`; commit tiếp theo bổ sung trọn bộ ảnh/video dẫn chứng `test_demo_android/` và cập nhật SHA vào `handoff.md`.
