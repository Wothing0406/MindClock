# Nhật ký thực hiện T020

## 2026-11-14

- Tiếp nhận file nhạc chuông `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3` (`313,344` bytes).
- Lập hồ sơ `T020-nhac-chuong-mp3-va-lua-chon-am-bao` trước khi chỉnh mã nguồn và tài nguyên Android.
- Sao chép MP3 sang `app/android/app/src/main/res/raw/alarm_bermuda.mp3` (`313,344` bytes).
- Thêm `AlarmSoundOption.bermudaAlarm('bermuda_alarm', 'Nhạc chuông Bermuda')` vào `app/lib/domain/models/alarm_config.dart`; `AlarmConfigScreen` và `TodayScreen` tự render từ `AlarmSoundOption.values` và `soundOption.labelVi`.
- Cập nhật `AlarmRingService.kt`: tách `resolveSoundTarget(soundEnabled, soundOption)`, ánh xạ `bermuda_alarm` tới `android.resource://$packageName/${R.raw.alarm_bermuda}` với `AudioAttributes.USAGE_ALARM` và fallback về chuông OS mặc định nếu phát raw resource thất bại.
- Bổ sung unit test ở `app/test/domain_and_persistence_test.dart` và `app/android/app/src/test/kotlin/com/mindclock/app/AlarmSoundResolverTest.kt`.
- Gắn trạng thái `blocked` do môi trường thiếu Flutter/Gradle/Android SDK để biên dịch, chạy unit test và kiểm chứng loa trên thiết bị thật.
