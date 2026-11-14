# T018 — Không gian học local (Nhiệm vụ 6A)

- **Trạng thái:** `blocked`
- **Mục tiêu:** xây dựng luồng Không gian học cục bộ (`chọn việc → chọn thời lượng → bắt đầu → tạm nghỉ/tiếp tục → kết thúc`), timer tính bằng mốc thời gian có khôi phục sau kill/reboot, 3 mức `Linh hoạt` / `Tập trung thường` / `Cam kết`, hướng dẫn Digital Wellbeing trung thực và cầu nối Android lifecycle/nhắc cục bộ không ảnh hưởng báo thức; phủ test `F01–F03`, `F07–F09` và UI accessibility.
- **Nguồn yêu cầu:** Nhiệm vụ 6A (`docs/45 §§1–6`); ngày 14/11/2026.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `app/lib/domain/**`, `app/lib/data/**`, `app/lib/ui/**`, `app/lib/app.dart`, `app/android/app/src/main/kotlin/com/mindclock/app/**`, `app/android/app/src/main/AndroidManifest.xml`, `app/test/study_focus_local_test.dart`, `tasks/T018-khong-gian-hoc-local/*`.
- **Liên quan:** giữ độc lập tuyệt đối với báo thức local (`T015`) và tách scope tài khoản tương thích luồng cá nhân (`T017`). Camera, micro và AI trợ lý học **chưa thuộc task này**.
- **Source refs đã đọc:** `docs/45 §§1–6`, `docs/05`, `docs/13`, `docs/27`, `docs/30`, `AGENTS.md`, `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md`, `.agents/skills/mindclock-android-native/SKILL.md`, `app/lib/app.dart`, `app/lib/ui/features/guest_shell/views/today_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/ui/core/widgets/mindclock_icon.dart`, `app/android/app/src/main/kotlin/com/mindclock/app/MainActivity.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt`.
- **Điểm tiếp tục:** cài Flutter SDK + Android SDK/emulator hoặc máy thật để chạy `cd app && flutter analyze && flutter test test/study_focus_local_test.dart`, sau đó kiểm thử tay trên thiết bị Android thật (`F01–F03`, `F07–F09` + báo thức độc lập) trước khi gỡ `blocked`.

## Cổng trước coding

- [x] Đã đọc đầy đủ `docs/45 §§1–6`, `AGENTS.md`, `tasks/README.md`, hai skill `flutter-apply-architecture-best-practices` và `mindclock-android-native` cùng mã nguồn Flutter/Android hiện tại.
- [x] Đã kiểm tra ranh giới với `docs/45`: phát hiện và sửa thiếu enum `MindClockIconKind.warning` trong `app/lib/ui/core/widgets/mindclock_icon.dart` cùng bộ icon `play`/`pause`/`stop`.
- [x] `spec.md`, `plan.md`, `tests.md` điền đầy đủ.

## Cổng kết thúc

- [ ] Toàn bộ `SF-TC-01..08` trong `app/test/study_focus_local_test.dart` chạy pass với Flutter SDK (`flutter analyze && flutter test`).
- [ ] Đã xác minh thực tế trên máy Android thật (lock screen, rời app 5s/11s/31s, kill app/reboot, Digital Wellbeing có/không có trên OEM, TalkBack/chữ 200%, báo thức độc lập vẫn reo).
