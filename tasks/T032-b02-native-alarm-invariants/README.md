# T032 — B02: Chuẩn hóa bất biến báo thức Android native (`Mở câu` dừng âm/rung, màn khóa riêng tư mặc định)

- **Trạng thái:** `verifying`
- **Mục tiêu:** Sửa `AlarmRingService.kt`, `AlarmRingActivity.kt`, `NativeAlarmModels.kt` và Flutter `AlarmRingScreen` / `MindClockShellScreen` để tuân thủ bất biến `AGENTS.md §3` và `docs/02-engineering/02-bao-thuc-android.md`: (1) bấm `Mở câu` chuyển sang trạng thái `sound_stopped_review_active` dừng ngay âm thanh và rung cục bộ trước khi mở cảnh/câu ôn (nhưng chưa tính hoàn thành lượt/thưởng), (2) màn khóa và notification mặc định chỉ hiện nội dung trung tính (`Báo thức <HH:mm>` / `Mở để xem kế hoạch hôm nay`), không lộ môn học hay thời khóa biểu chi tiết khi màn khóa chưa mở, (3) `Dừng khẩn cấp` luôn hoạt động một chạm, và (4) bổ sung Kotlin unit test kiểm chứng.
- **Nguồn yêu cầu:** Yêu cầu người dùng ngày 16/11/2026; `AGENTS.md §3`; `docs/00-start/05-goi-task-dau-tien.md` (B02); `docs/01-product/09-giac-ngu-va-bao-thuc.md` (`SLEEP-03`, `MORNING-01`); `docs/02-engineering/02-bao-thuc-android.md`.
- **Chủ sở hữu/reviewer:** AI Coding Agent.
- **Phạm vi file dự kiến:** `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingActivity.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/NativeAlarmModels.kt`, `app/android/app/src/test/kotlin/com/mindclock/app/AlarmRingPrivacyAndStateTest.kt`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/ui/core/strings/app_strings.dart`, `docs/02-engineering/02-bao-thuc-android.md`, `tasks/T032-b02-native-alarm-invariants/*`.
- **Liên quan:** Tiếp nối `T030-b01b-flutter-android-build`; sửa lệch hành vi giữa code `T015` cũ và bất biến sản phẩm hiện hành (`AGENTS.md §3`).
- **Source refs đã đọc:** `AGENTS.md §3, §5`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/02-bao-thuc-android.md`, `.agents/skills/mindclock-android-native/SKILL.md`.
- **Điểm tiếp tục:** Cắm ít nhất 2 máy Android thật khác OEM/API level qua ADB để chạy AD01–AD07 và SLEEP-03 thực tế trên thiết bị trước khi chuyển `T032` sang `done`.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
