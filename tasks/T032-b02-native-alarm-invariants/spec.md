# Đặc tả nhiệm vụ — T032 (B02: Bất biến báo thức Android native và riêng tư màn khóa)

## Vấn đề và kết quả mong muốn

Khi đối chiếu mã nguồn `app/android/app/src/main/kotlin/com/mindclock/app/` (viết từ `T015`) với nguồn chuẩn hiện hành (`AGENTS.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/02-bao-thuc-android.md`), có 2 điểm lệch nghiêm trọng cần sửa ngay:
1. **Hành vi `Mở câu`:** Trong `AlarmRingActivity.kt` hiện tại, khi bấm `Mở câu` (`openQuestionInMainApp`), app chỉ gửi `ACTION_LOWER_VOLUME` (`setVolume(0.25f, 0.25f)`) khiến âm báo và rung tiếp tục chạy trong lúc học sinh đọc cảnh mở màn và làm bài. Quy tắc bất biến `AGENTS.md §3` và `docs/02-engineering/02-bao-thuc-android.md §§1–2` quy định: bấm `Mở câu` phải **dừng âm/rung cục bộ ngay lập tức** và chuyển sang trạng thái `sound_stopped_review_active` (lượt học chưa hoàn thành, chưa cấp thưởng; `Dừng khẩn cấp` vẫn luôn có để hủy phiên).
2. **Riêng tư màn khóa mặc định (`SLEEP-03`):** `AlarmRingActivity.kt` hiện hiển thị `"${payload.label} • ${payload.subjectCode}"` ngay trên màn khóa, và `AlarmRingService.kt` đặt `Notification.VISIBILITY_PUBLIC` với tiêu đề chứa nhãn/môn học. Quy tắc `AGENTS.md §3` và `docs/01-product/09-giac-ngu-va-bao-thuc.md` quy định: màn khóa mặc định chỉ hiện nội dung trung tính (`Báo thức <HH:mm>` và `Mở để xem kế hoạch hôm nay`), không lộ môn học hay TKB chi tiết khi màn khóa chưa mở (trừ khi người dùng bật tùy chọn hiển thị chi tiết).

## Phạm vi

- **Trong phạm vi:**
  - Thay `ACTION_LOWER_VOLUME` bằng `ACTION_STOP_SOUND_FOR_QUESTION` (vẫn giữ tương thích hằng số cũ nếu có caller) trong `AlarmRingService.kt` và `AlarmRingActivity.kt` để dừng ngay `MediaPlayer` và `Vibrator`, ghi trạng thái `sound_stopped_review_active` vào `NativeAlarmStore` trước khi mở `MainActivity`.
  - Cập nhật `AlarmRingActivity.kt` và `AlarmRingService.kt` dùng helper `LockScreenPrivacyFormatter` để khi màn khóa đang khóa (`isKeyguardLocked == true` và `showLockScreenDetails == false` mặc định) hoặc trong `publicVersion` của notification (`VISIBILITY_PRIVATE`), chỉ hiển thị `"Báo thức ${formattedTime}"` và `"Mở để xem kế hoạch hôm nay"`.
  - Cập nhật `app/lib/ui/core/strings/app_strings.dart` và `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart` để khi bấm `Mở câu` từ `AlarmRingScreen` cũng gọi dừng âm/rung cục bộ và hiển thị đúng thông báo trạng thái `Đã dừng chuông · Hoàn thành câu ôn để nhận thưởng`.
  - Bổ sung unit test Kotlin `AlarmRingPrivacyAndStateTest.kt` kiểm chứng formatter riêng tư màn khóa và máy trạng thái `ringing -> sound_stopped_review_active -> dismissed`.
- **Ngoài phạm vi:**
  - Kiểm thử vật lý AD01–AD07 trên 2 thiết bị Android thật (cần cắm máy qua ADB; giữ trạng thái `verifying` cho cổng thiết bị thật).
- **Dữ liệu/role/quyền liên quan:**
  - Bảo vệ quyền riêng tư học sinh trên màn hình khóa (`SLEEP-03`) và an toàn dừng âm báo thức (`AD05`, `MORNING-01`).
- **Tài liệu chuẩn:**
  - `AGENTS.md §3, §5`
  - `docs/01-product/09-giac-ngu-va-bao-thuc.md` (`SLEEP-03`, `MORNING-01`)
  - `docs/02-engineering/02-bao-thuc-android.md §§1–3`
  - `.agents/skills/mindclock-android-native/SKILL.md`

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi màn hình đang khóa (`isKeyguardLocked == true`) và chưa bật tùy chọn hiện chi tiết trên màn khóa | Tiêu đề và phụ đề trên màn khóa / `publicVersion` notification chỉ hiện `"Báo thức <HH:mm>"` và `"Mở để xem kế hoạch hôm nay"`, tuyệt đối không chứa `subjectCode` hay nhãn TKB riêng | TC-01 |
| AC-02 | Khi màn hình đã mở khóa (`isKeyguardLocked == false`) hoặc người dùng chủ động bật hiển thị chi tiết | Hiển thị đầy đủ nhãn báo thức và môn học (`"${label} • ${subjectCode}"`) | TC-02 |
| AC-03 | Khi người dùng bấm `Mở câu` trên `AlarmRingActivity` hoặc `AlarmRingScreen` | Native `AlarmRingService` dừng ngay âm thanh và rung, chuyển trạng thái phiên chuông sang `sound_stopped_review_active`, lưu `pendingRingLaunch` để Flutter mở câu ôn mà chưa cộng EXP | TC-03 |
| AC-04 | Khi chạy `flutter analyze` và `gradlew.bat :app:testDebugUnitTest` + `:app:assembleDebug` | Pass 100% (cả 3 file test Kotlin và APK debug mới) | TC-04 |

## Hợp đồng và trường hợp biên

- `Dừng khẩn cấp` (`ACTION_EMERGENCY_STOP`) vẫn luôn xóa `activeRingPayload`, `pendingRingLaunch` và dừng hoàn toàn `AlarmRingService` ngay một chạm ở cả trạng thái `ringing` lẫn `sound_stopped_review_active`.
- Mode thử thách (`challenge`) vẫn ẩn hoàn toàn nút `Hoãn 5 phút` (`AD06`).

## Quyết định/mâu thuẫn

- Sửa code `T015` cũ (`ACTION_LOWER_VOLUME` và `VISIBILITY_PUBLIC` lộ môn) theo đúng quy tắc ưu tiên ở `AGENTS.md §2`: `AGENTS.md` và docs canonical (`02-bao-thuc-android.md`, `09-giac-ngu-va-bao-thuc.md`) thắng code cũ.
