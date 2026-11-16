# Kế hoạch thực hiện — T032 (B02)

## Điểm bắt đầu

- Code hiện tại: `AlarmRingService.kt`, `AlarmRingActivity.kt`, `NativeAlarmModels.kt`, `mindclock_shell_screen.dart`, `app_strings.dart`.
- Hiện trạng: `Mở câu` đang hạ âm lượng thay vì dừng âm/rung; màn khóa đang hiện thẳng `label • subjectCode`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Thêm `LockScreenPrivacyFormatter` và trạng thái `STATE_RINGING` / `STATE_SOUND_STOPPED_REVIEW_ACTIVE` vào `NativeAlarmModels.kt` | Model hỗ trợ kiểm tra riêng tư màn khóa và trạng thái dừng âm khi mở câu | [x] |
| 2 | Cập nhật `AlarmRingService.kt` và `AlarmRingActivity.kt`: dừng âm/rung khi bấm `Mở câu`, dùng `VISIBILITY_PRIVATE` + `publicVersion` trung tính và ẩn môn/nhãn khi `isKeyguardLocked` | Đạt AC-01, AC-02, AC-03 ở tầng Kotlin | [x] |
| 3 | Cập nhật `app_strings.dart` và `mindclock_shell_screen.dart` để đồng bộ câu chữ và trạng thái khi bấm `Mở câu` từ Flutter | Đạt AC-03 ở tầng Flutter | [x] |
| 4 | Viết `AlarmRingPrivacyAndStateTest.kt`, chạy `flutter analyze`, `gradlew.bat :app:testDebugUnitTest` và cập nhật docs/handoff | Tất cả unit test Kotlin (9/9) và `flutter analyze` pass | [x] |

## Rủi ro và đường lui

- **Rủi ro:** Khi dừng âm/rung ở bước `Mở câu`, nếu user thoát ngang hoặc muốn bấm `Dừng khẩn cấp` trong lúc đang xem câu thì nút `Dừng khẩn cấp` trong Flutter vẫn phải gọi `triggerEmergencyStop` để xóa trạng thái phiên chuông.
- **Đường lui:** Giữ nguyên banner `Dừng khẩn cấp` trên `MindClockShellScreen` trong suốt thời gian `_activeAlarmPlayingInQuestion == true`.
