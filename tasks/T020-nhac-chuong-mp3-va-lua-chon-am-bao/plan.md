# Kế hoạch thực hiện T020

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Lập hồ sơ `T020` và kiểm tra luồng `soundOption` xuyên suốt Dart → MethodChannel → Android Service | Rõ phạm vi và hợp đồng tên tài nguyên | [x] |
| 2 | Copy `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3` sang `app/android/app/src/main/res/raw/alarm_bermuda.mp3` | Đúng quy tắc tên `[a-z0-9_]` của Android `res/raw` | [x] |
| 3 | Thêm `AlarmSoundOption.bermudaAlarm` (`'bermuda_alarm'`, `'Nhạc chuông Bermuda'`) trong `app/lib/domain/models/alarm_config.dart` | UI `AlarmConfigScreen` & `TodayScreen` hiển thị và lưu chọn mới | [x] |
| 4 | Cập nhật `AlarmRingService.kt` để chọn đúng URI theo `soundOption` (phát `R.raw.alarm_bermuda` cho `bermuda_alarm`, fallback OS default nếu lỗi) | `MediaPlayer` dùng `USAGE_ALARM`, `Dừng khẩn cấp` vẫn tắt ngay | [x] |
| 5 | Bổ sung unit test cho `AlarmSoundOption.fromId('bermuda_alarm')` (Dart) và resolver URI (Kotlin); chạy static check & cập nhật `handoff.md` | Báo cáo trung thực phần chưa chạy được do thiếu SDK | [x] |
