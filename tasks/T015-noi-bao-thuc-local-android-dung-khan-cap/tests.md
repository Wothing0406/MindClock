# Kế hoạch và kết quả kiểm thử T015

Viết ca kiểm thử từ `spec.md` trước coding. Điền **lệnh thực và kết quả thực**, không ghi "pass" nếu chưa chạy.

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Gọi `AndroidMethodChannelAlarmSchedulerService` với mock channel (`bridgeVersion: 1`, sai version `99`, và `MissingPluginException`) | Trả typed `AlarmScheduleResult` + mã lỗi `unsupportedVersion` / `bridgeUnbound`; không văng exception ra UI | `flutter test test/android_bridge_contract_test.dart` | Chưa chạy (thiếu Flutter SDK trên máy host) |
| TC-02 | AC-02 | Mock OS cấp đủ quyền & trả `scheduledReady` với `bridgeVersion: 1` | `AlarmConfig.syncStatus == scheduledReady`; `TodayScreen` hiện `Đã sẵn sàng` | `flutter test test/android_bridge_contract_test.dart` | Chưa chạy (thiếu Flutter SDK trên máy host) |
| TC-03 | AC-03 | Từ chối từng quyền `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT` | Trả mã lỗi quyền tương ứng, không hiện `Đã sẵn sàng`, hiện giải thích tiếng Việt + nút mở Settings gọi `openPermissionSettings` | `flutter test` + máy Android thật (`AD04`) | Chưa chạy (thiếu Flutter SDK & máy thật) |
| TC-04 | AC-04 | Đợi báo thức đến giờ ở cả chế độ thường và thử thách (foreground, background, đóng khỏi recents, màn khóa, offline) | `AlarmRingService` phát âm/rung, `AlarmRingActivity` bật nền đêm; chế độ thường có `Hoãn 5 phút`, thử thách ẩn `Hoãn 5 phút` | Máy Android thật (`AD01, AD02, AD03, AD06`) + widget test `AlarmRingScreen` | Chưa chạy (thiếu Flutter SDK & máy thật) |
| TC-05 | AC-05 | Bấm `Dừng khẩn cấp` khi app Flutter chưa khởi động (màn `AlarmRingActivity` native) hoặc trên `AlarmRingScreen` | Âm thanh + rung tắt ngay ≤1s, notification biến mất, không phụ thuộc mạng/Flutter/backend | Máy Android thật (`AD05`) + test unit | Chưa chạy (thiếu Flutter SDK & máy thật) |
| TC-06 | AC-06 | Tính toán mốc kế tiếp qua `AlarmOccurrenceCalculator` cho lặp 1..7 ngày, qua đêm, `TIME_SET`, `TIMEZONE_CHANGED`, `BOOT_COMPLETED` | Lần reo kế tiếp đúng múi giờ mới, không nhân đôi báo thức, không gọi `startForegroundService` từ boot | Kotlin JUnit `AlarmOccurrenceCalculatorTest` + máy thật (`AD07`) | Chưa chạy (thiếu Flutter SDK/Gradle wrapper & máy thật) |
| TC-07 | AC-07 | Bảng thực địa trên thiết bị Android thật (`AD01–AD07` theo `docs/47`) + kiểm tiết kiệm pin + phân biệt app đóng khỏi recents với force-stop | Ghi đủ model máy, Android API level, trạng thái quyền, logcat và kết quả từng ca; force-stop ghi nhận giới hạn OS rõ ràng | Điện thoại Android thật qua `adb` | Chưa chạy (`adb devices` trống) |

## Cổng thiết bị thật (`docs/47` & `docs/09`) — Trạng thái chưa xác minh

| Ca `docs/47` | Điều kiện | Phân biệt `đóng app` vs `force-stop` | Kết quả thiết bị thật |
| --- | --- | --- | --- |
| `AD01` | Foreground & màn hình khóa | App chạy hoặc màn khóa | Chưa xác minh (chưa có máy thật) |
| `AD02` | Vuốt đóng app khỏi Recents vs bấm `Force stop` trong Cài đặt | Vuốt Recents: `AlarmManager` vẫn kích hoạt được (tùy OEM). `Force stop`: Android OS hủy mọi alarm/receiver cho tới khi mở lại app | Chưa xác minh (chưa có máy thật) |
| `AD03` | Tắt Wi-Fi / Dữ liệu di động | Chuông + `Dừng khẩn cấp` vẫn hoạt động 100% local | Chưa xác minh (chưa có máy thật) |
| `AD04` | Từ chối `SCHEDULE_EXACT_ALARM` / `POST_NOTIFICATIONS` / `USE_FULL_SCREEN_INTENT` | Không hiện `Đã sẵn sàng`; mở đúng Settings | Chưa xác minh (chưa có máy thật) |
| `AD05` | Bấm `Dừng khẩn cấp` khi đang reo | Dừng âm/rung tức thì, cả khi Flutter chưa mở | Chưa xác minh (chưa có máy thật) |
| `AD06` | Chế độ thường (`Hoãn 5 phút`) vs Thử thách (không Hoãn) | Thử thách ẩn nút Hoãn | Chưa xác minh (chưa có máy thật) |
| `AD07` | Reboot máy, đổi giờ/múi giờ, bật Tiết kiệm pin OEM | `BootAndTimeReceiver` đặt lại lịch nếu chưa force-stop | Chưa xác minh (chưa có máy thật) |
