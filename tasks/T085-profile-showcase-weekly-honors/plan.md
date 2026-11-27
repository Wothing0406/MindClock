# Kế hoạch thực hiện T085

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T085-profile-showcase-weekly-honors/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Thêm `GET /v1/profile/showcase` và `GET /v1/leaderboard/weekly` trong `v1.py` + `profile_showcase_service.py` + `test_t085_profile_showcase_and_weekly_leaderboard.py` | `pytest` pass đầy đủ showcase & weekly leaderboard | [x] |
| 3 | Cập nhật `PersonalFlowModels`, `PersonalFlowRepository`, `RemotePersonalFlowRepository`, `DebugFixturePersonalFlowRepository`, `PersonalFlowViewModel`, `MeGuestScreen` + `weekly_leaderboard_sheet.dart` | `flutter analyze` & `flutter test` pass ở `320dp 200%` | [x] |
| 4 | Viết `t085_profile_showcase_test.dart`, chạy `pytest` + `flutter test` + repo scripts | Toàn bộ cổng xanh | [x] |
