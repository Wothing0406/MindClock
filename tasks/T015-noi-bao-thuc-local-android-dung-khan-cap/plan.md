# Kế hoạch thực hiện T015

## Điểm bắt đầu

- Đã có `app/` (`T014`), `AlarmSchedulerService` interface và `AlarmSchedulerBridgeContract.kt`.
- Máy dev có `Android Studio` và `adb.exe`, chưa cài `flutter` SDK và chưa có điện thoại Android thật kết nối (`adb devices` trống).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T015-noi-bao-thuc-local-android-dung-khan-cap/` (`README.md`, `spec.md`, `plan.md`, `tests.md`, `worklog.md`, `handoff.md`) | Đủ cổng trước coding | [x] |
| 2 | Cập nhật `AlarmSchedulerService` (`bridgeVersion`, `AlarmBridgeErrorCode`, `triggerEmergencyStop`, `snoozeAlarm`, `openPermissionSettings`, `consumePendingRingLaunch`) & viết `AndroidMethodChannelAlarmSchedulerService` + `app.dart` | Typed outcomes, fallback an toàn khi thiếu plugin channel | [x] |
| 3 | Viết Android Native Kotlin & XML (`AndroidManifest.xml`, `activity_alarm_ring.xml`, `AlarmOccurrenceCalculator`, `NativeAlarmStore`, `AlarmSchedulerImpl`, `AlarmRingService`, `AlarmFireReceiver`, `BootAndTimeReceiver`, `AlarmRingActivity`, `MainActivity`) không dùng Hilt/Compose | Đủ luồng lập lịch, phát/dừng/hoãn, reboot/timezone, lock-screen `Dừng khẩn cấp` độc lập Flutter | [x] |
| 4 | Cập nhật UI Flutter: `AlarmRingScreen` (`S07` nền đêm, chế độ thường có `Hoãn 5 phút`, thử thách không Hoãn, `Dừng khẩn cấp`), cảnh báo/mở Cài đặt quyền bị từ chối và chỉ báo `Đã sẵn sàng` khi `scheduledReady` thật | Khớp `MindClockTheme`, ≥48 dp, `vi-VN` | [x] |
| 5 | Viết JUnit tests (`AlarmOccurrenceCalculatorTest.kt`) & Dart mock-MethodChannel/widget tests (`android_bridge_contract_test.dart`) | Đầy đủ test cho `TC-01..TC-06` | [x] |
| 6 | Chạy các check tĩnh khả dụng (`check_docs_links.py`, `check_task_records.py`, static grep Hilt/Compose/token), kiểm tra `adb devices`; ghi rõ trạng thái `blocked` (`chưa xác minh` thiết bị thật), commit và push `origin/main` | Trung thực 100%, không gắn `done` khi thiếu máy thật & Flutter SDK | [x] |

## Rủi ro và đường lui

- **Rủi ro thiếu Flutter SDK & máy Android thật:** chưa biên dịch Gradle/APK và chưa chứng minh `AD01–AD07` trên thiết bị thật. **Đường lui:** giữ `T015` ở trạng thái `blocked` (`chưa xác minh`), lập sẵn checklist chi tiết `AD01–AD07` (kèm phân biệt app đóng vs force-stop) trong `tests.md` và `handoff.md`.
- **Rủi ro `AndroidManifest` / `Activity` thiếu `android:exported` hoặc gọi FGS sai ngữ cảnh trên Android 14/15:** kiểm tường minh từng receiver/service/activity `exported` và tuyệt đối không start FGS trong `BootAndTimeReceiver`.
