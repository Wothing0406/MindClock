# Kế hoạch thực hiện T092

## Điểm bắt đầu

- Nhánh `main` tại `80999bd` (sau khi hoàn tất `T091`).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T092-*` và rà soát toàn bộ test hiện hữu | Không phá vỡ key kiểm thử cũ | [x] |
| 2 | Thêm `AlarmOccurrenceRecord` (`scheduled`, `ringing`, `question_open`, `submitted`, `completed`, `skipped`, `dismissed`, `hasSyncError`) vào `GuestWorkspace` + `GuestWorkspaceViewModel`; sửa idempotency cho `submitMcqAnswer` / `submitMiniQuizAnswers` và khóa double-submit trong `PersonalFlowViewModel` | Unit logic chuyển trạng thái & giữ key qua restart/timeout chuẩn xác | [x] |
| 3 | Đồng bộ `MindClockShellScreen`, tinh gọn `PracticeSessionScreen` (đưa câu hỏi lên đầu, ẩn nút lặp khi đang làm câu chuông sáng, bỏ thẻ Đăng xuất & nút Không gian học lặp, làm sạch chữ kỹ thuật), cập nhật `TodayScreen` hiển thị 4 trạng thái rõ ràng và giới hạn `FloatingMiniPetOverlay` ở tab Hôm nay | Giao diện gọn, câu hỏi ưu tiên diện tích đầu màn | [x] |
| 4 | Viết `app/test/t092_alarm_occurrence_and_clean_practice_test.dart`, đồng bộ assertion ở `t062`, chạy `flutter analyze`, bộ regression test báo thức/cá nhân, kiểm tra scripts, commit và push `T092` | Mọi bài kiểm thử xanh, commit & push sạch | [x] |

## Rủi ro và đường lui

- Đã đồng bộ `t062_offline_bank_alarm_and_arena_timer_test.dart` (`TC-06/07`) theo quy tắc mới: khi đang trong phiên câu sáng từ chuông reo (`inOpenAlarmSession`), giao diện ẩn hàng nút khởi động lại để người học tập trung hoàn toàn vào câu hỏi chính.
