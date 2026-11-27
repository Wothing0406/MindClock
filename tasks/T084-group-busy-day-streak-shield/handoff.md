# Bàn giao nhiệm vụ T084

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  1. Thêm bảng & migration `0010_add_group_busy_days.py` (`CommitmentGroupBusyDay`) cùng endpoint `POST /v1/commitment-groups/{group_id}/busy-today` (giới hạn 2 lượt/tháng).
  2. Cập nhật `CommitmentGroupService._pet_summary` & `_streak` hỗ trợ bảo lưu nguyên `Chuỗi N` qua ngày có bạn báo bận (nếu các thành viên không bận còn lại đều hoàn thành).
  3. Cập nhật Flutter `CommitmentGroupScreen` & `TodayPetCard` với nút `Báo bận hôm nay` + banner bảo lưu Chuỗi không lộ người bận.
- **Điểm tiếp tục chính xác:** Làm tiếp **T085** (Profile Showcase + Vinh danh tuần & Khung bậc mùa) và **T086** (Micro-Check Không gian học + Game Đấu thẻ bài 75% Stage).
- **Git:** Chưa commit/push.
