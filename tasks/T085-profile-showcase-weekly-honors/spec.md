# Đặc tả T085 — Profile Showcase & Bảng Xếp Hạng Học Bá Tuần

## Acceptance Criteria

- **AC-01 (API Profile Showcase & Vinh danh tuần):** `GET /v1/profile/showcase` trả về `seasonRank` (tính từ XP thật), `equippedTitleVi` (từ thành tích tuần thật), `earlyBirdDaysThisWeek` (số buổi sáng hoàn thành thử thách trong 7 ngày), `topSubject` (từ `SubjectMemory`), `stamps` (3 ô dấu ấn: Chuỗi, Dậy sớm tuần, Sở trường môn), và `groups` (danh sách tất cả nhóm giữ chuỗi đang tham gia).
- **AC-02 (API Bảng xếp hạng Học bá tuần theo môn):** `GET /v1/leaderboard/weekly?subject=TOAN` xếp hạng opt-in công khai theo điểm tuần & tỷ lệ đúng môn, không lộ giờ dậy hay TKB.
- **AC-03 (UI MeGuestScreen Showcase chuẩn nền sáng):** Hiển thị banner/ảnh bìa trang vở, Avatar + Khung bậc mùa, Danh hiệu tuần, 3 ô Dấu ấn, thẻ các nhóm chuỗi, trình độ + môn theo học, và mở được Bảng xếp hạng Học bá tuần; không overflow ở `320dp 200%`.
