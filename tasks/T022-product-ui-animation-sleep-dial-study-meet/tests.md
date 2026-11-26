# T022 — Kế hoạch Kiểm thử & Kết quả

## 1. Danh sách Test Cases
- Kiểm cứu demo 14/11: nguồn đổi đồng thời sang _PRODUCT_HTML. Trích script bằng Python AST và node --check: exit 0. Trang cổng 8000 không có marker viewport-container của bản trung gian. Server phụ 8001 khởi động nhưng HTTP timeout/000, không coi là kiểm browser đạt. Chưa kiểm chuông/chat/timer bằng thao tác thật.
- TC-rescue: trang cổng 8001 chứa viewport-container; JS qua node --check; chat đọc message_vi/next_question_vi, lỗi HTTP không tạo lời AI mẫu; timer dựa mốc thời gian có bắt đầu/tạm nghỉ.
- **TC-01:** Kiểm tra cú pháp và tích hợp route `/demo` và `/demo/bermuda.mp3` qua pytest `test_demo_console_and_bermuda_audio_route`.
- **TC-02:** Kiểm tra 13 bài test hồi quy của backend FastAPI (`pytest -v`).
- **TC-03:** Kiểm tra tương tác Vòng quay ngủ-dậy: thay đổi giờ ngủ (22:30) và giờ thức dậy (05:30) tính ra chính xác 7 giờ 00 phút.
- **TC-04:** Kiểm tra phát và dừng âm thanh Bermuda khẩn cấp.
- **TC-05:** Kiểm tra khung chụp ảnh bài làm và upload multipart lên endpoint `/v1/sessions/{id}/attempts`.
- **TC-06:** Kiểm tra giao diện Meet của Không gian học AI, gọi trợ lý Socratic và cấp token Live.
