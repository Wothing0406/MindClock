# T057 — Đồng hồ + To-Do List ngày, Lịch trình kiểu Calendar (Ảnh 1), Nhắc việc & Android Home Screen Widget (Ảnh 2)

- **Trạng thái:** `done`
- **Mục tiêu:** Biến MindClock thành ứng dụng trung tâm Đồng hồ – Lịch trình học thật sự: người dùng xem lịch trình theo khung giờ từng ngày kiểu Calendar (gộp TKB chính khóa + học thêm + To-do), thêm/sửa/đánh dấu Done việc trong ngày, upload ảnh TKB từ thư viện máy, nhận thông báo nhắc việc đúng giờ trên Android và thêm được Widget Lịch hôm nay ngoài màn hình chính Android (`AppWidgetProvider`).
- **Nguồn yêu cầu:** Người dùng 19/11/2026 kèm 2 ảnh tham chiếu Calendar ngày theo giờ & Home Screen Widget; `AGENTS.md §2–4`.
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `app/lib/domain/models/{daily_todo_task.dart,guest_workspace.dart}`
  - `app/lib/domain/services/schedule_widget_bridge.dart`, `app/lib/data/services/method_channel_schedule_widget_bridge.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/{today_screen.dart,timetable_profile_screen.dart,mindclock_shell_screen.dart}`
  - `app/lib/app.dart`
  - `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/kotlin/com/mindclock/app/{MainActivity.kt,MindClockScheduleWidgetProvider.kt,ScheduleWidgetBridgeHandler.kt,TaskReminderReceiver.kt}`
  - `app/android/app/src/main/res/{layout/mindclock_schedule_widget.xml,xml/mindclock_schedule_widget_info.xml,drawable/widget_bg_night.xml}`
  - `app/test/{daily_todo_calendar_test.dart}`, `app/android/app/src/test/kotlin/com/mindclock/app/MindClockWidgetFormatterTest.kt`
  - `docs/00-start/01-hien-trang.md`, `tasks/T057-*/*`.
- **Liên quan:** `T039-ai-timetable-ocr-and-realtime-clock`, `T055-student-avatars-and-custom-media-picker`, `T056-app-branding-loading-alarm-simplification-and-apk`.
- **Source refs đã đọc:** `AGENTS.md §3–4`, `.agents/skills/mindclock-android-native/SKILL.md`, `app/lib/domain/models/{timetable.dart,guest_workspace.dart}`, `app/lib/ui/features/guest_shell/views/{today_screen.dart,timetable_profile_screen.dart}`, `app/android/app/src/main/kotlin/com/mindclock/app/MainActivity.kt`.
- **Điểm tiếp tục:** Triển khai model `DailyTodoTask`, Calendar Timeline + To-Do Done UI, bridge nhắc việc & Android `AppWidgetProvider`, sau đó kiểm test + emulator + commit/push backup lên GitHub.

## Cổng trước coding

- [x] Đã đọc code TKB, TodayScreen, GuestWorkspace, Android MainActivity và `mindclock-android-native/SKILL.md`.
- [x] Đã xác định phạm vi tách rõ T057 (Lịch trình/To-do/Widget) trước T058 (Kết bạn/Phòng công khai).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] Docs chuẩn & `handoff.md` cập nhật kèm SHA remote đã xác minh.
