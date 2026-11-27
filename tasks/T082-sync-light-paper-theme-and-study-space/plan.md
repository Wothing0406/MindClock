# Kế hoạch thực hiện T082

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T082-sync-light-paper-theme-and-study-space/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Đồng bộ lại màu sáng `mc.surface`/`mc.paper`/`mc.primarySoft` trên `TodayScreen`, `AlarmConfigScreen`, `CircularSleepClockPicker`, `CommitmentGroupScreen`, `FloatingMiniPetOverlay`, `WelcomeScreen`, `StudySpaceScreen`, `StudyCommunitySheet` | Không còn khối đen lạc tông, mọi test cũ pass | [x] |
| 3 | Bổ sung định hướng Gia sư Socratic khóa giải hộ trong `StudySpaceScreen` & Bàn học nhóm gọn trong `StudyCommunitySheet` | Test widget `t082` pass ở `320dp 200%` | [x] |
| 4 | Chạy `dart analyze --fatal-infos` + toàn bộ `flutter test --no-pub -j 1` + `check_docs_links.py` / `check_task_records.py` | Toàn bộ cổng xanh | [x] |
