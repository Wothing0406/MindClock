# Kế hoạch thực hiện T050

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Guard `Base.metadata.create_all` trong `services/api/app/main.py` khi đã có bảng `alembic_version` | Không tạo bảng lệch `alembic_version` trên PostgreSQL | [x] |
| 2 | Thêm `_isolated_postgres_db(pg_url)` vào `test_migrations_and_data_invariants.py` và `test_pvp_matchmaking.py` | Chạy đúng lệnh người dùng với `.../mindclock` PASS 12/12 & không đụng DB `mindclock` | [x] |
| 3 | Sửa `pvp_match_service.py` (void round sang round kế tiếp, ẩn `grade_status` khi mới 1 bên nộp, xóa 4 import thừa) & cập nhật assertion trong `test_pvp_matchmaking.py` | 49/49 pytest PASS (0 skipped) trên live PostgreSQL 16 | [x] |
| 4 | Sửa `/v1/timetable/parse-image` → `/timetable/parse-image` trong `personal_api_client.dart`, bỏ `Color(0xFF22C55E)` trong `today_screen.dart`, thêm test URI trong `timetable_ocr_and_realtime_clock_test.dart` và thêm `.vscode/settings.json` | 70/70 Flutter tests PASS, `flutter analyze` 0 lỗi, 0 raw hex color | [x] |
| 5 | Chạy `check_docs_links.py`, `check_task_records.py`, stage đúng file T050, commit & push `origin/main` | Remote khớp SHA | [x] |
