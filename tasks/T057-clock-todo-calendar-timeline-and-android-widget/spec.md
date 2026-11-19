# Đặc tả nhiệm vụ T057

## Vấn đề và kết quả mong muốn

Người dùng phản hồi app cần xoay quanh **đồng hồ & quản lý thời gian thực**:
1. Chưa có **To-do list trong ngày** với nút đánh dấu **Done**, loại việc (`Chính khóa`, `Học thêm`, `Tự học`), mốc giờ và **nhắc giờ cục bộ**; ảnh TKB ở `TimetableProfileScreen` chưa lấy ảnh thật từ thư viện máy qua `MediaPickerGateway`.
2. Chưa có **khung lịch trình theo giờ kiểu Calendar** (gộp tiết TKB + học thêm + to-do theo giờ trong ngày, có khung 00:00–23:59 trực quan).
3. Chưa có **Android Home Screen Widget** hiển thị ngoài màn hình chính điện thoại lịch hôm nay sẽ làm gì, mấy giờ, tiến độ Done.

Sau T057, học sinh mở `Hôm nay` thấy đồng hồ thời gian thực + lịch trình theo giờ + to-do Done trong ngày, có thể gắn Widget MindClock ra màn hình chính Android, thêm/tick Done và đồng bộ snapshot tức thời xuống Widget & nhắc giờ cục bộ.

## Phạm vi

- **Trong phạm vi:**
  - Model `DailyTodoTask` (lưu bền trong `GuestWorkspace` theo từng ngày `dateIso`), tích hợp cả tiết TKB chính khóa lẫn task học thêm/tự học thành danh sách thời gian thống nhất cho ngày đang chọn.
  - UI Calendar Day Timeline (`00:00–23:00` cuộn được, highlight khung giờ hiện tại, tick Done ngay trên dòng giờ, tạo nhanh việc mới chọn giờ/thời lượng/phân loại/môn).
  - Nối chọn ảnh thật từ `MediaPickerGateway` khi quét ảnh TKB ở `TimetableProfileScreen` (fallback nháp nếu chưa đăng nhập hoặc chưa chọn ảnh).
  - Kênh Android native `mindclock/schedule_widget`: lưu snapshot lịch hôm nay vào `SharedPreferences`, gọi `AppWidgetManager` cập nhật `MindClockScheduleWidgetProvider` (layout đêm `#101A30` theo Ảnh 2 tham chiếu), và đặt/hủy thông báo nhắc giờ việc học (`TaskReminderReceiver`).
- **Ngoài phạm vi:** Đồng bộ server `/v1/tasks` mới hoặc Google Calendar sync (giữ cục bộ bền vững trước, không làm gãy API `/v1` hiện tại); giao diện Kết bạn/Phòng công khai làm ở T058.
- **Dữ liệu/role/quyền liên quan:** Không ép xin quyền mới ngoài `POST_NOTIFICATIONS`/`SCHEDULE_EXACT_ALARM` đã khai báo; fallback thông báo chuẩn nếu thiếu quyền exact alarm.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Thêm việc / học thêm trong ngày (`DailyTodoTask`) và khởi động lại app | Lưu bền trong `GuestWorkspace`, gộp đúng thứ tự giờ với tiết TKB ngày đó, hỗ trợ tick `Done` / `Chưa xong` và tính đúng tỷ lệ `X/Y` | TC-01 |
| AC-02 | Xem giao diện Lịch trình Calendar trên `TodayScreen` ở `320dp/200%` | Hiển thị trục giờ `00:00–23:00` / các khối giờ rõ ràng không tràn layout (`RAW_COLOR_HITS: 0`), tick Done và xóa việc sạch sẽ | TC-02 |
| AC-03 | Quét ảnh TKB từ `TimetableProfileScreen` | Cho chọn ảnh qua `MediaPickerGateway` (nếu có), đọc bytes -> base64 gửi `parseTimetableImage`; hủy chọn không crash | TC-03 |
| AC-04 | Thay đổi TKB hoặc To-do khi gắn với Android native bridge | Gửi `ScheduleWidgetSnapshot` xuống `mindclock/schedule_widget`, định dạng chuẩn cho Widget (`MindClockWidgetFormatter`) & lên/hủy nhắc việc đúng giờ | TC-04, TC-05 |
| AC-05 | Đóng gói APK & kiểm tra trên Android Emulator | Gradle biên dịch sạch `MindClockScheduleWidgetProvider` + `mindclock_schedule_widget.xml`, `flutter test` & `:app:testDebugUnitTest` xanh, xuất APK cài được trên `emulator-5554` | TC-05, TC-06 |

## Hợp đồng và trường hợp biên

- `GuestWorkspace.fromJson` đọc `dailyTasks` optional (`?? const []`), không làm mất dữ liệu workspace cũ.
- Khi thiết bị chưa hỗ trợ/chưa nối bridge (`UnboundScheduleWidgetBridge`), mọi thao tác To-do vẫn chạy mượt trên Flutter không throw.
- Widget Android giới hạn hiển thị tối đa 4 sự kiện sắp tới/chưa xong (kèm tổng `X/Y xong`), tránh tràn chiều cao widget 2x2 / 4x2 trên Launcher.

## Quyết định/mâu thuẫn

- Chọn viết `AppWidgetProvider` bằng Android XML `RemoteViews` thuần (không thêm dependency Jetpack Glance) để giữ build nhanh, APK gọn nhẹ, tuân thủ `AGENTS.md §5`.
