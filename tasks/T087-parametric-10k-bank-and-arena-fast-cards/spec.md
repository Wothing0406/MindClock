# Đặc tả T087 — Ngân hàng chuyển số & Đánh nhanh thẻ bài Arena

## Acceptance Criteria

- **AC-01 (Sinh biến thể chuyển số theo lớp & tuần):** `build_quick_morning_challenge` cho `TOAN`, `VAT_LY`, `HOA_HOC` sinh câu hỏi chuyển số tham số khớp `grade_level` (`Lớp 10`, `Lớp 11`, `Lớp 12`), các `seed_hint` khác nhau sinh các câu khác nhau với 4 đáp án không trùng và `correctOptionIndex` chính xác.
- **AC-02 (Đánh nhanh 1 chạm trong Đấu trường Arena):** `SoloTrainingQuestionBank.quickChoicesFor` trả về 4 thẻ phương án cho từng câu hỏi và `ArenaScreen` hiển thị `arena-quick-card-0..3` để chọn nhanh & kích hoạt chiêu mà không phá vỡ các ô nhập `arena-answer-input`, `arena-reasoning-input`.
