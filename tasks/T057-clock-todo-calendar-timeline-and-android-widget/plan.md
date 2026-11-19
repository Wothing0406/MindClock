# Kế hoạch thực hiện T057

## Điểm bắt đầu

- Đã xong T056 (`aa6625f` trên `origin/main`).
- `TodayScreen` hiện có đồng hồ thời gian thực, thanh TKB 7 ngày, card báo thức, Không gian học. `MainActivity.kt` đang có 4 MethodChannel.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo `DailyTodoTask`, tích hợp vào `GuestWorkspace`, `GuestWorkspaceViewModel` (CRUD + toggle Done + snapshot hôm nay), và `ScheduleWidgetBridge` | Unit test persistence + merge TKB/To-do xanh | [x] |
| 2 | Xây UI **Lịch trình & To-Do hôm nay** (khung lịch ngày theo giờ kiểu Calendar + thêm/sửa/tick Done + quét ảnh TKB qua `MediaPickerGateway`) trên `TodayScreen` & `TimetableProfileScreen` | Widget test PASS ở `320dp/200%`, `RAW_COLOR_HITS: 0` | [x] |
| 3 | Viết Android Native `MindClockScheduleWidgetProvider.kt`, `ScheduleWidgetBridgeHandler.kt`, `TaskReminderReceiver.kt`, layout XML widget & đăng ký trong `AndroidManifest.xml` / `MainActivity.kt`, kèm `MindClockWidgetFormatterTest.kt` | Kotlin `:app:testDebugUnitTest` + Flutter bridge contract tests PASS | [x] |
| 4 | Chạy full `flutter analyze`, `flutter test`, Kotlin tests, build/test trên `emulator-5554` (chụp ảnh giao diện Calendar Timeline + kiểm Widget provider đăng ký trong Android system), cập nhật docs & push `origin/main` | Tất cả test xanh, commit & push backup thành công | [x] |

## Rủi ro và đường lui

- Một số launcher Android không tự gắn Widget ra Home bằng ADB; ta xác nhận đăng ký Widget qua `adb shell appwidget` / `dumpsys appwidget` + Kotlin unit test `RemoteViews` formatter + kiểm trực quan qua ảnh Calendar & demo app.
