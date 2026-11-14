# Nhật ký thực hiện T015

## 2026-11-14

- Đọc `.agents/skills/mindclock-android-native/SKILL.md`, `docs/06`, `docs/09`, `docs/31`, `docs/47` và tra cứu tài liệu chính thức Android (`AlarmManager.setAlarmClock`, `canScheduleExactAlarms`, `USE_FULL_SCREEN_INTENT`, `canUseFullScreenIntent`, `ForegroundService mediaPlayback` trên Android 14/15).
- Tạo hồ sơ `tasks/T015-noi-bao-thuc-local-android-dung-khan-cap/` trước khi sửa/viết mã Flutter và Kotlin.
- Cập nhật `app/lib/domain/services/alarm_scheduler_service.dart` với `bridgeVersion = 1`, `AlarmBridgeErrorCode`, `AlarmPermissionAction`, `AlarmRingPayload`, `AndroidMethodChannelAlarmSchedulerService` (chỉ trả `scheduledReady` khi `errorCode == ok && permissionSnapshot.allGranted`).
- Viết Android Native (`app/android/app/src/main/`): `AndroidManifest.xml`, `colors.xml`, `strings.xml`, `activity_alarm_ring.xml`, `AlarmSchedulerBridgeContract.kt`, `NativeAlarmModels.kt`, `NativeAlarmStore.kt`, `AlarmRingService.kt` (`mediaPlayback`), `AlarmFireReceiver.kt`, `BootAndTimeReceiver.kt` (chỉ đặt lại lịch, không start FGS khi boot), `AlarmRingActivity.kt`, `AlarmSchedulerImpl.kt`, `MainActivity.kt` (không Hilt, không Compose).
- Cập nhật Flutter UI (`app.dart`, `app_strings.dart`, `guest_workspace_view_model.dart`, `alarm_ring_screen.dart`, `mindclock_shell_screen.dart`, `today_screen.dart`, `alarm_config_screen.dart`, `me_guest_screen.dart`).
- Viết `app/android/app/src/test/kotlin/com/mindclock/app/AlarmOccurrenceCalculatorTest.kt` và `app/test/android_bridge_contract_test.dart`.
- Chạy kiểm tra môi trường & static hygiene:
  - `where.exe flutter dart` -> không tìm thấy Flutter/Dart SDK trên máy.
  - `adb.exe devices` -> `List of devices attached` trống (0 thiết bị thật).
  - `Select-String` kiểm tra `Color(0x` và `@HiltAndroidApp|dagger\.hilt|androidx\.compose|InkWell\b|NavigationBar\b` -> 0 vi phạm trong `app/lib` và `app/android`.
- Ghi nhận `T015` ở trạng thái `blocked` (`chưa xác minh`) do thiếu Flutter SDK để build/chạy test và thiếu thiết bị Android thật để xác minh bảng `AD01–AD07`.
