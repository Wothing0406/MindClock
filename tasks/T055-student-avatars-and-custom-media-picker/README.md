# T055 — Avatar Học Sinh Minh Họa & Chọn Avatar Ảnh / Nhạc Chuông Cục Bộ Từ Máy

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. Đóng gói ảnh đại diện gốc `app/assets/avatars/avatar_sunrise.png` + tận dụng bộ chân dung gốc `app/assets/arena/champ_*.png` làm avatar minh họa chọn sẵn cho học sinh (vẫn giữ tương thích 4 key cũ `sunrise`, `book`, `clock`, `user`), dùng widget thống nhất `MindClockAvatarView` ở Onboarding, Today và Tôi.
  2. Thêm **`MediaPickerGateway`** (`app/lib/domain/services/media_picker_gateway.dart` + `MethodChannelMediaPickerGateway` nối kênh Android `mindclock/media_picker` trong `MainActivity.kt` và `MediaPickerBridgeHandler.kt` bằng `ACTION_OPEN_DOCUMENT`, copy an toàn vào thư mục riêng `filesDir/avatars/` hoặc `filesDir/sounds/` không cần xin quyền bộ nhớ diện rộng).
  3. Hỗ trợ **chọn & hiển thị ảnh Avatar tùy chỉnh từ máy** ở `OnboardingSetupScreen`, `MeGuestScreen`, `TodayScreen` và `StudyProfile` (`customAvatarPath`), chỉ lưu cục bộ trên máy, có fallback sạch về icon vector/ảnh mẫu khi tệp không tồn tại.
  4. Hỗ trợ **chọn & nghe thử file nhạc chuông / âm thanh từ máy (`.mp3`, `.m4a`, `.wav`, `.ogg`)** cho báo thức (`AlarmSoundOption.customLocal`, `customSoundPath`, `customSoundLabel` trong `AlarmConfig` + `AlarmConfigScreen`) và nối xuống `AlarmSchedulerImpl.kt`, `NativeAlarmModels.kt`, `AlarmFireReceiver.kt`, `AlarmRingService.kt` — **bắt buộc có fallback an toàn** về `BUNDLED_BERMUDA`/`SYSTEM_DEFAULT` nếu file tùy chỉnh bị xóa/hỏng.
  5. Bổ sung **tùy chọn nhạc nền từ máy (mặc định tắt)** trong `StudySpaceScreen` cho chế độ `Học ngắt quãng`, **tắt và khóa cứng ở `Học sâu (im lặng)`**.
- **Nguồn yêu cầu:** Yêu cầu người dùng 2026-11-18; `AGENTS.md §3, §4, §5`; `.agents/skills/mindclock-android-native/SKILL.md`; `docs/01-product/08-phong-hoc-ai-va-ban-be.md`; `docs/02-engineering/02-bao-thuc-android.md`.
- **Chủ sở hữu/reviewer:** Senior Android & Flutter Systems Architect.
- **Phạm vi file đã chạm:**
  - `app/assets/avatars/avatar_sunrise.png`, `app/assets/avatars/manifest.json`, `app/pubspec.yaml`
  - `app/lib/app.dart`
  - `app/lib/domain/models/study_profile.dart`
  - `app/lib/domain/models/alarm_config.dart`
  - `app/lib/domain/services/media_picker_gateway.dart`
  - `app/lib/data/services/method_channel_media_picker_gateway.dart`
  - `app/lib/ui/core/widgets/mindclock_avatar_view.dart`
  - `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart`
  - `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/android/app/src/main/kotlin/com/mindclock/app/MediaPickerBridgeHandler.kt`
  - `app/android/app/src/main/kotlin/com/mindclock/app/MainActivity.kt`
  - `app/android/app/src/main/kotlin/com/mindclock/app/NativeAlarmModels.kt`
  - `app/android/app/src/main/kotlin/com/mindclock/app/AlarmSchedulerImpl.kt`
  - `app/android/app/src/main/kotlin/com/mindclock/app/AlarmFireReceiver.kt`
  - `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt`
  - `app/android/app/src/test/kotlin/com/mindclock/app/AlarmSoundResolverTest.kt`
  - `app/test/custom_avatar_and_audio_picker_test.dart`
  - `docs/00-start/01-hien-trang.md`, `tasks/T055-student-avatars-and-custom-media-picker/*`
- **Source refs đã đọc:** `.agents/skills/mindclock-android-native/SKILL.md`, `AlarmRingService.kt`, `NativeAlarmModels.kt`, `AlarmSchedulerImpl.kt`, `AlarmFireReceiver.kt`, `MainActivity.kt`, `AlarmSoundResolverTest.kt`, `onboarding_setup_screen.dart`, `alarm_config_screen.dart`, `study_space_screen.dart`.
- **Điểm tiếp tục:** Đã xong kiểm thử dev (Flutter 82/82 + Gradle 10/10); bước kiểm tra còn thiếu ngoài T055 là chạy thử trên 2 máy Android thật.

## Cổng trước coding

- [x] Đọc `mindclock-android-native/SKILL.md` và mã Kotlin/Dart hiện tại.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-05).
- [x] `plan.md`, `tests.md`, `handoff.md` cập nhật với kết quả Gradle + Flutter test thật.
