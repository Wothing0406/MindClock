# T087 — Ngân Hàng Chuyển Số 10k+ Biến Thể Theo Lớp & Đánh Nhanh Thẻ Bài Arena

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Bổ sung bộ sinh câu hỏi chuyển số theo tham số (`_generate_parametric_items`) cho `TOAN`, `VAT_LY`, `HOA_HOC` khớp đúng `Lớp 10 / 11 / 12` và tuần học thực tế, tạo hàng chục nghìn biến thể câu hỏi trắc nghiệm & đề ngắn không trùng lặp ở `GET /v1/challenges/next`.
  2. Bổ sung 4 thẻ **Chọn nhanh 1 chạm** (`arena-quick-card-0..3`) trong `ArenaScreen` giúp người chơi chọn thẻ đáp án và kích hoạt bộ chiêu ngay trên điện thoại mà vẫn giữ nguyên ô tự luận truyền thống.
- **Nguồn yêu cầu:** Yêu cầu hoàn thiện toàn bộ task trước khi xuất APK và push GitHub bản tải (`27/11/2026`).
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa:**
  - `services/api/app/services/subject_memory_service.py`, `services/api/tests/test_t087_parametric_10k_questions.py`
  - `app/lib/domain/game/solo_training_question_bank.dart`, `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/test/t087_arena_quick_cards_test.dart`
- **Liên quan:** Kế thừa `T083`, `T086`.
- **Source refs đã đọc:** `services/api/app/services/subject_memory_service.py`, `app/lib/domain/game/solo_training_question_bank.dart`.
- **Điểm tiếp tục:** Kiểm tra trực tiếp trên máy Android thật sau khi cài bản `dist/apk/mindclock-android.apk` / GitHub Releases `v1.0.0`.

## Cổng trước coding

- [x] Đã kiểm tra cơ chế `build_quick_morning_challenge` và `gradeSoloTrainingSubmission` để giữ nguyên tính đúng đắn đáp án.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và test xanh.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
