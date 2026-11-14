# Bàn giao T020

- **Trạng thái:** `blocked` (đã thêm asset Android `res/raw/alarm_bermuda.mp3`, lựa chọn UI/domain `AlarmSoundOption.bermudaAlarm`, mapping trong `AlarmRingService.kt` và unit test; chưa chạy test biên dịch/phát loa thực tế vì máy host không có Flutter/Android Gradle SDK).

## Chức năng — Chạy thật hay mẫu — Bằng chứng

- File MP3 đóng gói trong APK: `app/android/app/src/main/res/raw/alarm_bermuda.mp3` (`313,344` bytes, copy từ `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3`).
- Lựa chọn giao diện & lưu trữ local: `AlarmSoundOption.bermudaAlarm` (`id = 'bermuda_alarm'`, nhãn `'Nhạc chuông Bermuda'`) trong `app/lib/domain/models/alarm_config.dart`, tự động hiển thị thành chip chọn trên `AlarmConfigScreen` và nhãn trên `TodayScreen`, kiểm bởi unit test thêm vào `app/test/domain_and_persistence_test.dart` (`SND-TC-01`, chưa chạy do thiếu Flutter SDK).
- Phát âm thanh native Android offline: `AlarmRingService.resolveSoundTarget` + `resolveSoundUri` phát `android.resource://$packageName/${R.raw.alarm_bermuda}` qua `MediaPlayer` với `USAGE_ALARM`, có fallback sang chuông hệ thống mặc định nếu đọc raw lỗi, và vẫn dừng ngay qua `ACTION_EMERGENCY_STOP`. Đã thêm `AlarmSoundResolverTest.kt` (`SND-TC-02`, chưa chạy do thiếu Gradle/Android SDK).

## Điểm tiếp tục cụ thể

1. Trên máy có Flutter & Android SDK:
   - Chạy `flutter test test/domain_and_persistence_test.dart` trong `app/`.
   - Chạy unit test Android (`./gradlew testDebugUnitTest` trong `app/android` hoặc `flutter build apk --debug`).
2. Trên máy Android thật: chọn `Nhạc chuông Bermuda`, khóa màn hình, xác nhận nhạc chuông MP3 phát khi tới giờ và dừng ngay khi bấm `Dừng khẩn cấp`.
