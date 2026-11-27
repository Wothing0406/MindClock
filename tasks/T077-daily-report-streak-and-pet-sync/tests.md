# Kế hoạch và kết quả kiểm thử T077

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Nộp `POST /v1/progress/daily-report` lần 1 trong ngày, gửi lại lần 2 cùng ngày, thử user B đọc A | Lần 1 cấp +5 XP, `streak == 1`, `todayCompleted == True`, `todayReportSubmitted == True`, cập nhật Pet nhóm; lần 2 chỉ update note (`xpAwarded == 0`, không nhân streak); user B cô lập (0 báo cáo của A) | `.\.venv\Scripts\python.exe -m pytest -q` (SQLite FastAPI TestClient, Windows) | Đạt trong `88 passed, 10 skipped` (`test_daily_report_streak.py` pass) — 27/11/2026 |
| TC-02 | AC-01 | Hoàn thành `morning_challenge` hoặc `study_session` >= 5p hoặc `daily_report` trong nhóm cam kết | `CommitmentGroupService._pet_summary` tính đủ `currentStreakDays`, `totalCareDays`, `totalXp` cho mọi `care_kind` hợp lệ | `.\.venv\Scripts\python.exe -m pytest -q` | Đạt trong `88 passed, 10 skipped` — 27/11/2026 |
| TC-03 | AC-02 | Chuỗi nhiều ngày liên tiếp từ `XpLedger` (`challenge_correct`, `photo_challenge_correct`, `study_time_v0_1`, `daily_report`) + `DailyReport` | `streak`, `bestStreak`, `totalActiveDays`, `recentDays` (14 ngày) tính chính xác | `.\.venv\Scripts\python.exe -m pytest -q` | Đạt trong `88 passed, 10 skipped` — 27/11/2026 |
| TC-04 | AC-03 | Render `TodayStreakCard`, mở `DailyReportSheet`, nộp báo cáo và mở `StreakDetailSheet` trên Flutter (gồm cả `320dp` chữ `200%` + Reduce Motion) + HTTP contract test | Hiển thị đúng số streak, 7 ngày / 14 ngày, nộp cập nhật ngay thành `1 ngày Streak` / `Đã giữ hôm nay`, không overflow ở `320dp` `200%` | `flutter test --no-pub -j 1` (Windows) | Sẽ xác nhận lại toàn bộ suite ở bước chạy cuối — 27/11/2026 |
| TC-05 | AC-04 | Toàn bộ regression suite (`pytest`, `flutter test`, `dart analyze`, `check_docs_links`, `check_task_records`) | 0 lỗi phân tích tĩnh, toàn bộ unit/widget/API test không phụ thuộc Docker xanh | CLI local Windows | Đang chạy lượt cuối tổng hợp — 27/11/2026 |

## Giới hạn môi trường hiện tại

- 10 test PostgreSQL opt-in trong `pytest` bị `skipped` vì Docker Desktop trên máy chưa bật (`npipe:////./pipe/dockerDesktopLinuxEngine` chưa chạy) và biến `MINDCLOCK_TEST_POSTGRES_ADMIN_URL` chưa thiết lập; chưa chạy kiểm thử live APK trên Android Emulator/máy thật cho màn T077.
