# Đặc tả nhiệm vụ

## Phạm vi và quyết định MVP

Trong T074, mỗi người tham gia tối đa **3 nhóm cam kết active**, mỗi nhóm tối đa 4 người, kín và không tìm công khai. Một hoạt động đủ điều kiện phát care/EXP cho từng pet của các nhóm active, nhưng mỗi nguồn chỉ ghi một lần trong từng nhóm. Mời chỉ gửi tới bạn bè hai chiều. Người biết mã nhóm có thể gửi yêu cầu; trưởng nhóm duyệt/từ chối. Dashboard/share card là T075; QR TTL/phòng chờ là T076, không giả là đã có.

Care `study_care` +10 EXP chỉ sinh khi backend xác nhận phiên `completed|finished`, timing hợp lệ và có ít nhất 300 giây focus. Care `morning_challenge` +20 EXP sinh khi backend chốt câu báo thức đúng; retry/cùng source/ngày/nhóm không nhân care. Không lấy nút bấm client làm bằng chứng. Mốc stage thử nghiệm version `pet-progression-v0.1`: stage 1/2/3/4 tại 0/60/160/320 EXP nhóm; không mất stage khi đứt streak.

## Yêu cầu EARS

| ID | Yêu cầu kiểm chứng | Bằng chứng |
| --- | --- | --- |
| AC-01 | Khi user còn dưới giới hạn 3 nhóm tạo tên hợp lệ, hệ thống tạo group kín, owner membership và pet `mam` trong một transaction. | TC-01, TC-10 |
| AC-02 | Khi owner mời một friendship hợp lệ, hệ thống tạo invite pending hết hạn sau 72 giờ; recipient accept/decline, accept khóa capacity và giới hạn 3 nhóm active. | TC-02, TC-10 |
| AC-03 | Khi user gửi join request bằng mã nhóm, owner thấy request và approve/reject; non-owner không duyệt được. | TC-03 |
| AC-04 | Khi owner kick member, hệ thống kết thúc membership; khi member rời, group còn nguyên; owner chỉ xóa group hoặc chuyển quyền ở task sau. | TC-04 |
| AC-05 | Khi phiên học hoặc thử thách sáng đủ điều kiện, hệ thống ghi tối đa một care/source/group và phát cho tối đa 3 nhóm active; retry không nhân bản. | TC-05, TC-10 |
| AC-06 | Khi đọc group detail, hệ thống trả count hôm nay, total care days, current streak, EXP và stage từ ledger server, không từ client. | TC-06 |
| AC-07 | Khi mở giao diện nhóm, user chuyển giữa tối đa 3 pet, tạo nhóm, xem pet/streak/EXP/member/invite/request và owner mời/duyệt/kick/delete; UI không dùng emoji hay số mẫu. | TC-07–TC-09 |

## Quyền, lỗi và riêng tư

- Owner từ token; không nhận owner/user tùy ý ngoài recipient/member target đã kiểm quyền.
- Không trả email, TKB, giờ dậy, bài làm, EXP cá nhân. Group member thấy alias/avatar/role và tổng care hôm nay, không thấy ai vắng hoặc lý do.
- Invite/request hết hạn/duplicate/full/cross-owner trả 403/404/409 rõ; create/respond dùng transaction và idempotency nơi cần.
- Xóa account phải xóa invite/request/care/membership; nếu là owner thì xóa group cascade.
