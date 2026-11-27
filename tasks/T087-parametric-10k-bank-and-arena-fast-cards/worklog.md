# Nhật ký thực hiện T087

- `2026-11-27`: Khởi tạo hồ sơ T087 để hoàn thiện tính năng chuyển số 10k+ biến thể và thẻ đánh nhanh Arena trước khi xuất APK & push GitHub.
- `2026-11-27`: Đã triển khai `_generate_parametric_items` (Toán/Lý/Hóa theo lớp 10–12) và `SoloTrainingQuestionBank.quickChoicesFor` + 4 thẻ chọn nhanh 1 chạm trong `ArenaScreen`. Thay `ActionChip` ở `arena_screen.dart` bằng `MindClockButton` để không phụ thuộc `Material` ancestor. Toàn bộ `93 passed, 10 skipped` pytest và `183 passed` Flutter test xanh.
