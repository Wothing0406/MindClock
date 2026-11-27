# Đặc tả T084 — Ngày Bận & Bảo Lưu Chuỗi Nhóm

## Acceptance Criteria

- **AC-01 (Báo bận giới hạn 2 lượt/tháng):** Thành viên `active` trong nhóm gọi `POST /v1/commitment-groups/{group_id}/busy-today` được tối đa 2 lần trong cùng `YYYY-MM`. Vượt quá trả `409 BUSY_QUOTA_EXCEEDED`.
- **AC-02 (Bảo lưu Chuỗi N không tụt về 0):** Khi trong ngày `t`, thành viên B báo bận và toàn bộ thành viên còn lại (A) hoàn thành học/báo cáo ngày hôm đó, chuỗi không bị đứt về 0 mà bảo lưu nguyên mốc `Chuỗi N` của ngày trước đó (`streakPreservedToday = true`), ngày hôm sau khi đủ 100% thành viên hoàn thành lại thì cộng tiếp `Chuỗi N + 1`.
- **AC-03 (UI giữ riêng tư):** `CommitmentGroupScreen` và `TodayPetCard` cho phép bấm **Báo bận hôm nay** (chọn lý do *Đi thi / Việc gia đình / Nghỉ ốm*), hiển thị trạng thái `Đang bảo lưu Chuỗi N` khi có thành viên bận, không lộ tên ai bận cho người khác.
