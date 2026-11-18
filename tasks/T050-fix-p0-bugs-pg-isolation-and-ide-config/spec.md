# Đặc tả T050 — Sửa nhóm lỗi P0, cô lập DB test PostgreSQL và cấu hình IDE

## Yêu cầu kiểm chứng được

| ID | Vấn đề gốc | Hành vi sau khi sửa | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | `pytest` live PG chạy `downgrade('base')` trực tiếp lên DB dev `mindclock` (có `alembic_version=0002` + 7 bảng PvP do `create_all`) gây `DependentObjectsStillExist` và phá DB đang chạy | `main.py` không chạy `create_all` khi đã có `alembic_version`; 2 test live PG tự tạo DB tạm cô lập `mindclock_pytest_<hex>` và xóa sạch sau test → chạy lệnh pytest với `POSTGRES_TEST_URL=.../mindclock` PASS 100% và giữ nguyên vẹn DB `mindclock` | TC-01 |
| AC-02 | `PersonalApiClient.parseTimetableImage` gọi `/v1/timetable/parse-image` qua `_resolvePath` làm thành `/v1/v1/timetable/parse-image` (404) | Gọi đúng `POST /v1/timetable/parse-image` (chỉ 1 lần `/v1`), có unit test xác minh URI chính xác | TC-02 |
| AC-03 | Trong `pvp_match_service.py`: round `void` do `uncertain` làm trận treo mãi ở round 1; người nộp đầu tiên bị lộ `grade_status` trước khi đối thủ nộp; còn 4 import thừa | Round `void` tự tạo round kế tiếp (`round_no + 1`, giữ nguyên HP/armor/qi) hoặc kết thúc gọn nếu đã ở round 6; người nộp đầu nhận `grade_status='grading_pending'` & `feedback_vi=''` cho tới khi đủ 2 bài nộp; xóa 4 import thừa | TC-03 |
| AC-04 | `today_screen.dart:200` còn hardcode `Color(0xFF22C55E)` | Dùng token `mc.primary` từ `MindClockTheme`, toàn bộ `app/lib/` ngoài `mindclock_theme.dart` có 0 raw `Color(0x...)` | TC-04 |
| AC-05 | Bảng Problems IDE báo 289 cảnh báo giả do thiếu `.vscode/settings.json` | Thêm `.vscode/settings.json` trỏ đúng `services/api/.venv`, `extraPaths: ["services/api"]` và `.local-sdk/flutter` | TC-05 |
