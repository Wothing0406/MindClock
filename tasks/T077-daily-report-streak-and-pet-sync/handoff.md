# Bàn giao nhiệm vụ T077

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  - Nâng cấp cơ chế streak theo ngày (`streak-v2` trong `services/api/app/services/progression.py`): mỗi ngày theo múi giờ tài khoản tính tối đa 1 ngày streak khi có Báo cáo ngày (`daily_reports`) hoặc hoạt động học/câu sáng hợp lệ (`challenge_correct`, `photo_challenge_correct`, `study_time_v0_1`, `daily_report`), trả về `bestStreak`, `totalActiveDays`, `todayCompleted`, `todayReportSubmitted`, `todaySources`, và lịch `recentDays` 14 ngày.
  - Bổ sung bảng `daily_reports` + migration `0008_add_daily_reports.py`, endpoint `POST /v1/progress/daily-report` (hoàn thành 1 báo cáo = giữ 1 ngày streak + 5 XP duy nhất 1 lần/ngày + đồng bộ chăm Pet nhóm) và `GET /v1/progress/daily-reports`.
  - Sửa `CommitmentGroupService._pet_summary` để tính streak nhóm trên mọi `care_kind` hợp lệ (`study_care`, `morning_challenge`, `daily_report`).
  - Bổ sung trên Flutter: `TodayStreakCard` (ngọn lửa vector, dải 7 ngày, trạng thái hôm nay), `DailyReportSheet` (tổng hợp việc/học/câu sáng, chọn cảm nhận, ghi chú, nút cố định dưới cùng), `StreakDetailSheet` (lịch 14 ngày chạm từng ngày xem nguồn + nhật ký Báo cáo ngày), đồng bộ `ProfileProgressCard` và tự reload `TodayPetCard`.
  - Cập nhật docs canonical (`13-tien-do-va-cong-dong-trien-khai.md`, `04-hop-dong-api.md`, `13-nhom-cam-ket-va-pet-ledger.md`).
- **File/code/docs thay đổi:** Chi tiết liệt kê trong `tasks/T077-daily-report-streak-and-pet-sync/README.md`.
- **Test đã chạy:** Xem `tests.md` (backend `pytest` và toàn bộ Flutter `analyze` + `flutter test` + scripts).
- **Test chưa chạy/giới hạn:** 10 test PostgreSQL opt-in (do Docker Desktop chưa chạy) và build/verify trực tiếp trên Android Emulator/máy thật cho UI T077.
- **Rủi ro còn lại:** DB PostgreSQL đang chạy cần chạy `alembic upgrade head` lên `0008_add_daily_reports` trước khi phục vụ `/v1/progress/daily-report` trên môi trường server/Docker.
- **Điểm tiếp tục chính xác:** Bật Docker Desktop -> chạy `alembic upgrade head` trên PostgreSQL + chạy `MINDCLOCK_TEST_POSTGRES_ADMIN_URL=... pytest` -> test trực tiếp trên Emulator/máy Android -> cập nhật `README.md` sang `done` nếu đạt và commit/push theo quy trình.
- **Git:** Nhánh `main`, chưa commit/push trong lượt này.
