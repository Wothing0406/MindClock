# Kế hoạch thực hiện T055

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Crop sạch & xuất `app/assets/avatars/avatar_sunrise.png`, khai báo `assets/avatars/` trong `app/pubspec.yaml` | Ảnh rõ nét không viền trắng thừa | [x] |
| 2 | Thêm `MediaPickerGateway` + `MethodChannelMediaPickerGateway` (`mindclock/media_picker`) + `customAvatarPath` (`StudyProfile`) + `AlarmSoundOption.customLocal`/`customSoundPath`/`customSoundLabel` (`AlarmConfig`) + truyền tự động qua `alarm.toJson()` trong `AndroidMethodChannelAlarmSchedulerService` | `flutter analyze` 0 lỗi | [x] |
| 3 | Tạo `MediaPickerBridgeHandler.kt` & cập nhật Kotlin native (`MainActivity.kt`, `NativeAlarmModels.kt`, `AlarmSchedulerImpl.kt`, `AlarmFireReceiver.kt`, `AlarmRingService.kt`, `AlarmSoundResolverTest.kt`) hỗ trợ `ACTION_OPEN_DOCUMENT` (image/audio copy nội bộ app) + fallback an toàn khi file nhạc tùy chỉnh lỗi/bị xóa + nghe thử âm thanh | `./gradlew testDebugUnitTest` PASS | [x] |
| 4 | Cập nhật UI (`MindClockAvatarView`, `OnboardingSetupScreen`, `MeGuestScreen`, `TodayScreen`, `AlarmConfigScreen`, `StudySpaceScreen`, `MindClockShellScreen`, `app.dart`), viết `app/test/custom_avatar_and_audio_picker_test.dart`, chạy full `flutter test` + Gradle unit test + docs check | 100% PASS, sẵn sàng commit & push `origin/main` | [x] |
