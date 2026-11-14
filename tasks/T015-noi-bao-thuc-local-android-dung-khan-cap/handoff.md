# Bàn giao T015

## 1. Đã làm trong lát cắt này

1. **Hợp đồng cầu nối Android có version & typed outcomes:**
   - `app/lib/domain/services/alarm_scheduler_service.dart`: thêm `AlarmBridgeErrorCode`, `AlarmPermissionAction`, `AlarmRingPayload`, `AlarmPermissionSnapshot.missingActions()`, các method `snoozeAlarm`, `triggerEmergencyStop`, `openPermissionSettings`, `consumePendingRingLaunch`, và `AndroidMethodChannelAlarmSchedulerService` (`bridgeVersion = 1`, bắt `MissingPluginException` an toàn, và chốt không bao giờ trả `scheduledReady` nếu `errorCode != ok` hoặc `!permissionSnapshot.allGranted`).
   - `app/lib/app.dart`: mặc định nối `AndroidMethodChannelAlarmSchedulerService()` khi `defaultTargetPlatform == TargetPlatform.android && !kIsWeb`.
2. **Tầng Android Native (thuần Kotlin + XML, không Hilt, không Compose):**
   - `app/android/app/src/main/AndroidManifest.xml`: khai báo quyền `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`; khai báo `android:exported` tường minh cho `MainActivity`, `AlarmRingActivity`, `AlarmRingService`, `AlarmFireReceiver`, `BootAndTimeReceiver`.
   - `app/android/app/src/main/res/layout/activity_alarm_ring.xml` + `colors.xml` + `strings.xml`: màn hình chuông reo nền đêm `#101A30`, giờ lớn `#F7FAFF`, `Mở câu hỏi`, `Hoãn 5 phút` (ẩn mặc định), `Dừng khẩn cấp`.
   - `app/android/app/src/main/kotlin/com/mindclock/app/`:
     - `AlarmSchedulerBridgeContract.kt`, `NativeAlarmModels.kt` (`AlarmOccurrenceCalculator`), `NativeAlarmStore.kt`.
     - `AlarmRingService.kt` (`FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK`, `AudioAttributes.USAGE_ALARM`, `VibrationEffect`, `ACTION_EMERGENCY_STOP` dọn sạch player/vibrator/notification).
     - `AlarmFireReceiver.kt` (bắt FGS fallback notification nếu OS chặn + tự đặt lại báo thức lặp định kỳ).
     - `BootAndTimeReceiver.kt` (khôi phục lịch trên `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `TIME_CHANGED`, `TIMEZONE_CHANGED`, `ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED` — tuyệt đối không start FGS khi boot).
     - `AlarmRingActivity.kt` (màn khóa native độc lập Flutter; `Hoãn 5 phút` ẩn hoàn toàn ở chế độ thử thách; `Dừng khẩn cấp` dừng thẳng `AlarmRingService`).
     - `AlarmSchedulerImpl.kt` (`AlarmManager.setAlarmClock`, kiểm quyền thật `canScheduleExactAlarms`, `POST_NOTIFICATIONS`, `canUseFullScreenIntent`, mở đúng trang Cài đặt Android).
     - `MainActivity.kt` (gắn `MethodChannel("mindclock/alarm_scheduler")` lên `FlutterActivity`).
3. **UI Flutter & ViewModel:**
   - `guest_workspace_view_model.dart`, `app_strings.dart`, `alarm_ring_screen.dart`, `mindclock_shell_screen.dart`, `today_screen.dart`, `alarm_config_screen.dart`, `me_guest_screen.dart`: đồng bộ quyền khi `AppLifecycleState.resumed`, chỉ báo `Đã sẵn sàng` khi OS xác nhận đủ quyền & đặt lịch, hiện cảnh báo + nút mở đúng màn Cài đặt Android khi thiếu quyền, màn `S07` và thanh `Dừng khẩn cấp` khi vừa nhấn `Mở câu hỏi`.
4. **Tests đã viết (chưa chạy được trên máy dev này):**
   - `app/android/app/src/test/kotlin/com/mindclock/app/AlarmOccurrenceCalculatorTest.kt`
   - `app/test/android_bridge_contract_test.dart`

## 2. Kết quả kiểm tra thực tế

- `where.exe flutter dart` -> chưa cài Flutter/Dart SDK trên máy host.
- `C:\Users\QuangDev\AppData\Local\Android\Sdk\platform-tools\adb.exe devices` -> `List of devices attached` trống (0 máy Android thật hoặc emulator đang chạy).
- Scan tĩnh `Color(0x` trong `app/lib` -> chỉ có trong `app/lib/ui/core/theme/mindclock_theme.dart` (0 vi phạm).
- Scan tĩnh `@HiltAndroidApp|dagger\.hilt|androidx\.compose|InkWell\b|NavigationBar\b` trong `app/android` và `app/lib` -> 0 vi phạm.
- `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` -> xem mục kết quả trong phiên chạy cuối.

## 3. Rủi ro, giới hạn OS & phần chưa xác minh

- **Chưa xác minh trên máy thật (`blocked`):** Toàn bộ `AD01–AD07` (foreground/background/đóng app khỏi recents/màn khóa/offline/quyền từ chối-cấp lại/reboot/đổi giờ & múi giờ/tiết kiệm pin OEM/build Gradle & `flutter test`) **chưa chạy**.
- **Chưa có khung Gradle trong `app/android/`:** hiện `app/android/` chỉ có `app/src/main/**` và `app/src/test/**`; cần chạy `flutter create --platforms=android .` trong `app/` (trên máy có Flutter SDK) để sinh `build.gradle.kts`, `settings.gradle.kts` và `gradle/` wrapper chuẩn mà giữ nguyên toàn bộ `src/main` và `src/test`.
- **Giới hạn OS Android cần phân biệt trong bằng chứng:**
  - *Vuốt đóng app khỏi Recents (`app bị đóng`):* `AlarmManager.setAlarmClock` vẫn đánh thức `AlarmFireReceiver` bình thường (tùy chính sách tiết kiệm pin OEM).
  - *Bấm `Force stop` trong Cài đặt ứng dụng:* Android OS chặn toàn bộ pending alarm và broadcast receiver (kể cả `BOOT_COMPLETED`) cho tới khi người dùng tự mở lại app. Không app thường nào vượt qua được `Force stop`.

## 4. Điểm tiếp tục cụ thể

1. Trên máy có Flutter SDK & Android SDK:
   - Chạy `cd app && flutter create --platforms=android .` (kiểm tra git diff để không ghi đè `AndroidManifest.xml`, `MainActivity.kt` hay `Alarm*` files), rồi `flutter pub get && flutter analyze && flutter test`.
   - Chạy Kotlin unit test (`cd app/android && ./gradlew testDebugUnitTest`) cho `AlarmOccurrenceCalculatorTest`.
2. Cắm điện thoại Android thật (API 33–35 càng tốt), bật USB debugging (`adb devices`), chạy `flutter run --release` (hoặc `--debug`) và điền đủ bằng chứng + logcat vào bảng `AD01–AD07` trong `tasks/T015-noi-bao-thuc-local-android-dung-khan-cap/tests.md`.
3. Chỉ sau khi `flutter test`, `./gradlew testDebugUnitTest` và `AD01–AD07` máy thật đạt hết mới chuyển `T015` từ `blocked` sang `done`.
