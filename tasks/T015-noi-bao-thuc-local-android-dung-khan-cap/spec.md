# Đặc tả nhiệm vụ T015 — Nối Flutter với báo thức local Android & Dừng khẩn cấp

## Vấn đề và kết quả mong muốn

Ở `T014`, ứng dụng Flutter đã có cấu hình báo thức và interface `AlarmSchedulerService` chưa nối OS (`"Đã lưu cấu hình"`). Nhiệm vụ `T015` nối hoàn chỉnh với hệ thống báo thức local Android bằng Kotlin thuần (không thêm Hilt hoặc Jetpack Compose) và bổ sung UI chuông đang reo `S07`:
1. Bridge `mindclock/alarm_scheduler` có `bridgeVersion = 1`, trả về kết quả typed (`AlarmScheduleResult`, `AlarmPermissionSnapshot`) và mã lỗi ổn định (`AlarmBridgeErrorCode`).
2. Android native thực hiện lập lịch (`AlarmManager.setAlarmClock` + `PendingIntent` idempotent theo ID báo thức), phát âm thanh (`MediaPlayer` / `AudioAttributes.USAGE_ALARM` + `VibrationEffect` trong `AlarmRingService` type `mediaPlayback`), hủy lịch, hoãn 5 phút (chỉ mode thường) và `Dừng khẩn cấp` tức thì.
3. **`Dừng khẩn cấp` độc lập với Flutter & backend:** `AlarmRingActivity` (native Views nền đêm) tự hiển thị trên màn hình khóa; bấm `Dừng khẩn cấp` dừng ngay `AlarmRingService` và đóng chuông mà không cần Flutter engine hay mạng.
4. UI chuông đang reo nền đêm (`#101A30`): giờ lớn, tên môn/nhãn, nút `Mở câu hỏi`, nút `Dừng khẩn cấp`, nút `Hoãn 5 phút` **chỉ hiện ở chế độ thường** và ẩn ở chế độ thử thách.
5. Khi quyền OS bị từ chối (`SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`), app giải thích rõ nguyên nhân và mở đúng màn Cài đặt Android tương ứng; **chỉ hiển thị `Đã sẵn sàng`** khi OS xác nhận lập lịch thành công.
6. Khi reboot (`BOOT_COMPLETED`), cập nhật app (`MY_PACKAGE_REPLACED`), đổi giờ (`TIME_SET`), đổi múi giờ (`TIMEZONE_CHANGED`) hoặc đổi quyền (`ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED`), receiver đọc cấu hình từ native `SharedPreferences`, tính lại lần reo kế tiếp theo giờ địa phương và đặt lại `AlarmManager` (không khởi động `mediaPlayback` foreground service từ boot).

## Phạm vi

- **Trong phạm vi:** `app/android/app/src/main/AndroidManifest.xml`, layout/strings XML thuần (`activity_alarm_ring.xml`), Kotlin classes & unit tests (`AlarmOccurrenceCalculatorTest.kt`), mở rộng `AlarmSchedulerService` với `AndroidMethodChannelAlarmSchedulerService`, màn `S07` Flutter (`AlarmRingScreen`) + UI giải thích quyền bị từ chối & badge `Đã sẵn sàng` có điều kiện, unit/contract widget tests (`app/test/android_bridge_contract_test.dart`).
- **Ngoài phạm vi:** chấm bài AI/Gemini, Firebase Auth, PvP/Đấu trường, iOS AlarmKit, tự động cài Flutter SDK.
- **Tài liệu chuẩn:** `docs/06 §§1–3`, `docs/09 §§1–3`, `docs/31 §§1–7`, `docs/47 §§1–4`, `.agents/skills/mindclock-android-native/SKILL.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi Flutter gọi `AlarmSchedulerService` qua `MethodChannel` | Gửi/nhận `bridgeVersion = 1`, kết quả typed (`AlarmScheduleResult`) và `AlarmBridgeErrorCode` ổn định (cả khi sai version hoặc `MissingPluginException`) | `TC-01` |
| AC-02 | Khi OS cấp đủ quyền và `AlarmManager` lập lịch thành công | Native lưu lịch vào `SharedPreferences`, gọi `setAlarmClock()`, trả `scheduledReady` → UI hiển thị `Đã sẵn sàng` | `TC-02` |
| AC-03 | Khi bị từ chối `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` hoặc `USE_FULL_SCREEN_INTENT` | Trả mã lỗi cụ thể (`permissionExactAlarmDenied` / `permissionNotificationDenied` / `permissionFullScreenDenied`), không báo `Đã sẵn sàng`, hiển thị giải thích tiếng Việt và nút mở Cài đặt hệ thống | `TC-03` |
| AC-04 | Khi đến giờ reo (kể cả app đóng/màn khóa/offline/Flutter chưa mở) | `AlarmFireReceiver` chạy `AlarmRingService` (`mediaPlayback`) phát âm/rung và bật `AlarmRingActivity` nền đêm (`Mở câu hỏi`, `Dừng khẩn cấp`, `Hoãn 5 phút` chỉ cho mode thường); nếu Android 14+ chặn FGS hoặc thiếu full-screen thì fallback notification | `TC-04` |
| AC-05 | Khi bấm `Dừng khẩn cấp` ở `AlarmRingActivity` hoặc `AlarmRingScreen` | Âm/rung dừng ngay lập tức tại local, không gọi mạng/Flutter/backend; lưu trạng thái `dismissed` cục bộ | `TC-05` |
| AC-06 | Khi reboot, đổi giờ hoặc đổi múi giờ | `BootAndTimeReceiver` tính lại mốc kế tiếp theo giờ địa phương bằng `AlarmOccurrenceCalculator`, hủy intent cũ và đặt lại `AlarmManager` không trùng | `TC-06` |
| AC-07 | Kiểm trên thiết bị Android thật theo `docs/47` (`AD01–AD07`) | Có bằng chứng log/ảnh cho foreground, background, đóng khỏi recents, màn khóa, offline, từ chối quyền, reboot, tiết kiệm pin; phân biệt rõ app bị đóng vs OS force-stop | `TC-07` |

## Hợp đồng và trường hợp biên

- **Giới hạn OS (`Force-stop`):** khi người dùng tự bấm `Force stop` (`Buộc dừng`) trong Cài đặt Android, hệ điều hành hủy toàn bộ alarm đã đặt và chặn mọi BroadcastReceiver (kể cả `BOOT_COMPLETED` / `AlarmManager`) cho tới khi người dùng tự mở lại app. Phải phân biệt rõ `swipe khỏi recents` (app bị đóng bình thường, alarm vẫn chạy được tùy OEM) với `force-stop` trong tài liệu & kiểm thử.
- **Android 14/15:** không gọi `startForegroundService(..., mediaPlayback)` từ `BOOT_COMPLETED`; chỉ gọi khi `AlarmFireReceiver` được kích hoạt từ `AlarmManager` và có `try/catch` fallback sang Notification.
