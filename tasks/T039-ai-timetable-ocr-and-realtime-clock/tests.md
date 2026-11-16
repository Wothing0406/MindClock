# Kế hoạch & Kết quả kiểm thử T039

## Ma trận kiểm thử

| Mã TC | Nội dung kiểm thử | Kết quả mong đợi | Trạng thái |
|---|---|---|---|
| TC-01 | Backend: Parse ảnh TKB hợp lệ qua Gemini Vision | Trả về danh sách `slots` có `weekday`, `position`, `subject_code` chuẩn hóa | PASS (`test_timetable_image_parser.py`) |
| TC-02 | Backend: Parse ảnh lỗi / không hợp lệ | Trả về lỗi 422 hoặc thông báo lỗi rõ ràng, không crash | PASS (`test_timetable_image_parser.py`) |
| TC-03 | Frontend: Realtime clock tích tắc 1 giây | Thời gian cập nhật mỗi giây, đếm ngược chính xác đến báo thức kế tiếp | PASS (`TC-RTC-01` trong `timetable_ocr_and_realtime_clock_test.dart`) |
| TC-04 | Frontend: Luồng duyệt bản nháp TKB từ ảnh | Hiển thị bảng nháp, cho phép sửa tiết/môn, bấm xác nhận mới lưu | PASS (`TC-OCR-01` trong `timetable_ocr_and_realtime_clock_test.dart`) |
| TC-05 | Toàn hệ thống: Hạn chế layout overflow tại 320dp/200% | Hero Clock và Timetable UI co giãn bằng FittedBox & Wrap mượt mà | PASS (`AC-08` trong `guest_flow_widget_test.dart`) |

