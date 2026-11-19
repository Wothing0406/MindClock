# T056 — Logo app Android, Load app, Loading game, tinh gọn Báo thức Thử thách tự động & Test game emulator + APK

- **Trạng thái:** `done`
- **Mục tiêu:** Hoàn thiện bộ nhận diện khởi động (Adaptive/Mipmap `ic_launcher` từ `assets/brand/mindclock-mark.svg`, Android Launch Splash + Flutter Boot Screen), màn Loading vào Đấu trường G1, đơn giản hóa màn cấu hình báo thức (`S06`: tự động chế độ Thử thách & AI/hệ thống tự lấy môn theo hồ sơ + TKB buổi sáng, xóa chọn môn/chọn chế độ thừa), bổ sung kịch bản test game E2E trên Android Emulator (`emulator-5554`), cập nhật báo cáo `test_demo_android/` và build APK sẵn sàng cài kiểm thử.
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`@11_alarm_config_challenge_and_sound`, logo app, load app, loading game, test game môi trường ảo & báo cáo, xuất APK).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/mipmap-*`, `res/drawable/*`, `res/values/styles.xml`, `res/values/colors.xml`
  - `app/lib/ui/core/widgets/mindclock_brand_mark.dart`, `app/lib/ui/core/strings/app_strings.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`
  - `app/lib/ui/features/arena/view_models/solo_arena_view_model.dart`, `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/test/*`, `app/integration_test/arena_game_e2e_test.dart`
  - `scripts/build_android_apk.ps1`
  - `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/00-start/01-hien-trang.md`
  - `test_demo_android/README.md`, `test_demo_android/ui_features_recap.md`, `test_demo_android/game_emulator_test_report.md`, ảnh/video demo bổ sung.
- **Liên quan:** `T034-brand-logo-and-git-handoff`, `T047-g1-arena-solo-training`, `T054-arena-original-assets-and-champion-preview`, `T055-student-avatars-and-custom-media-picker`.
- **Source refs đã đọc:** `AGENTS.md §2–4`, `docs/01-product/03-he-thiet-ke.md`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/04-game/02-g1-luyen-don-cuc-bo.md`, `assets/brand/mindclock-mark.svg`, `app/android/app/src/main/AndroidManifest.xml`, `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/ui/features/arena/views/arena_screen.dart`.
- **Điểm tiếp tục:** Triển khai icon `ic_launcher` + Android splash + `MindClockBrandMark` + loading game + tinh gọn `AlarmConfigScreen`, sau đó chạy full tests & live emulator game test + build APK.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và ghi quyết định trong `spec.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
