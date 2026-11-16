# Nhật ký thực hiện và vòng sửa — T032 (B02)

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 2026-11-16 | Rà soát `AlarmRingService.kt`, `AlarmRingActivity.kt` và `mindclock_shell_screen.dart` đối chiếu `AGENTS.md §3` | Code từ `T015` dùng `ACTION_LOWER_VOLUME` khi bấm `Mở câu` và dùng `VISIBILITY_PUBLIC` hiển thị môn học trên màn khóa | Thêm `LockScreenPrivacyFormatter`, trạng thái `sound_stopped_review_active`, sửa `AlarmRingService.kt`, `AlarmRingActivity.kt`, `mindclock_shell_screen.dart`, `app_strings.dart` và viết `AlarmRingPrivacyAndStateTest.kt` | `flutter analyze` pass; `:app:testDebugUnitTest` pass 9/9 ca | Đạt AC-01..AC-04; giữ `verifying` cho TC-05 (cần 2 máy Android thật) |
