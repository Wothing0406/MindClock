# Kế hoạch thực hiện T084

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T084-group-busy-day-streak-shield/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Thêm model `CommitmentGroupBusyDay`, migration `0010`, schema, endpoint `POST /v1/commitment-groups/{group_id}/busy-today` và logic bảo lưu chuỗi trong `CommitmentGroupService` | `pytest` pass kịch bản 2 lượt/tháng & bảo lưu chuỗi qua nhiều ngày | [x] |
| 3 | Cập nhật Flutter `CommitmentPetSummary`, `CommunityRepository`, `RemoteCommunityRepository`, `DebugFixtureCommunityRepository`, `CommitmentGroupScreen`, `TodayPetCard` | Render & báo bận hoạt động không overflow `320dp 200%` | [x] |
| 4 | Viết `test_t084_group_busy_days.py` & `t084_group_busy_day_test.dart`, chạy `pytest` + `flutter test` | Toàn bộ test xanh | [x] |
| 5 | Cập nhật `tests.md`, `handoff.md` và kiểm tra docs/tasks | Toàn bộ cổng xanh | [x] |
