# Kế hoạch thực hiện T051

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Bổ sung câu seed THPT 10–12 vào `services/api/app/db/seed.py` và sửa FK cleanup trong `DELETE /v1/me` (`services/api/app/routes/v1.py`) + thêm test trong `services/api/tests/test_api_v1.py` và `services/api/tests/test_pvp_matchmaking.py` | `pytest` PASS 100% trên PostgreSQL 16 | [x] |
| 2 | Mở rộng `PersonalFlowRepository`, `RemotePersonalFlowRepository`, `DebugFixturePersonalFlowRepository`, `PersonalFlowViewModel` hỗ trợ `syncProfile`, `recordConsent`, `syncTimetable`, `deleteAccount` và `GuestWorkspaceRepository.clearScopedAccountData` | `flutter analyze` 0 lỗi | [x] |
| 3 | Sửa `TimetableProfileScreen` (giữ `alias`/`avatarId`/`selfAssessments`/`confirmedPlan`, sửa thông báo AI TKB) và nối đồng bộ hồ sơ/TKB/consent ở `MindClockShellScreen` | Không mất dữ liệu onboarding khi sửa TKB/hồ sơ | [x] |
| 4 | Bổ sung nút & xác nhận 2 bước `Xóa tài khoản & dữ liệu trực tuyến` vào `MeGuestScreen` (`me-delete-account-btn` → `me-delete-account-confirm`), chỉ hiện khi đã đăng nhập và giữ nguyên báo thức local | Widget test & integration loopback PASS | [x] |
| 5 | Tạo `app/test/account_sync_and_delete_test.dart`, chạy full `flutter test`, `flutter analyze --no-pub`, `pytest` live PostgreSQL 16, `check_docs_links.py`, `check_task_records.py`, commit & push `origin/main` | 100% test PASS, SHA khớp `origin/main` | [x] |
