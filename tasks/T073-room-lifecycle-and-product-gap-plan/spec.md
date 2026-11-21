# Đặc tả nhiệm vụ

## Vấn đề và kết quả mong muốn

Phòng hiện có tạo/join/leave/settings và polling REST, nhưng chủ phòng chưa kick thành viên hoặc xóa phòng. Mic/camera mới là cờ hiển thị, không truyền media. Sau task, vòng đời phòng REST có quyền rõ và UI không giữ room state đã bị xóa/kick; tài liệu không gọi phần còn thiếu là đã hoàn thành.

## Phạm vi

- **Trong phạm vi:** host kick thành viên; host xóa phòng và cascade member rows; member bị kick/room bị xóa nhận 404/403 và client clear room state; hộp xác nhận UI; cập nhật ma trận product gap.
- **Ngoài phạm vi:** WebRTC/LiveKit, chat/ảnh/QR token/waitlist, lịch hẹn, pet ledger, notification theo lịch, PvP/ranked.
- **Dữ liệu/role/quyền:** Firebase principal hiện hành; chỉ owner được kick/delete; không kick host; user A/B test; xóa room phải xóa member rows bằng FK cascade.
- **Tài liệu chuẩn:** `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/09-phong-hoc-realtime.md`, `docs/02-engineering/12-lich-chung-va-ghep-phong.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Host kick member đang active | member bị đánh dấu rời, mic/cam false; response phòng không còn member | TC-01, TC-05 |
| AC-02 | Member/non-host kick hoặc kick host/self | từ chối 403/409, dữ liệu không đổi | TC-02 |
| AC-03 | Host xóa phòng | row `study_rooms` và `study_room_members` bị xóa trong transaction; room biến mất khỏi list/get | TC-03, TC-06 |
| AC-04 | Non-host xóa phòng | từ chối 403, phòng còn nguyên | TC-04 |
| AC-05 | UI host quản trị | có menu kick và nút xóa với xác nhận; thành công clear/update state; lỗi giữ state để retry | TC-07–TC-09 |
| AC-06 | Kết thúc task | ma trận trạng thái phân biệt runtime thật, metadata/mock và chưa test | TC-10 |

## Hợp đồng và trường hợp biên

- `DELETE /v1/study-rooms/{room_id}/members/{user_id}` trả room detail sau kick.
- `DELETE /v1/study-rooms/{room_id}` trả `204`; nếu room tồn tại phải kiểm owner. Room đã không còn trả 404, client coi là state đã hết.
- Không xóa/tắt study timer local khi room bị xóa hoặc user bị kick.
- Không tuyên bố mic/cam/loa hoạt động cho tới khi có media engine và test hai máy.

## Quyết định/mâu thuẫn

Xóa phòng là hard delete vì hiện chưa có chat/audit/recording và người dùng yêu cầu xóa ID/cache rõ. Khi mở moderation/audit phải thêm retention/tombstone trong migration riêng; không âm thầm đổi ở task này.
