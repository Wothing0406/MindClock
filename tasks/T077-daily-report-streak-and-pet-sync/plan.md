# Kế hoạch thực hiện T077

## Điểm bắt đầu

- Backend FastAPI + SQLAlchemy (`services/api/app/{db/models.py,schemas.py,services/progression.py,services/commitment_group_service.py,routes/v1.py}`), Alembic ở `0007_local_auth_accounts`.
- Flutter (`app/lib/`) có `TodayScreen`, `TodayPetCard`, `ProfileProgressCard`, `PersonalFlowViewModel`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T077-daily-report-streak-and-pet-sync/` trước khi sửa code | `check_task_records.py` hợp lệ | [x] |
| 2 | Backend: thêm `DailyReport` + migration `0008`, nâng cấp `progression.py` (`streak-v2`), fix `commitment_group_service.py` + `record_daily_report`, thêm endpoint `POST /v1/progress/daily-report` & `GET /v1/progress/daily-reports` và mở rộng `GET /v1/progress/summary` | `pytest` pass cho SQLite + migration | [x] |
| 3 | Flutter: cập nhật `personal_flow_models.dart`, `personal_flow_repository.dart`, `remote/debug_fixture`, `personal_flow_view_model.dart`, thêm `flame` icon và tạo `today_streak_card.dart`, `daily_report_sheet.dart`, `streak_detail_sheet.dart`, nối `TodayScreen`, `ProfileProgressCard`, `TodayPetCard`, `MindClockShellScreen` | `flutter analyze` & `dart analyze` 0 lỗi | [x] |
| 4 | Cập nhật docs canonical (`13-tien-do...md`, `04-hop-dong-api.md`, `13-nhom-cam-ket...md`) + thêm `test_daily_report_streak.py` và `app/test/t077_daily_report_streak_test.dart` | Docs links + contract tests đồng bộ | [x] |
| 5 | Chạy toàn bộ test backend + Flutter + script kiểm tra repo và ghi `tests.md`, `handoff.md` | Toàn bộ unit/widget/API test xanh | [x] |

## Rủi ro và đường lui

- **Rủi ro lệch timezone / nộp trùng báo cáo cuối ngày:** Dùng thời điểm server UTC đổi sang `user.time_zone` và `UniqueConstraint('user_id', 'local_date')` + `XpLedger` unique `(user_id, source_type, source_id, reason)`.
- **Đường lui:** Các trường mới trên `ProgressSummary` và tham số mới trên `TodayScreen`/`TodayPetCard` đều optional/mặc định an toàn; migration `0008` có đầy đủ `upgrade`/`downgrade`.
