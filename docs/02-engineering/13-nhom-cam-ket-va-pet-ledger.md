# Nhóm cam kết và pet ledger

## Phạm vi hiện hành

T074 xây nền nhóm kín và pet có dữ liệu server; T075 thêm pet chính đồng bộ đa thiết bị, card Hôm nay và Android share sheet. Một user có tối đa 3 membership `active`; một nhóm tối đa 4 người. Nhóm không xuất hiện trong tìm kiếm công khai. Owner mời bạn đã kết bạn, duyệt yêu cầu theo mã, mời ra hoặc xóa nhóm. Member có thể rời. Chuyển quyền trưởng nhóm, QR, chat/media và PvP chưa thuộc phạm vi hiện hành.

## Nguồn care và EXP nhóm

| Nguồn server đã xác nhận | Điều kiện | Care kind | EXP nhóm |
| --- | --- | --- | ---: |
| `study_session` | `completed|finished`, timing hợp lệ, focus ≥ 300 giây | `study_care` | 10 |
| `alarm_session` | backend chốt câu cá nhân hóa `correct` | `morning_challenge` | 20 |

Một sự kiện hợp lệ được chiếu vào tất cả nhóm active của user tại thời điểm ghi. Constraint `(group_id, source_type, source_id)` chống retry cộng trùng. Constraint `(group_id, user_id, local_date, care_kind)` giới hạn một care cùng loại/ngày trong mỗi nhóm. Ngày được tính theo timezone cố định của nhóm lúc tạo.

Pet `mam` dùng `pet-progression-v0.1`: stage 1/2/3/4 tại 0/60/160/320 EXP. Stage không giảm khi đứt streak. `currentStreakDays` lấy từ tập ngày có care của cả nhóm; nếu hôm nay chưa có care thì cho phép chuỗi kết thúc ở hôm qua. Client chỉ render `totalXp`, `currentStreakDays`, `todayCareCount`, `stage`; không tự cộng.

## Bảng dữ liệu

- `commitment_groups`: owner, mã nhóm, timezone, pet, progression version, capacity và status.
- `commitment_group_members`: role `owner|member`, status `active|left|removed`, thời điểm tham gia/rời và `is_primary`; partial unique index chỉ cho một membership active primary/user trên PostgreSQL.
- `commitment_group_invites`: người mời/người nhận, trạng thái, TTL 72 giờ.
- `commitment_group_join_requests`: yêu cầu theo mã, owner accept/reject.
- `commitment_pet_care`: ledger append-only theo group/user/ngày/source, `xp_delta` do server quyết định.

Xóa account owner xóa group cascade. Xóa member/account dọn membership, invite, request và care theo FK/transaction. Không lưu email, thời khóa biểu, giờ dậy, bài làm hoặc lý do vắng trong payload nhóm.

## API T074

| Method | Path | Quyền/kết quả |
| --- | --- | --- |
| `GET` | `/v1/commitment-groups/me` | Các group của user, invite đến, giới hạn membership |
| `POST` | `/v1/commitment-groups` | Tạo group + owner membership trong transaction |
| `POST` | `/v1/commitment-groups/{id}/invites` | Owner mời một friendship, TTL 72 giờ |
| `POST` | `/v1/commitment-group-invites/{id}/respond` | Recipient accept/decline |
| `POST` | `/v1/commitment-group-join-requests` | Gửi request bằng mã nhóm |
| `POST` | `/v1/commitment-groups/{id}/join-requests/{requestId}/respond` | Owner accept/reject |
| `DELETE` | `/v1/commitment-groups/{id}/members/{userId}` | Owner mời member ra, không xóa owner |
| `POST` | `/v1/commitment-groups/{id}/leave` | Member rời; owner phải xóa group |
| `DELETE` | `/v1/commitment-groups/{id}` | Owner xóa group và dữ liệu con |
| `POST` | `/v1/commitment-groups/{id}/primary` | Member chọn pet group này làm pet chính; server hạ primary cũ rồi nâng primary mới trong cùng transaction |

Accept/approve khóa row user và group trên PostgreSQL trước khi kiểm giới hạn. Các response nhóm chỉ trả alias/avatar/role và số tổng hợp. Không trả danh sách người chưa chăm.

## Cổng kiểm chứng

- SQLite API: quyền owner/member, invite/request state, kick/leave/delete, study/morning care và retry.
- PostgreSQL disposable DB: migration `0005/0006`, hai approval không vượt 3 nhóm và hai lần chọn primary cạnh tranh vẫn còn đúng một primary.
- Flutter: parse contract đa nhóm, tạo/render pet, 320dp + text 200% + Reduce Motion.
- T075 đã đưa pet ra dashboard và share sheet; ảnh/video emulator nằm tại `docs/03-quality/evidence/T075/`. T077 mới thêm chat `@MindClock`.
