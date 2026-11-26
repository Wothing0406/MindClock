# T022 — Đặc tả Sản phẩm Giao diện Toàn diện: Vòng quay Ngủ-Dậy, Chuông báo, Khung ảnh AI, Không gian học Google Meet

## 1. Bối cảnh & Mục tiêu
- **Mục tiêu:** Nâng cấp giao diện sản phẩm MindClock thành một ứng dụng web/PWA hoàn chỉnh, hoạt động mượt mà cả trên máy tính và điện thoại/máy ảo Android (`http://10.0.2.2:8000/demo` & `http://127.0.0.1:8000/demo`).
- **Phạm vi giao diện & tương tác:**
  1. **Vòng quay Giấc ngủ 24h (Sleep & Wake Dial)**: Theo đúng thiết kế chuẩn quốc tế trong ảnh mẫu (`media_1794620679858_7b86f075.jpg`), cho phép kéo xoay chọn giờ ngủ đêm và giờ thức dậy sáng, tự tính số giờ ngủ (ví dụ 7 giờ / 8 giờ), cảnh báo mục tiêu ngủ, bật tắt chế độ báo thức thử thách không Hoãn, chọn âm chuông Bermuda.
  2. **Màn hình Báo thức reo ban đêm (Alarm Triggering)**: Giao diện tối (Night mode), sóng âm dao động (pulsing audio waves), đồng hồ nhảy số lớn, nút Dừng khẩn cấp màu đỏ nổi bật ngắt âm ngay lập tức, nút Mở câu hỏi thử thách.
  3. **Màn hình Thử thách & Khung ảnh chụp bài làm (Camera Viewfinder)**:
     - Làm bài chữ và khung chụp ảnh bài viết tay với góc ngắm viewfinder, chụp webcam trực tiếp hoặc tải ảnh, hiệu ứng quét laser AI (laser scanner animation), chấm điểm qua Gemini Vision (`/v1/sessions/{id}/attempts`) trong RAM không lưu ảnh cá nhân.
  4. **Không gian học AI (Study Space) phong cách Google Meet**:
     - Layout 2 khung video call: Khung học sinh (Webcam live stream hoặc avatar hoạt họa, mic toggle) + Khung MindClock AI Mentor (Avatar động, audio waveform visualizer phản hồi khi nói, trạng thái Socratic).
     - Bộ đếm thời gian tập trung (Focus/Pomodoro Timer).
     - Trò chuyện hỏi đáp Socratic qua `POST /v1/study/help`.
     - Chế độ thoại Gemini Live qua `POST /v1/study/live-token` với hộp kiểm đồng ý minh bạch.
  5. **Hồ sơ & Thời khóa biểu GDPT 2018**:
     - Chọn lớp 6–12, chọn môn học, thời khóa biểu 7 ngày, theo dõi XP/streak, đồng bộ PostgreSQL/SQLite.

## 2. Tiêu chí chấp nhận (Acceptance Criteria)
- **AC-01:** Vòng quay ngủ-dậy 24h hoạt động mượt mà, tính đúng thời lượng ngủ giữa giờ ngủ và giờ dậy (kể cả qua nửa đêm), lưu thành công vào API `/v1/alarms`.
- **AC-02:** Chuông Bermuda phát chuẩn từ backend (`/demo/bermuda.mp3`), Dừng khẩn cấp một chạm tắt âm ngay lập tức.
- **AC-03:** Khung ảnh bài làm cho phép mở camera hoặc tải ảnh, hiển thị animation quét laser AI, chấm bài bằng Gemini Vision thật và hiển thị kết quả chi tiết.
- **AC-04:** Không gian học Meet hiển thị 2 khung video call trực quan, thanh điều khiển mic/cam/giơ tay, bộ đếm giờ tập trung, và chat Socratic phản hồi từ Gemini.
- **AC-05:** Responsive 100% trên cả PC (có chế độ mô phỏng khung điện thoại) và màn hình điện thoại Android thật/máy ảo. Không có nút chết hay lỗi JavaScript.
- **AC-06:** Toàn bộ test pytest backend (13/13) tiếp tục pass không hồi quy.
