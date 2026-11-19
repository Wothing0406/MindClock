# Kế hoạch thực hiện T059

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật `StudyFocusSessionSnapshot` hỗ trợ `timingMode` (`countdown`/`candle_countup`), bỏ trần 120 phút, lọc môn theo `StudyProfile` | Unit test model + ViewModel xanh | [x] |
| 2 | Tạo widget `StudyCandleTimer` & cập nhật `StudySpaceScreen` | Widget test 320dp/200% & Reduce Motion xanh | [x] |
| 3 | Tích hợp AI pre-generate thử thách cá nhân hóa theo TKB + Profile trên `AlarmConfigScreen` | Test API + fallback offline xanh | [x] |
| 4 | Full test, kiểm script docs/task, cập nhật docs & push `origin/main` | Test pass, SHA push xác minh | [x] |
