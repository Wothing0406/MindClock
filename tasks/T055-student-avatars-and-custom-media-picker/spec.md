# Đặc tả kiểm nhận T055

| ID | Tiêu chí chấp nhận | Cách kiểm |
| --- | --- | --- |
| AC-01 | `app/assets/avatars/avatar_sunrise.png` được xử lý sạch viền, đóng gói trong `app/pubspec.yaml`; `OnboardingSetupScreen` và `MeGuestScreen` hiển thị avatar minh họa (`sunrise`, 3 chân dung tướng MindClock) cùng nút chọn ảnh avatar từ máy (`pick-custom-avatar-btn`) và nút xóa về mặc định (`clear-custom-avatar-btn`). | Widget test `custom_avatar_and_audio_picker_test.dart` + `rootBundle.load`. |
| AC-02 | `AlarmSoundOption` có tùy chọn `customLocal`; `AlarmConfig` lưu/serialize `customSoundPath` & `customSoundLabel`; `AlarmConfigScreen` cho phép chọn file nhạc từ máy (`pick-custom-alarm-audio-btn`) và nghe thử (`preview-alarm-audio-btn`) khi có bridge. | Widget/unit test `custom_avatar_and_audio_picker_test.dart`. |
| AC-03 | Android native (`MainActivity.kt`, `NativeAlarmModels.kt`, `AlarmSchedulerImpl.kt`, `AlarmFireReceiver.kt`, `AlarmRingService.kt`) truyền & phát `customSoundPath`; nếu `custom_local` thiếu/lỗi file thì `resolveSoundTarget` + `startAlarmSound` **fallback an toàn** về `SYSTEM_DEFAULT`/`BUNDLED_BERMUDA`, tuyệt đối không làm im lặng báo thức. | Kotlin unit test `AlarmSoundResolverTest.kt` (`./gradlew testDebugUnitTest`). |
| AC-04 | `MediaPickerGateway` xử lý từ chối/hủy chọn tệp hoặc thiếu bridge Android (`MissingPluginException`) an toàn bằng thông báo tiếng Việt, không crash app hay hỏng báo thức. | Flutter unit/widget test `custom_avatar_and_audio_picker_test.dart`. |
| AC-05 | `flutter analyze --no-pub`, full `flutter test`, Kotlin `./gradlew testDebugUnitTest`, `RAW_COLOR_HITS: 0`, `check_docs_links.py`, `check_task_records.py` PASS 100%, commit sạch & push `origin/main`. | Chạy tất cả bộ kiểm thử sau sửa cuối. |
