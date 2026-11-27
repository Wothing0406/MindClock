# Đặc tả T086 — Study Space Micro-Check & Arena 2D Card-Stage

## Acceptance Criteria

- **AC-01 (Study Space Micro-Check 60s):** Trong phiên học đang chạy (`StudySpaceScreen`), người học có thể mở nhanh thẻ **Micro-Check 60 giây** theo môn đang học để kiểm tra độ tỉnh táo & ghi nhớ bằng 1 câu trắc nghiệm nhanh, nhận phản hồi đúng/chưa đúng tức thì (không phạt XP/chuỗi).
- **AC-02 (Khóa Socratic trên MindClock AI):** Phần hỏi đáp AI yêu cầu người học chọn hoặc nhập **1 bước bạn đã tự thử** (`Khóa giải hộ`) trước khi gửi yêu cầu gợi ý để AI hướng dẫn Socratic thay vì làm hộ từ đầu.
- **AC-03 (Arena Stage 2D Card-Battle >= 75% & Charge Bar):** Sân đấu Arena hiển thị **Thanh Cảnh báo tụ chiêu** của đối thủ, hoạt cảnh lướt đòn/chắn đòn & nhãn sát thương bay nổi (tôn trọng Reduce Motion / Bỏ qua hiệu ứng), nút **Né & Chắn**, **Hồi phục** hoặc **Mở đề nhanh** song hành với bộ thẻ chiêu trong suốt ở dưới sân mà vẫn giữ tương thích toàn bộ test key hiện có (`arena-stage-compact`, `arena-stage-expanded`, `arena-action-basic`, `arena-submit-answer`) và không overflow ở `320dp 200%`.
