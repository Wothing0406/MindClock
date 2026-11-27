# Kế hoạch thực hiện T087

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T087-parametric-10k-bank-and-arena-fast-cards/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Thêm `_generate_parametric_items` trong `subject_memory_service.py` + `test_t087_parametric_10k_questions.py` | `pytest` pass | [x] |
| 3 | Thêm `quickChoicesFor` trong `solo_training_question_bank.dart` + thẻ 1 chạm trong `arena_screen.dart` + `t087_arena_quick_cards_test.dart` | `flutter test` pass | [x] |
| 4 | Chạy full verify, rebuild Docker & APK, đánh dấu hồ sơ, commit & push GitHub | Toàn bộ cổng xanh & đã push | [x] |
