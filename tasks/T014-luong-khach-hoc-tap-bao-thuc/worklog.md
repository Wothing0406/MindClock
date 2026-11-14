# Nhật ký thực hiện T014

## 2026-11-14

- Đọc lại `tasks/README.md`, `tasks/_template/*`, `docs/08, 31, 32, 47`, `flutter-apply-architecture-best-practices/SKILL.md` và `flutter-custom-design-system/SKILL.md` + `references/tokens.md`, `references/pressable.md`.
- Kiểm tra công cụ máy dev: có `C:\Users\QuangDev\AppData\Local\Android\Sdk\platform-tools\adb.exe` (`adb devices` trống) và `Android Studio`; **không có `flutter` hoặc `dart` SDK trên máy**.
- Tạo hồ sơ `tasks/T014-luong-khach-hoc-tap-bao-thuc/` trước khi khởi tạo mã Flutter trong `app/`.
- Xây dựng đầy đủ mã nguồn Dart/Flutter + test trong `app/`:
  - `domain/models/`: `SubjectCatalog` (11 môn chuẩn `docs/32`, tách rõ môn đã/chưa có câu duyệt), `StudyProfile` (lớp, nhiều môn, 0–5 môn ưu tiên, mục tiêu sửa được, `alarmOnlyMode`), `WeeklyTimetable` (7 ngày, ngày nghỉ, thêm/sửa/xóa tiết), `AlarmConfig` (giờ, ngày lặp T2–CN, âm/rung, thường vs tự chọn thử thách, `AlarmSyncStatus`), `WakeSuggestionCalculator` (`classStart - commute - prep - buffer`, xử lý qua nửa đêm, chỉ preview), `GuestWorkspace`.
  - `domain/services/alarm_scheduler_service.dart` + `app/android/.../AlarmSchedulerBridgeContract.kt`: tách interface cho giai đoạn Android native; mặc định `UnboundAlarmSchedulerService` chỉ trả `savedConfigOnly` (`"Đã lưu cấu hình"`), không bao giờ trả `"Đã sẵn sàng"` hay giả cấp quyền.
  - `data/`: `LocalKeyValueStore` (`SharedPreferencesKeyValueStore` + `InMemoryKeyValueStore`) và `GuestWorkspaceRepository` lưu/khôi phục JSON local.
  - `ui/`: `MindClockTheme` (`ThemeExtension`, 1:1 token `docs/55`), `MindClockPressable` (`NoSplash`, ≥48×48 dp, hỗ trợ `Reduce Motion`), `MindClockIcon` (vector nét 2 px bo tròn), shell 3 tab (`Hôm nay`, `Luyện tập`, `Tôi` — lược bỏ hoàn toàn `Đấu trường`) cùng `S01`, `S03`, `S04`, `S05`, `S06`.
  - `test/`: `domain_and_persistence_test.dart` và `guest_flow_widget_test.dart` phủ AC-01..AC-08.
- Chạy kiểm tra tĩnh PowerShell trên `app/lib`: xác nhận không có `Color(0x...)` ngoài `mindclock_theme.dart`, không có `InkWell`/`NavigationBar`/`FilledButton`/`ElevatedButton`, không lộ Đấu trường và không hiện `"Đã sẵn sàng"` giả.
- Bị chặn ở khâu biên dịch/chạy test vì máy chưa cài Flutter SDK → giữ trạng thái `blocked` và ghi rõ đường chạy `flutter create . --platforms=android && flutter pub get && flutter analyze && flutter test` trong `handoff.md`.
- Rà lại toàn bộ luồng khách (`T014` lượt cập nhật): bổ sung chọn mức ưu tiên `Cao / Vừa` trong `S03`, thêm nút chỉnh `-1/+1 phút` trong `S06`, `-1h/+1h/-5p/+5p` cho tiết TKB trong `S05`, bổ sung giải thích khi chọn `Chỉ báo thức` cùng `Báo thức thử thách`, và bổ sung `ensureVisible` + case đóng/mở lại `MindClockApp` trong `guest_flow_widget_test.dart`. Ghi nhận có thêm file `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3` trong workspace (giữ nguyên chưa gộp vào `app/` để chờ nối native audio & kiểm tra giấy phép).
