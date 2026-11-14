# Bàn giao T014

- **Trạng thái:** `blocked` (đã viết xong code UI/domain/data/tests ở `app/`, chưa thể biên dịch và chạy `flutter analyze`/`flutter test`/`flutter run` vì máy chưa cài Flutter SDK).

## 1. Phần đã làm

- Xây dựng cấu trúc Flutter Android phân lớp (`UI -> ViewModel -> Repository -> LocalStore` + `AlarmSchedulerService` port) trong `app/`:
  - **Luồng khách (`S01`, `S03`):** `Dùng thử không cần tài khoản`, có nút `Để sau` và `Chỉ báo thức`; chọn lớp, nhiều môn học (chỉ rõ môn chưa có câu duyệt), tối đa 5 môn ưu tiên và mục tiêu cá nhân chỉnh sửa được; lược bỏ hoàn toàn Đấu trường khỏi thanh 3 tab (`Hôm nay`, `Luyện tập`, `Tôi`).
  - **Thời khóa biểu 7 ngày & Hồ sơ (`S05`):** chọn từng ngày `Thứ 2 .. Chủ nhật`, bật/tắt `Ngày nghỉ`, thêm/sửa/xóa tiết môn học, sửa lớp/môn/ưu tiên/mục tiêu; sửa TKB tuyệt đối không tự đổi giờ báo thức đã lưu.
  - **Báo thức local & Gợi ý giờ dậy (`S06`, `S04`):** đặt giờ, lặp T2–CN, chọn âm/rung, chế độ thường vs tự bật `Báo thức thử thách` (giải thích rõ không Hoãn, luôn có `Dừng khẩn cấp`), môn chưa có câu duyệt vẫn cho lưu chuông kèm giải thích rõ; máy tính gợi ý giờ dậy (`giờ bắt đầu − đi đường − chuẩn bị − đệm`) hiển thị công thức và chỉ áp dụng khi người dùng bấm `Dùng giờ này`.
  - **Interface native & lưu local:** `AlarmSchedulerService` + `AlarmSchedulerBridgeContract.kt` chuẩn bị nối Android `AlarmManager`; `UnboundAlarmSchedulerService` trả trạng thái `"Đã lưu cấu hình"` và quyền `Chưa kiểm tra (chưa nối OS)` (không hiện `"Đã sẵn sàng"` giả). `GuestWorkspaceRepository` lưu/khôi phục JSON qua `SharedPreferencesKeyValueStore`.
  - **Giao diện Android (`MindClockTheme`, `MindClockPressable`, `MindClockIcon`):** tuân thủ token `docs/55`, lưới 4 dp, chạm tối thiểu 48×48 dp, tắt ink ripple Material mặc định.
  - **Kiểm thử viết sẵn:** `app/test/domain_and_persistence_test.dart` và `app/test/guest_flow_widget_test.dart`.

## 2. Kết quả kiểm tra thực tế

- Quét tĩnh `app/lib` bằng `Select-String`: không có mã màu `Color(0x...)` rò ra ngoài `mindclock_theme.dart`, không có `InkWell`/`NavigationBar`/`FilledButton`/`ElevatedButton`, không hiện `"Đã sẵn sàng"` giả khi chưa nối OS.
- `python scripts/check_docs_links.py` -> `PASS local links in 57 documentation files` (exit 0).
- `python scripts/check_task_records.py` -> `Task records OK` (exit 0).
- **Chưa chạy được:** `flutter pub get`, `flutter analyze`, `flutter test`, build APK Android và kiểm thử trên thiết bị thật (`flutter` chưa cài trên máy; `adb devices` hiện trống).

## 3. Điểm tiếp tục cụ thể

1. Cài **Flutter SDK** (và thêm `flutter/bin` vào `PATH` theo `docs/47`), đồng thời sinh phần Android project wrapper còn thiếu bằng `cd app && flutter create . --platforms=android`.
2. Chạy `flutter pub get && flutter analyze && flutter test` tại `app/` để xác minh biên dịch và toàn bộ `TC-01..TC-08` (sửa nếu có lỗi API/lint cụ thể), rồi cắm điện thoại Android thật (`adb devices`) chạy `flutter run` kiểm tra màn 320/360/390/600 dp & chữ 200%.
3. Chỉ sau khi `TC-01..TC-08` đạt thật mới chuyển trạng thái `T014` sang `done`, rồi mở task nối Android `MethodChannel` thật (`AlarmManager` + `FullScreenIntent` + phát âm thanh, rà giấy phép file `mp3/jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3` hiện đang để trong workspace) vào `AlarmSchedulerService`.
