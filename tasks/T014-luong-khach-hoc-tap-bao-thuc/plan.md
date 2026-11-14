# Kế hoạch thực hiện T014

## Điểm bắt đầu

- Repo chưa có `app/pubspec.yaml`, chưa có mã Dart/Flutter; có `Android Sdk\platform-tools\adb.exe` và `Android Studio`, chưa có `flutter` trong `PATH` và chưa có thiết bị Android cắm qua `adb`.
- Quy tắc tokens và chuỗi `vi-VN` đã chốt tại `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T014-luong-khach-hoc-tap-bao-thuc/` (`README.md`, `spec.md`, `plan.md`, `tests.md`, `worklog.md`, `handoff.md`) | Đủ cổng trước coding | [x] |
| 2 | Khởi tạo cấu trúc project Flutter Android (`app/pubspec.yaml`, `app/analysis_options.yaml`, `app/android/` tối thiểu nếu cần) | Đúng chuẩn Flutter, zero lint thừa | [x] |
| 3 | Xây lớp Domain & Interface (`app/lib/domain/`): `StudyProfile`, `WeeklyTimetable`, `AlarmConfig`, `WakeSuggestionCalculator`, `SubjectCatalog`, `AlarmSchedulerService` + `UnboundAlarmSchedulerService` | Đầy đủ phép tính gợi ý, trạng thái `savedConfigOnly`, kiểm môn chưa có câu duyệt | [x] |
| 4 | Xây lớp Data persistence (`app/lib/data/`): `LocalKeyValueStore`, `SharedPreferencesKeyValueStore`, `GuestWorkspaceRepository` (lưu/khôi phục JSON local) | Round-trip serialize/deserialize không mất field | [x] |
| 5 | Xây UI Design System & ViewModel (`app/lib/ui/`): `MindClockTheme` (`ThemeExtension`), `MindClockPressable` (`NoSplash`), `GuestWorkspaceViewModel`, `S01`, `S03`, `S04` (3 tab không Đấu trường), `S05`, `S06` | Khớp token `docs/55`, không emoji, ≥48 dp, hỗ trợ 320–600 dp & chữ 200% | [x] |
| 6 | Viết unit tests & widget tests (`app/test/`) bao phủ AC-01..AC-08 | Mọi AC đều có test tương ứng | [x] |
| 7 | Chạy kiểm tra thực tế có trên máy (`check_docs_links.py`, `check_task_records.py`, static grep kiểm `Color(0x`/`InkWell`/`Đã sẵn sàng` giả, và `flutter test` nếu SDK khả dụng), cập nhật `tests.md`, `worklog.md`, `handoff.md`, push `origin/main` | Trung thực trạng thái chạy/blocked; không gắn `done` nếu `flutter test` chưa chạy | [ ] |

## Rủi ro và đường lui

- **Rủi ro máy dev chưa cài Flutter SDK:** không chạy được `flutter analyze` / `flutter test` ngay trong phiên này. **Đường lui:** giữ cấu trúc Dart chuẩn 100% không dùng codegen ẩn, tự kiểm tra chéo cú pháp/kiểu thủ công kỹ lưỡng, ghi `blocked` (hoặc `in_progress`) kèm lệnh kiểm tra cụ thể để chạy ngay khi cài Flutter SDK.
- **Rủi ro sửa lịch tự đổi giờ chuông:** tách `Timetable` và `AlarmConfig` thành thực thể độc lập; `updateTimetable` tuyệt đối không sửa `AlarmConfig.hour/minute`, chỉ tính `WakeDriftNotice` để hiện nhắc xem lại.
- **Rủi ro hiển thị giả `Đã sẵn sàng`:** `AlarmSchedulerService.isOsBridgeConnected` là nguồn duy nhất quyết định badge trạng thái; widget không được render chữ `Đã sẵn sàng` khi `status == AlarmSyncStatus.savedConfigOnly`.
