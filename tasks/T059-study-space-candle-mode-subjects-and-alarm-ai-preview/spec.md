# Đặc tả kỹ thuật T059

1. **AC-01 (Study Space lọc đúng môn từ StudyProfile):** Danh sách môn gợi ý và bộ chọn môn chỉ hiển thị các môn trong `StudyProfile.selectedSubjectCodes` (chỉ fallback đầy đủ nếu hồ sơ chưa có môn).
2. **AC-02 (Bỏ giới hạn 120p & Chế độ Đốt nến / Đếm giờ tự do):** Cho phép `countdown` dài (>120 phút) và chế độ `candle_countup` đếm giờ tiến từ `00:00`, hiển thị ngọn nến đốt cháy động theo phút học (tôn trọng Reduce Motion) và cảnh báo nghỉ ngơi trung tính khi học liên tục dài; EXP giữ nguyên quy tắc an toàn ở server.
3. **AC-03 (Màn cài báo thức AI cá nhân hóa sẵn câu):** `AlarmConfigScreen` tự động nạp/gọi API tạo bản xem trước chủ đề & câu thử thách dựa trên ngày lặp báo thức + TKB + Profile (có fallback rule-based offline).
