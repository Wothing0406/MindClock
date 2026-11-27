# T092 — Máy trạng thái occurrence báo thức buổi sáng và tinh gọn Dashboard / Luyện tập

- **Trạng thái:** `verifying`
- **Mục tiêu:** Thiết lập một máy trạng thái duy nhất lưu trữ cục bộ cho từng lần chuông (`alarmId + occurrenceDate`: `scheduled → ringing → question_open → submitted → completed | skipped | dismissed` kèm cờ `hasSyncError`), chống hiện lại câu sáng đã hoàn thành hoặc tạo attempt trùng khi bấm nhiều lần / mất mạng / mở lại app, đồng thời dọn bỏ các thẻ lặp và thuật ngữ kỹ thuật trên màn Chuông, Hôm nay và Luyện tập.
- **Nguồn yêu cầu:** Task 1 trong đặc tả tái cấu trúc sản phẩm và 10 ảnh chụp màn hình thực tế của người dùng; `2026-11-27`.
- **Chủ sở hữu/reviewer:** AI Assistant / User.
- **Phạm vi file dự kiến:**
  - `app/lib/domain/models/alarm_occurrence.dart`
  - `app/lib/domain/models/guest_workspace.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/lib/ui/features/personal_flow/views/practice_session_screen.dart`
  - `app/lib/ui/features/community/views/today_pet_card.dart`
  - `app/test/t062_offline_bank_alarm_and_arena_timer_test.dart`
  - `app/test/t092_alarm_occurrence_and_clean_practice_test.dart`
- **Liên quan:** Sau `T091` (`80999bd`).
- **Source refs đã đọc:** `AGENTS.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/02-bao-thuc-android.md`, `docs/01-product/03-he-thiet-ke.md`.
- **Điểm tiếp tục:** Đã pass toàn bộ analyze + 17/17 bài kiểm thử báo thức/cá nhân; giữ `verifying` chờ kiểm thử AD01–AD09 trên máy Android vật lý. Chuyển sang task tiếp theo (`T093`) phân luồng Không gian học (`Học một mình` / `Học cùng MindClock AI` / `Học cùng bạn`).

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt trên môi trường dev/widget/contract; ghi rõ phần cần máy Android thật.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
