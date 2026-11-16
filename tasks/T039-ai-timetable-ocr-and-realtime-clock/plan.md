# Kế hoạch thực hiện T039

- [x] **Bước 1:** Backend: Bổ sung phương thức `parse_timetable_image` trong `GeminiService` và endpoint `POST /v1/timetable/parse-image` trong `routes/v1.py` kèm unit test pytest (`test_timetable_image_parser.py` - 3/3 PASS).
- [x] **Bước 2:** Frontend: Bổ sung Realtime Clock Ticker (`Timer.periodic`) trên `TodayScreen` với giao diện đồng hồ số sống động, nhịp nháy giây và đếm ngược thời gian đến chuông kế tiếp (loại bỏ hoàn toàn các badge kỹ thuật dev-mode).
- [x] **Bước 3:** Frontend: Bổ sung tính năng chụp/quét ảnh TKB trong `TimetableProfileScreen`, gọi API Gemini Vision (hoặc fallback offline heuristic khi chưa đăng nhập), hiển thị bảng xem trước (preview draft), cho phép bấm xác nhận mới cập nhật TKB.
- [x] **Bước 4:** Kiểm thử tích hợp: Viết widget test cho đồng hồ realtime và luồng xác nhận TKB từ ảnh (`timetable_ocr_and_realtime_clock_test.dart` - 2/2 PASS). Chạy toàn bộ Flutter test suite (47/47 PASS) và build APK cài lên Android emulator kiểm tra thực tế.
- [x] **Bước 5:** Cập nhật tài liệu, kiểm tra hồ sơ nhiệm vụ (`scripts/check_task_records.py` và `check_docs_links.py`) và bàn giao.
