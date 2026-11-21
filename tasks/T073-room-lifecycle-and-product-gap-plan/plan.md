# Kế hoạch thực hiện

## Điểm bắt đầu

T068/T069 đã có capacity atomic, settings và polling. `StudyRoomMember` cascade theo `StudyRoom`; UI có lưới thành viên nhưng chưa có host moderation. Repo đang có WIP game/Firebase ngoài phạm vi, không stage.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo test backend + Flutter cho kick/delete/clear state | Test đỏ đúng thiếu contract | [x] |
| 2 | Thêm service/routes/repository/VM | Quyền A/B và cascade đúng | [x] |
| 3 | Thêm UI host với xác nhận, không giả media | 320dp/200% không vỡ; member không thấy quyền host | [x] |
| 4 | Ghi ma trận product đầy đủ và cập nhật API/realtime docs | “đã có” khớp bằng chứng | [x] |
| 5 | Chạy test PostgreSQL/Flutter/analyze/docs/task records, rà secret/diff | Không lỗi trong phạm vi | [x] |
| 6 | Commit/push riêng T073 và ghi SHA | Remote xác nhận | [x] |

## Chuỗi task product sau T073

1. T074: lịch hẹn học + todo server + local notification idempotent/quiet hours/Doze test.
2. T075: lời mời phòng TTL/QR/waitlist/duyệt và moderation rate-limit.
3. T076: signaling + media audio 1v1, mic/loa/audio route thật, hai máy.
4. T077: camera grid 2–4 người, reconnect/background/permission/low bandwidth.
5. T078: chat/ảnh hỏi AI/retention/delete và consent theo người nhận.
6. T079: group streak + pet ledger server, evolution/share card/provenance.
7. T080: đồng bộ timer/recap/EXP trong phòng nhóm, deep/interval và recovery.
8. T081: game G2 giao hữu 1v1 hai máy/event/FX/audio/reconnect/appeal.
9. T082: game G3 2v2; T083 ranked chỉ sau balance/content/rights gate.
10. T084: pilot Android thật, Firebase A/B, staging/monitoring/privacy/account deletion.

Mỗi task là một lát dọc riêng; không gọi product hoàn thành trước T084.

## Rủi ro và đường lui

Hard delete không giữ audit moderation; feature chưa có chat/report room nên chấp nhận ở v1 nội bộ. Nếu cần audit, dừng release và thêm tombstone/retention migration trước public room. Rollback API/UI vẫn giữ join/leave cũ; không đụng study timer.
