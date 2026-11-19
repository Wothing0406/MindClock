# Báo Cáo Kiểm Thử Game Đấu Trường G1 Trên Môi Trường Ảo Android (T056)

- **Ngày kiểm thử:** `2026-11-19`
- **Thiết bị ảo:** Android Emulator `emulator-5554` (`Medium_Phone_API_37.0`, `1080×2400`)
- **Bản build APK:** `dist/mindclock-debug.apk` (`151.77 MB`, universal `arm` + `arm64` + `x64`, có đủ Android Adaptive Icon `ic_launcher` + `LaunchTheme` splash)
- **Tệp E2E test:** [`app/integration_test/arena_game_e2e_test.dart`](../app/integration_test/arena_game_e2e_test.dart)

---

## 1. Kết Quả Chạy Thực Tế Trên Máy Ảo & Test Suite

| Hạng mục | Lệnh chạy thực tế | Kết quả |
| :--- | :--- | :--- |
| **Game E2E trên Emulator thật** | `flutter test integration_test/arena_game_e2e_test.dart -d emulator-5554 --no-pub --reporter expanded` | **PASS (`00:54 +1: All tests passed!`)** |
| **Flutter Unit & Widget Tests** | `flutter test --no-pub -j 1` | **PASS (`84/84 All tests passed!`)** |
| **Static Analysis & Theme** | `flutter analyze --no-pub` + scan `Color(0x` | **0 issues**, **`RAW_COLOR_HITS: 0`** |
| **Android Kotlin Native + Resource** | `.\gradlew.bat :app:testDebugUnitTest --no-daemon --no-watch-fs` | **PASS (`10/10` `:app` tests)**, AAPT2 adaptive icon & splash biên dịch sạch |
| **APK Build Universal** | `.\scripts\build_android_apk.ps1 -Mode debug` | **PASS (`dist/mindclock-debug.apk`, `151.77 MB`)** |

---

## 2. Chuỗi Kịch Bản Game Đã Kiểm Chứng Trong `emulator-5554`

1. **App Launch Branding (`29_android_launcher_icon.png`, `30_app_launch_splash.png`):**
   - Icon `MindClock` hiển thị sắc nét trong Android App Drawer (`mipmap-*` 48–192px + `mipmap-anydpi-v26` Adaptive Icon, không cắt mép).
   - Khi mở app, OS hiển thị ngay `LaunchTheme` nền xanh đêm `#101A30` + logo vector `splash_mark`, chuyển tiếp sang Flutter Boot Loading (`MindClockBrandMark` + thanh tiến trình) trước khi vào màn chính.
2. **Đấu Trường Hub & Modal Xem Tướng (`19_arena_hub_modes.png` – `21_arena_champion_detail_modal.png`):**
   - Hub tách bạch 3 chế độ: `Luyện đơn` (mở, 0 RP), `Giao hữu 1v1` (khóa G2), `Đấu đội 2v2` (khóa G3).
   - Chọn môn có sẵn bộ câu duyệt, chọn tướng (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bội Pháp`) và mở modal xem trước nội tại + bộ 3 chiêu thức trước trận.
3. **Màn Loading Game (`ArenaSection.loading`):**
   - Bấm `Bắt đầu Luyện đơn` chuyển qua `ArenaSection.loading` (`arena-loading-screen`) precache trước ảnh sân `Võ đường Bình minh`, hai chân dung và icon chiêu thức; hiện cặp đối đầu `Bạn vs Máy tập`, thanh tiến trình mượt và nút `Vào trận ngay` / `Quay lại chọn tướng`.
4. **Cơ Chế Chiến Đấu Công Bằng 6 Round (`22` – `27`):**
   - Nộp câu mơ hồ (`?`) -> trả về `uncertain` -> **bảo toàn nguyên vẹn `100 HP`**, cho đổi câu không mất lượt.
   - Giải đúng + bước trình bày -> mở chiêu (`Đánh thường` / `Chiêu 1` / `Chiêu 2`), settle round với `Máy tập`, chuyển mượt tới màn **Tổng kết trận (`0 RP`)** và bấm **Luyện lại cùng seed** đi qua `ArenaSection.loading` lần 2 không lỗi.

---

## 3. Cải Tiến Màn Đặt Báo Thức (`@11_alarm_config_challenge_and_sound`)

- **Trước (`T055`):** Màn cấu hình báo thức chứa danh mục 11 chip chọn môn thủ công và bộ chọn `Báo thức thường / thử thách`.
- **Sau (`T056`, xem [`screenshots/11_alarm_config_challenge_and_sound.png`](screenshots/11_alarm_config_challenge_and_sound.png)):** Đã **xóa toàn bộ lựa chọn môn thủ công và lựa chọn chế độ thường**; mặc định mọi chuông mới là **Báo thức thử thách (`AlarmMode.challenge`)**, tự động chọn môn & câu theo **hồ sơ lớp/tổ hợp môn và TKB buổi sáng (`AlarmSubjectRule.todaySchedule`)**, vẫn bảo toàn nút **Dừng khẩn cấp 1 chạm**.

---

## 4. Phạm Vi Game & Tính Năng Chưa Mở (Giai Đoạn Sau)

- **Chưa mở trên UI ở G1:**
  - Ghép phòng 1v1 trực tuyến 2 máy thật (**G2** — backend đã có 6 route `/v1/pvp/*` và 7 bảng Postgres, chưa nối client realtime 2 máy).
  - Đấu đội 2v2 (**G3**) & Đấu hạng RP (**G4** — bị chặn tới khi qua playtest & eval AI).
  - Giao diện **Kết bạn / Tìm bạn học theo trình độ / Phòng học công khai nhiều người / To-Do & Lịch trình kiểu Calendar + Android Home Screen Widget** (cần mở sprint riêng R6).
