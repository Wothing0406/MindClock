# MindClock — Bộ sản phẩm Android (`product/`)

Thư mục này chứa bản đóng gói ứng dụng Android thực tế (`mindclock-android.apk`) và tài liệu tổng quan rõ ràng về giao diện, tính năng và logic hoạt động của **MindClock**.

## 1. File cài đặt Android
- **`product/mindclock-android.apk`** (đồng bộ với `dist/apk/mindclock-android.apk`)
- Yêu cầu: Android 8.0+ (API 26 trở lên), bật cài đặt từ nguồn không xác định khi cài trực tiếp file `.apk`.
- Kết nối backend mặc định: `https://api.ieltsoasis.site` (qua Docker API + PostgreSQL + Cloudflare Tunnel).

## 2. Luồng sử dụng & Giao diện chính

### A. Đăng nhập & Khởi tạo hồ sơ (`Welcome` → `Auth` → `Onboarding`)
1. **Chào mừng & Đăng nhập / Đăng ký**: Người dùng đăng ký hoặc đăng nhập bằng email + mật khẩu mạnh (không còn chế độ khách không đăng nhập).
2. **Thiết lập hồ sơ**: Chọn biệt danh, avatar, lớp học (THPT 10–12), các môn đang học, môn ưu tiên và mục tiêu cá nhân.

### B. Báo thức & Câu hỏi buổi sáng (`Hôm nay` & `Báo thức`)
1. **Hai kiểu báo thức**:
   - **Hẹn giờ thường**: Chỉ chọn giờ/phút, ngày lặp, âm thanh/rung. Khi reo có nút **Hoãn 5 phút** và **Tắt chuông**.
   - **Báo thức dậy học**: Chọn giờ ngủ – giờ dậy trên vòng tròn 24 giờ và gắn câu hỏi ôn tập buổi sáng theo lớp/môn/thời khóa biểu. Khi reo không có nút Hoãn; luôn có nút **Dừng khẩn cấp** 1 chạm.
2. **Trạng thái & Giới hạn mỗi ngày**:
   - Mỗi lần chuông đi qua vòng đời rõ ràng: `scheduled → ringing → question_open → submitted → completed | skipped | dismissed`.
   - Hoàn thành câu sáng rồi thì không bị hiện lại như chưa làm khi quay về màn `Hôm nay` hoặc mở lại app.
   - **Mỗi ngày chỉ tính tối đa 1 báo thức hoàn thành** (cộng thưởng XP & chuỗi ngày 1 lần/ngày); nếu đặt nhiều chuông trong ngày, các chuông tiếp theo chỉ reo và cho tắt trực tiếp.

### C. Không gian học (`Học tập trung`)
Tách thành 3 chế độ độc lập, không trộn lẫn:
1. **Học một mình**: Đồng hồ tập trung, mục tiêu phiên, ghi chú vướng mắc, tạm dừng, kết thúc.
2. **Học cùng MindClock AI**: Chat 1 ô nhập mượt mà (gửi nhanh bằng nút gửi hoặc phím Enter, có gợi ý nhanh, tùy chọn gửi ảnh đề bài hoặc nói câu hỏi, nghe giọng đọc lại).
3. **Học cùng bạn**: Tạo/vào phòng theo mã mời, cập nhật thành viên theo thời gian thực, chuyển quyền chủ phòng khi rời phòng, tự dọn phòng hết hạn. Camera và micro tắt mặc định.

### D. Đấu trường (`Đấu trường`)
- **Luyện đơn**: Chọn môn học, chọn nhân vật và bộ kỹ năng, trả lời câu hỏi đúng để tích năng lượng, tung chiêu tấn công, phòng thủ/hồi phục hoặc né đòn.
- **Đấu 1v1**: Ghép trận cùng câu hỏi và thang chấm công bằng.

## 3. Khởi chạy Backend bằng Docker
```bash
cd services/api
docker compose up -d --build
```
- API chạy tại cổng `8000`, PostgreSQL 16 tại cổng `5432` và Cloudflare Tunnel trỏ ra domain công khai.
