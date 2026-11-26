# T022 — Kế hoạch triển khai Giao diện Sản phẩm Toàn diện

## 1. Các bước thực hiện
- [ ] Cứu demo: mở server mới cổng 8001; sửa mapping message_vi, lỗi chat minh bạch và timer local; kiểm JS syntax và HTTP thực tế.
- [x] Bước 1: Khảo sát chi tiết ảnh mẫu vòng quay 24h `media_1794620679858_7b86f075.jpg` (Kim giờ ngủ, kim giờ dậy, cung tròn màu cam, nhãn số 24h từ 0, 2, 4,... 22, biểu tượng mặt trăng đêm và mặt trời trưa).
- [ ] Bước 2: Thiết kế và cài đặt component Vòng quay giấc ngủ 24h SVG/Canvas tương tác mượt mà bằng kéo thả hoặc cảm ứng, tự tính số giờ ngủ chính xác (kể cả ngủ đêm sang sáng hôm sau), đồng bộ với cấu hình báo thức.
- [ ] Bước 3: Thiết kế màn hình Báo thức đêm với hiệu ứng sóng âm động, đồng hồ kỹ thuật số lớn, nút Dừng khẩn cấp màu đỏ ngắt chuông tức thời.
- [ ] Bước 4: Thiết kế Khung ảnh chụp bài làm (Camera Viewfinder Frame) với hỗ trợ Webcam trực tiếp `navigator.mediaDevices.getUserMedia` hoặc tải ảnh, hiệu ứng quét laser AI (laser scan beam animation), kết nối chấm Gemini Vision.
- [ ] Bước 5: Thiết kế Không gian học AI phong cách Google Meet với 2 ô video (Học sinh + AI Mentor), thanh điều khiển Meet (Mic, Cam, Giơ tay, Rời phòng), visualizer sóng âm động, đồng hồ Pomodoro và chat Socratic.
- [ ] Bước 6: Ghép toàn bộ vào giao diện sản phẩm hoàn thiện trong `services/api/app/demo_ui.py` với tab bar di động, chế độ khung điện thoại (Device Frame Toggle) và tương thích 100% Android Chrome.
- [ ] Bước 7: Kiểm thử thực tế bằng Pytest backend và kiểm tra giao diện trên server live.
