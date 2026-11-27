# Nhật ký làm việc T092

- 2026-11-27 (Vòng 1): Khởi tạo `T092`, xây dựng `AlarmOccurrenceRecord` lưu trong `GuestWorkspace`, nối vòng đời occurrence giữa `GuestWorkspaceViewModel`, `PersonalFlowViewModel` và `MindClockShellScreen`. Bổ sung khóa chống nộp kép và giữ `Idempotency-Key` cho `submitMcqAnswer` / `submitMiniQuizAnswers`.
- 2026-11-27 (Vòng 2): Đưa thẻ câu hỏi lên đầu `PracticeSessionScreen`, bỏ `AccountAuthCard` và nút Không gian học lặp khỏi tab `Luyện tập`, giới hạn `FloatingMiniPetOverlay` chỉ hiển thị ở tab `Hôm nay` kèm đệm đáy 76dp, cập nhật `TodayScreen` phân biệt rõ trạng thái occurrence hôm nay. Đồng bộ test `t062` (`TC-06/07`) khi ẩn nút khởi động lại trong phiên chuông sáng đang mở.
