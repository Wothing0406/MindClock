# Kế hoạch thực hiện T059

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật `StudyFocusSessionSnapshot` hỗ trợ `timingMode` (`countdown`/`candle_countup`), bỏ trần 120 phút, lọc môn theo `StudyProfile` | Unit test model + ViewModel xanh | [ ] |
| 2 | Tạo widget `StudyCandleTimer` & cập nhật `StudySpaceScreen` | Widget test 320dp/200% & Reduce Motion xanh | [ ] |
| 3 | Tích hợp AI pre-generate thử thách cá nhân hóa theo TKB + Profile trên `AlarmConfigScreen` | Test API + fallback offline xanh | [ ] |
| 4 | Full test, kiểm trên emulator, cập nhật docs & push `origin/main` | Test pass, SHA push xác minh | [ ] |
