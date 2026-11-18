# Kế hoạch thực hiện T049

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo `app/lib/domain/models/daily_study_plan.dart` và `app/lib/domain/services/rule_based_plan_generator.dart` | Sinh tối đa 3 việc, 10–25 phút, `rule-plan-v0.1`, tôn trọng trạng thái câu duyệt | [x] |
| 2 | Cập nhật `app/lib/domain/models/study_profile.dart` lưu `selfAssessments` và `confirmedPlan` (tương thích ngược JSON cũ) | `fromJson`/`toJson` round-trip sạch | [x] |
| 3 | Cập nhật `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart` (chọn mức tự đánh giá theo môn, xem trước bản kế hoạch nháp rule-based, bỏ câu `Báo thức tự động: 06:00`, hỗ trợ xác nhận hoặc bỏ qua kế hoạch) | Giữ nguyên các `ValueKey` cũ, 0 raw hex/emoji | [x] |
| 4 | Cập nhật `app/lib/ui/features/guest_shell/views/today_screen.dart` hiển thị thẻ `Kế hoạch hôm nay` đã xác nhận | Hiển thị rõ ở 320dp 200% và 390×844 | [x] |
| 5 | Viết `app/test/onboarding_plan_draft_test.dart`, chạy full `flutter test --no-pub`, `dart analyze lib test`, `check_docs_links.py`, `check_task_records.py`, commit & push `origin/main` | 69/69 tests PASS, 0 analyze issues, SHA khớp `origin/main` | [x] |
