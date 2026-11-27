# Kế hoạch thực hiện T086

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T086-study-microcheck-and-arena-card-stage/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Cập nhật `StudySpaceScreen` thêm **Micro-Check 60 giây** & ô **Bước bạn đã tự thử** (Socratic step-lock) | Test Study Space + `t086` pass | [x] |
| 3 | Nâng cấp `ArenaStageWidget`, `ArenaSkillHand`, `ArenaScreen` với Thanh cảnh báo tụ chiêu & dock thẻ chiến đấu | Test `solo_arena_widget_test.dart`, `t065`, `t086` pass | [x] |
| 4 | Chạy full `pytest`, `flutter analyze`, `flutter test`, rebuild Docker API & APK | Toàn bộ cổng xanh | [x] |
