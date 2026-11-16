# Nhiệm vụ T039: AI Quét ảnh TKB & Đồng hồ Realtime sản phẩm thực tế

- **Trạng thái:** `in_progress`
- **Mục tiêu:**
  1. Thêm tính năng upload/chụp ảnh thời khóa biểu giấy bằng AI (Gemini Vision) tự động nhận diện ma trận các thứ và tiết học THPT, trả về bản nháp để học sinh xem xét, chỉnh sửa và xác nhận; tự động liên kết báo thức sáng theo môn học thực tế của từng ngày.
  2. Bổ sung đồng hồ Realtime tích tắc từng giây (`HH:mm:ss`) trên màn Hôm nay (Today), đếm ngược trực tiếp đến chuông báo thức kế tiếp ("Còn X giờ Y phút nữa"), đồng bộ thời gian chuẩn xác với Android OS AlarmManager.
- **Tài liệu căn cứ:**
  - `AGENTS.md` §3 (bất biến sản phẩm, AI chỉ tạo nháp, người học xác nhận trước khi lưu).
  - `AGENTS.md` §4 (quy trình task).
  - `docs/01-product/09-giac-ngu-va-bao-thuc.md` (chu kỳ giấc ngủ, báo thức theo TKB).
  - `docs/02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md` (catalog môn học và TKB).
- **Phạm vi kiểm thử:**
  - Unit tests cho Gemini Vision Timetable Parser trên backend FastAPI (`test_timetable_image_parser.py`).
  - Unit/Widget tests cho Realtime Clock ticker và Timetable OCR Preview trên Flutter Dart (`today_realtime_clock_test.dart`, `timetable_ocr_test.dart`).
