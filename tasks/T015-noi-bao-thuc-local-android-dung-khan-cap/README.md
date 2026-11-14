# T015 — Nối Flutter với báo thức local Android và Dừng khẩn cấp

- **Trạng thái:** `blocked` (`chưa xác minh` — đã viết mã Dart bridge/UI, Android Kotlin/XML và unit/widget tests; chưa chạy `flutter test`/`gradle` do thiếu Flutter SDK trên máy và chưa kiểm trên thiết bị Android thật vì `adb devices` trống)
- **Mục tiêu:** nối `AlarmSchedulerService` qua `MethodChannel` có version (`bridgeVersion = 1`), kết quả typed và mã lỗi ổn định với tầng native Android (`AlarmManager.setAlarmClock`, ForegroundService `mediaPlayback`, `AlarmFireReceiver`, `BootAndTimeReceiver`, lock-screen `AlarmRingActivity`), hỗ trợ phát âm/rung, hủy, hoãn (chỉ chế độ thường), `Dừng khẩn cấp` hoạt động cả khi Flutter/backend chưa sẵn sàng, UI chuông reo nền đêm `S07`, hướng dẫn xin quyền OS khi bị từ chối, và chỉ báo `Đã sẵn sàng` khi OS xác nhận lập lịch thành công; không tự thêm Hilt/Compose.
- **Nguồn yêu cầu:** nhiệm vụ ngày 14/11/2026 (`docs/06, 09, 31, 47`, `.agents/skills/mindclock-android-native/SKILL.md`, tài liệu chính thức Android developer.android.com).
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/**`, `app/android/app/src/main/kotlin/com/mindclock/app/**`, `app/android/app/src/test/kotlin/com/mindclock/app/**`, `app/lib/**`, `app/test/**`, `tasks/T015-noi-bao-thuc-local-android-dung-khan-cap/*`.
- **Liên quan:** mở rộng trực tiếp `AlarmSchedulerService` từ `T014`.
- **Source refs đã đọc:** `docs/06 §§1–3`, `docs/09 §§1–3`, `docs/31 §§1–7`, `docs/47 §§1–4`, `.agents/skills/mindclock-android-native/SKILL.md`, tài liệu `developer.android.com` (`AlarmManager.setAlarmClock`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `ForegroundService mediaPlayback` Android 14/15). Skill chính: `mindclock-android-native`; skill bổ trợ: `flutter-custom-design-system`.
- **Điểm tiếp tục:** cài Flutter SDK + chạy Gradle/Kotlin/Flutter unit & widget test, sau đó kiểm chứng bắt buộc trên điện thoại Android thật theo bảng `docs/47` (`AD01–AD07`), phân biệt app bị đóng khỏi Recents với force-stop.

## Cổng trước coding

- [x] Đã đọc `.agents/skills/mindclock-android-native/SKILL.md`, `docs/06, 09, 31, 47`.
- [x] Đã đối chiếu tài liệu Android chính thức (`SCHEDULE_EXACT_ALARM` + `canScheduleExactAlarms()`, `USE_FULL_SCREEN_INTENT` + `canUseFullScreenIntent()`, hạn chế Android 14/15 không khởi động `mediaPlayback` foreground service từ `BOOT_COMPLETED`).
- [x] `spec.md`, `plan.md`, `tests.md` đã điền đầy đủ trước khi sửa code `app/` và `app/android/`.

## Cổng kết thúc

- [ ] Kiểm thử đơn vị Kotlin & Flutter (`flutter analyze`, `flutter test`) chạy thực tế.
- [ ] Bằng chứng trên **máy Android thật** (`AD01–AD07`: foreground/background/đóng app khỏi recents/màn khóa/offline/quyền từ chối/reboot/đổi giờ & múi giờ/tiết kiệm pin + `Dừng khẩn cấp` khi Flutter chưa chạy). Chưa có máy thật thì giữ `blocked` (`chưa xác minh`), không gắn `done`.
- [x] Không dùng Hilt/Compose trong project Flutter Android.
- [x] `handoff.md` nêu rõ giới hạn OS (bao gồm `force-stop`) và điểm tiếp tục.
