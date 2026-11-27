# Bàn giao nhiệm vụ T085

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  - Triển khai `profile_showcase_service.py` và 2 route `GET /v1/profile/showcase`, `GET /v1/leaderboard/weekly` với opt-in `weekly_leaderboard_opt_in`, ẩn hoàn toàn giờ dậy/TKB/email.
  - Khôi phục đầy đủ `PersonalFlowViewModel` (`T078`, `T083` + `T085`) và nâng cấp `MeGuestScreen` với banner bình minh, khung bậc mùa quanh avatar, danh hiệu tuần, 3 ô Dấu ấn, thẻ các nhóm giữ chuỗi, và `weekly_leaderboard_sheet.dart`.
- **Test đã chạy (`2026-11-27`):** `pytest -q` (`92 passed, 10 skipped`), `flutter analyze --no-pub` (0 lỗi), `flutter test --no-pub -j 1` (`181 passed`).
- **Điểm tiếp tục chính xác:** Kiểm tra giao diện trên máy Android thật qua bản `dist/apk/mindclock-android.apk`.
- **Git:** Chưa commit/push theo yêu cầu tạm hoãn push của người dùng.
