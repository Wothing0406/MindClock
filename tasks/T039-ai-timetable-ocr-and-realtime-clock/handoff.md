# Bàn giao nhiệm vụ T039

- **Trạng thái:** `done`
- **Thay đổi chính:**
  1. Đã triển khai tính năng AI Timetable OCR: Backend Gemini Vision endpoint `POST /v1/timetable/parse-image`, trích xuất tự động danh sách tiết học, chuẩn hóa tên môn THPT.
  2. Giao diện Flutter: Thêm nút `Quét ảnh thời khóa biểu (AI tự động điền)` trong `TimetableProfileScreen`, hiển thị thẻ duyệt bản nháp (draft preview) với môn/tiết từng ngày trong tuần; học sinh nhấn `Xác nhận & Lưu thời khóa biểu` mới cập nhật TKB vào hệ thống.
  3. Đồng hồ thời gian thực (Realtime Clock): Thêm Hero Card hiển thị `HH:mm:ss` nhảy giây theo thời gian thực tế, thứ ngày tháng tiếng Việt, và đếm ngược thời gian chuông reo tiếp theo trên màn `TodayScreen`.
  4. Chuẩn hóa sản phẩm (Product Vibe): Gỡ bỏ hoàn toàn các badge kỹ thuật gồ ghề (`Đã lưu local`, `OS: Đã sẵn sàng`, `Server: Chưa đồng bộ server`), giao diện chuyển sang tông học sinh THPT gọn gàng, tự nhiên.
  5. Đảm bảo chuẩn Responsive: Áp dụng `FittedBox` + `Wrap` co giãn mượt mà tại màn hình hẹp 320dp và cỡ chữ 200%, không bị tràn layout.
- **Kiểm thử & Môi trường:**
  - Ngày: 2026-11-17
  - Backend: `pytest test_timetable_image_parser.py` (3/3 PASS), `docker compose up -d --build api` hoạt động lành mạnh trên cổng 8000.
  - Frontend: `flutter test test/timetable_ocr_and_realtime_clock_test.dart` (2/2 PASS), toàn bộ Flutter test suite (47/47 PASS).
  - Android Emulator (`emulator-5554`): Cài đặt APK debug thực tế, xác nhận đồng hồ nhảy giây, quét TKB nháp, lưu TKB và phản ánh trực tiếp vào lịch học màn Hôm nay.
- **Rủi ro & Ghi chú:**
  - Ảnh chụp TKB bằng camera thực tế có thể bị nghiêng hoặc thiếu sáng; Gemini prompt đã có hướng dẫn chuẩn hóa và chế độ tự phục hồi về danh mục môn chuẩn.
- **Điểm tiếp tục chính xác:**
  - Tích hợp thêm nút camera trực tiếp từ thiết bị khi người dùng cấp quyền chụp ảnh ngoài file picker có sẵn.
  - Tiếp tục phát triển các vòng đời đấu trường PvP Solo 1v1 theo catalog đã kiểm định.
