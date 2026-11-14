# Kế hoạch và kết quả kiểm thử T014

Viết ca kiểm thử từ `spec.md` trước coding. Điền **lệnh thực và kết quả thực**, không ghi "pass" nếu chưa chạy.

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Mở app lần đầu -> bấm `Dùng thử không cần tài khoản`, `Để sau`, `Chỉ báo thức`; kiểm tra bottom nav | Không hỏi email/mật khẩu; vào `Hôm nay`; bottom nav chỉ 3 tab, 0 tab `Đấu trường` | Widget test `app/test/guest_flow_widget_test.dart` (`flutter test`) | Chưa chạy |
| TC-02 | AC-02 | Chọn lớp `Lớp 9`, chọn 3 môn, bật 2 môn ưu tiên (`Toán`, `Tin học`), sửa nhãn mục tiêu | Lưu và hiển thị đúng danh sách môn/ưu tiên/mục tiêu; sửa lại được | Unit + Widget test `flutter test` | Chưa chạy |
| TC-03 | AC-03 | Ở `S05`, bật `Ngày nghỉ` Chủ nhật; thêm tiết Thứ 2 `Toán 07:00`, sửa thành `07:15`, xóa tiết | TKB 7 ngày cập nhật đúng và lưu thành công | Unit + Widget test `flutter test` | Chưa chạy |
| TC-04 | AC-04 | Ở `S06`, đặt `05:55`, chọn lặp T2/T4/T6, tắt/bật rung, bật `Báo thức thử thách`, thử chọn môn `Tin học` (chưa có câu duyệt) | Thấy rõ dòng giải thích `Không có Hoãn. Dừng khẩn cấp luôn có.`; môn chưa có câu duyệt vẫn cho lưu chuông kèm giải thích rõ | Unit + Widget test `flutter test` | Chưa chạy |
| TC-05 | AC-05 | Tính gợi ý giờ dậy `07:00 - 25 - 30 - 10`; không bấm `Dùng giờ này`; sau đó bấm `Dùng giờ này` -> lưu `05:55` -> sửa TKB tiết `07:00` thành `07:30` | Phép tính hiện `05:55`; chỉ đổi form khi bấm `Dùng giờ này`; sau khi sửa TKB, giờ chuông đã lưu vẫn giữ nguyên `05:55` | Unit + Widget test `app/test/wake_calculator_and_persistence_test.dart` (`flutter test`) | Chưa chạy |
| TC-06 | AC-06 | Lưu báo thức qua `UnboundAlarmSchedulerService` (chưa nối OS) | Hiện badge `Đã lưu cấu hình`; không xuất hiện `Đã sẵn sàng` hay trạng thái quyền OS đã cấp giả | Unit + Widget test `flutter test` | Chưa chạy |
| TC-07 | AC-07 | Lưu hồ sơ, TKB, báo thức -> khởi tạo `GuestWorkspaceRepository` & `ViewModel` mới từ cùng `LocalKeyValueStore` | Toàn bộ lớp, môn, ưu tiên, mục tiêu, TKB 7 ngày và báo thức được khôi phục nguyên vẹn | Unit test `flutter test` | Chưa chạy |
| TC-08 | AC-08 | Render các màn chính ở 320/360/390/600 dp với text scale `1.0/1.5/2.0`; grep check token/ripple/emoji | Zero RenderFlex overflow; nút ≥48 dp; không dùng `Color(0x` ngoài `mindclock_theme.dart`, không `InkWell` | Widget test (`flutter test`) + static grep check | Chưa chạy |

## Cổng theo rủi ro

- **Báo thức OS:** giao diện đã tách qua `AlarmSchedulerService`, **chưa nối Android native (`AlarmManager`) và chưa kiểm máy Android thật** — bắt buộc ghi rõ là ngoài phạm vi chạy thật trong task này.
- **Môi trường máy dev:** chưa có Flutter SDK (`flutter`/`dart` chưa cài), do đó `TC-01..TC-08` dưới `flutter test` hiện bị chặn ở bước thực thi cho tới khi cài Flutter SDK. Các check tĩnh (Python/PowerShell/task records) vẫn chạy và ghi kết quả thật.

## Kết quả kiểm tra đã chạy ngày 2026-11-14

```powershell
# 1. Kiểm tra công cụ trên máy
where.exe flutter dart   # Không tìm thấy (exit 1)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
# List of devices attached: (trống)

# 2. Quét tĩnh token, widget Material mặc định và chuỗi trong app/lib
Select-String -Path $files.FullName -Pattern "Color\(0x|Color\.from|InkWell|FilledButton|ElevatedButton|FloatingActionButton|NavigationBar|Đấu trường|Đã sẵn sàng"
# Kết quả: Color(0x...) chỉ nằm trong mindclock_theme.dart; 0 InkWell/FilledButton/ElevatedButton/NavigationBar;
# 'Đã sẵn sàng' chỉ nằm ở nhánh isOsBridgeConnected == true (đang guard bởi UnboundAlarmSchedulerService).

# 3. Kiểm tra docs & task records
python scripts/check_docs_links.py   # PASS local links in 57 documentation files (exit 0)
python scripts/check_task_records.py # Task records OK (exit 0)
```

## Lệnh cần chạy ngay khi có Flutter SDK trên máy

```powershell
cd app
flutter create . --platforms=android
flutter pub get
flutter analyze
flutter test
```
