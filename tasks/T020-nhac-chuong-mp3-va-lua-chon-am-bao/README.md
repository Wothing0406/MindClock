# T020 — Thêm nhạc chuông MP3 tùy chọn cho báo thức (Bermuda Alarm)

- **Trạng thái:** `blocked`
- **Mục tiêu:** đưa file nhạc chuông `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3` thành 1 lựa chọn âm báo hợp lệ cho người dùng trên màn cấu hình báo thức Flutter (`AlarmSoundOption.bermudaAlarm`) và phát đúng âm thanh đó trên dịch vụ báo thức native Android (`AlarmRingService`), đồng thời bảo đảm fallback an toàn sang chuông mặc định OS nếu tài nguyên lỗi và không làm gãy `Dừng khẩn cấp`.
- **Nguồn yêu cầu:** yêu cầu người dùng ngày 14/11/2026: `"C:\Users\QuangDev\Downloads\Projects\web\MindClock\mp3" đây là thư mục nhạc chuông thêm trước 1 lựa chọn cho user`.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `app/android/app/src/main/res/raw/alarm_bermuda.mp3`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt`, `app/lib/domain/models/alarm_config.dart`, `app/test/domain_and_persistence_test.dart`, `app/android/app/src/test/kotlin/com/mindclock/app/AlarmSoundResolverTest.kt`, `tasks/T020-nhac-chuong-mp3-va-lua-chon-am-bao/*`.
- **Liên quan:** kế thừa `T014` (cấu hình báo thức) và `T015` (cầu nối Android native & `AlarmRingService`).
- **Source refs đã đọc:** `docs/30-ngon-ngu-va-tai-san-giao-dien.md`, `docs/31-bao-thuc-thu-thach.md`, `.agents/skills/mindclock-android-native/SKILL.md`, `app/lib/domain/models/alarm_config.dart`, `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmFireReceiver.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmSchedulerImpl.kt`.
- **Điểm tiếp tục:** hoàn tất copy asset vào `res/raw/`, nối enum Dart + resolver Kotlin + unit test; báo trạng thái kiểm chứng trung thực vì máy không có Flutter/Android Gradle SDK để chạy runtime hay test trên thiết bị thật.

## Cổng trước coding

- [x] Đã đọc code `AlarmSoundOption`, `AlarmConfigScreen`, `AlarmSchedulerImpl`, `AlarmFireReceiver`, `AlarmRingService` và skill `mindclock-android-native`.
- [x] Xác định quy tắc đặt tên Android `res/raw` (`[a-z0-9_]+` -> `alarm_bermuda.mp3`) và chuẩn ngôn ngữ `docs/30` (không emoji, nhãn tiếng Việt rõ ràng `Nhạc chuông Bermuda`).
- [x] Đã lập `spec.md`, `plan.md`, `tests.md` trước khi sửa code.

## Cổng kết thúc

- [ ] `flutter test` & Gradle Kotlin unit test pass (chưa chạy được do máy thiếu Flutter/Android SDK).
- [ ] Kiểm thử phát âm thanh `bermuda_alarm` và `Dừng khẩn cấp` trên máy Android thật (kể cả khi màn khóa/offline).
