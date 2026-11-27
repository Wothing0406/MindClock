# Bàn giao nhiệm vụ T087

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  - Sinh câu hỏi chuyển số tham số (`TOAN`, `VAT_LY`, `HOA_HOC`) khớp lớp 10/11/12 & tuần học.
  - Thẻ đánh nhanh 1 chạm 4 phương án (`arena-quick-card-0..3`) trong `ArenaScreen`.
  - Rebuild Docker PostgreSQL API + xuất `dist/apk/mindclock-android.apk` + push `main` và tag release lên GitHub.
- **Test đã chạy (`2026-11-27`):** `pytest -q` (`93 passed, 10 skipped`), `flutter analyze --no-pub` (`0 issues`), `flutter test --no-pub -j 1` (`183 passed`).
- **Điểm tiếp tục chính xác:** Kiểm tra tải & cài thử APK từ GitHub Releases trên thiết bị Android thật.
- **Git:** Xem commit/tag trên nhánh `main` của `origin`.
