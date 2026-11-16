# Đặc tả kỹ thuật T039: AI Quét ảnh TKB & Đồng hồ Realtime

## 1. Yêu cầu sản phẩm (AC)
- **AC-01 (AI Timetable OCR):** Cung cấp endpoint `POST /v1/timetable/parse-image` nhận ảnh TKB (base64 hoặc binary). Backend dùng Gemini Vision nhận diện ma trận các thứ (Thứ 2 đến Thứ 7/Chủ nhật), các tiết (1 đến 5), chuẩn hóa mã môn theo `SubjectCatalog` THPT (`math`, `literature`, `english`, `physics`, `chemistry`, `biology`, `history`, `geography`, `informatics`, `civics`).
- **AC-02 (Xem và xác nhận nháp):** AI chỉ tạo bản nháp; client hiển thị preview trực quan các tiết học nhận diện được. Học sinh có thể kiểm tra, sửa đổi tiết/môn bị nhận diện nhầm, rồi mới bấm "Xác nhận & Lưu thời khóa biểu".
- **AC-03 (Báo thức theo TKB sáng):** Khi TKB được cập nhật, hệ thống tự động:
  - Tính toán giờ học sớm nhất của từng ngày trong tuần.
  - Gợi ý/liên kết giờ báo thức sáng phù hợp (thời gian đi lại + chuẩn bị + đệm).
  - Tự động gắn môn ôn sáng theo lịch học thực tế của ngày hôm đó (ví dụ Thứ 2 có Toán thì sáng reo câu hỏi ôn Toán).
- **AC-04 (Đồng hồ Realtime sản phẩm thực tế):**
  - Màn hình `TodayScreen` hiển thị đồng hồ số chạy từng giây theo thời gian thực (`HH:mm:ss`).
  - Hiển thị đếm ngược trực quan đến chuông tiếp theo: *"Còn X giờ Y phút · Chuông 06:00 · Ôn Toán"*.
  - Tích tắc 1Hz mượt mà, không gây rò rỉ bộ nhớ (dispose Timer cẩn thận).

## 2. Thiết kế dữ liệu & API
- **Endpoint:** `POST /v1/timetable/parse-image`
  - Input: `{"image_base64": str, "mime_type": str}`
  - Output: `{"slots": [{"weekday": int, "position": int, "subject_code": str, "topic_id": str | None}], "raw_notes": str | None}`
