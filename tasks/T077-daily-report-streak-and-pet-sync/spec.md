# Đặc tả T077 — Streak theo ngày, Báo cáo ngày & Xem chi tiết Streak

## Quyết định kiến trúc & mâu thuẫn đã xử lý

1. **Chuẩn hóa cách tính ngày Streak (`streak-v2`):**
   - Trước T077, `GET /v1/progress/summary` chỉ đếm `XpLedger.reason == 'challenge_correct'`, bỏ sót `photo_challenge_correct`, phiên học `study_time_v0_1`, và chưa có Báo cáo ngày.
   - Từ T077, một ngày theo múi giờ tài khoản (`Asia/Ho_Chi_Minh` mặc định, xác định từ `now_utc` của server) được ghi nhận giữ streak khi có **ít nhất một** hoạt động hợp lệ: hoàn thành **Báo cáo ngày** (`daily_reports` / `daily_report`), hoặc hoàn thành câu ôn sáng (`challenge_correct`, `photo_challenge_correct`), hoặc hoàn thành phiên học hợp lệ (`study_time_v0_1`). Nhiều hoạt động trong cùng một ngày chỉ tính **1 ngày streak** (`local_date` duy nhất).
   - Giữ nguyên nguyên tắc công bằng: chưa hoàn thành hôm nay vẫn giữ chuỗi tới hết hôm qua; không trừ EXP khi lỡ ngày; không khuyến khích thức khuya để cứu chuỗi; AI/client không tự cộng điểm.
2. **Sửa lỗi streak Pet nhóm (`CommitmentGroupService._pet_summary`):**
   - Trước T077, `_pet_summary` lọc `care_kind == 'study_care'`, làm `morning_challenge` (+20 EXP) không tăng `currentStreakDays` / `totalCareDays`.
   - Sửa `_pet_summary` tính ngày chăm trên toàn bộ `care_kind` hợp lệ (`study_care`, `morning_challenge`, `daily_report`), đồng thời bổ sung `record_daily_report` (`+10 EXP nhóm`, 1 lần/ngày/nhóm/người).

## Tiêu chí nghiệm thu (Acceptance Criteria)

- **AC-01 (Báo cáo ngày = 1 ngày Streak, idempotent & server-authoritative):** `POST /v1/progress/daily-report` (auth bắt buộc, `extra='forbid'`, hỗ trợ `Idempotency-Key`) tổng hợp `studyMinutes` và `challengeCompleted` từ DB của owner trong `localDate` hiện tại theo timezone server, lưu `daily_reports` (`UNIQUE(user_id, local_date)`), cộng `+5 XP` đúng 1 lần/ngày qua `XpLedger` và chiếu sang `CommitmentGroupService.record_daily_report`. Gửi lại cùng ngày cập nhật ghi chú/cảm nhận nhưng không cộng XP hoặc streak lần thứ 2.
- **AC-02 (API Xem Streak chi tiết & lịch sử Báo cáo ngày):** `GET /v1/progress/summary` giữ nguyên toàn bộ trường cũ (`streakKind='review_days'`, `xp`, `level`, `streak`, ...) và bổ sung `streakPolicyVersion='streak-v2'`, `todayCompleted`, `todayReportSubmitted`, `bestStreak`, `totalActiveDays`, `todaySources`, `recentDays` (14 ngày gần nhất theo timezone tài khoản). `GET /v1/progress/daily-reports` trả nhật ký báo cáo ngày owner-only (A/B cô lập).
- **AC-03 (UI Trending Streak Card, Sheet Báo cáo ngày & Xem chi tiết trên Flutter):**
  - `TodayScreen` hiển thị `TodayStreakCard` (ngọn lửa vector `MindClockIconKind.flame`, không dùng emoji hệ thống, số ngày streak lớn, trạng thái hôm nay `Đã giữ hôm nay` / `Chưa giữ hôm nay`, dải 7 ngày gần nhất, nút `Hoàn thành báo cáo hôm nay` và `Xem chuỗi`).
  - `DailyReportSheet` tự tổng hợp số liệu ngày (phút tập trung, việc To-Do xong, câu sáng), cho chọn cảm nhận (`Tập trung tốt` / `Vừa sức` / `Hơi mệt`) + ghi chú, nộp thật qua `PersonalFlowViewModel.submitDailyReport` và làm mới cả `TodayStreakCard` lẫn `TodayPetCard`.
  - `StreakDetailSheet` hiển thị chuỗi hiện tại, kỷ lục, lịch 14 ngày chạm từng ngày để xem nguồn (`Báo cáo ngày`, `Tự học`, `Câu ôn sáng`, `+EXP`) và nhật ký các Báo cáo ngày đã nộp. `ProfileProgressCard` cũng đồng bộ hiển thị streak mở rộng và nút xem lịch sử.
  - Đáp ứng `320dp` + chữ `200%`, Reduce Motion, 0 màu hex thô ngoài `MindClockTheme`.
- **AC-04 (Docs & Quality Gate):** Cập nhật `docs/01-product/13-tien-do-va-cong-dong-trien-khai.md`, `docs/02-engineering/04-hop-dong-api.md`, `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, migration `0008_add_daily_reports.py`; toàn bộ `pytest`, `flutter test`, `flutter analyze`, `dart analyze`, `check_docs_links.py`, `check_task_records.py` đều xanh.
