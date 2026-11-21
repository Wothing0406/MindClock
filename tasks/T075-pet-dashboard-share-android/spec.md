# Đặc tả T075

## Phạm vi

- Một membership được chọn `primary` cho mỗi user; khi chưa chọn, group active cũ nhất là fallback.
- Màn Hôm nay tải group server, hiển thị pet chính, chuỗi, EXP, đóng góp hôm nay và mở hub nhóm.
- User đổi pet chính trong hub; server là nguồn thẩm quyền và đồng bộ thiết bị.
- Nút chia sẻ dựng PNG từ snapshot server đã tải, preview rõ nội dung, Android share sheet chỉ mở sau thao tác user. Không tự đăng.
- Ảnh share không chứa email, group code, lịch, giờ dậy, danh sách thành viên hoặc tên nhóm nếu user không bật.
- T074 đã ghi +20 EXP cho thử thách sáng đúng và +10 EXP cho phiên học ≥300 giây vào tối đa 3 group; T075 chỉ hiển thị/recap, không cộng lại.

## Yêu cầu kiểm chứng

| ID | Điều kiện | Hành vi | Test |
| --- | --- | --- | --- |
| AC-01 | User chọn một group active | backend bỏ primary cũ và đặt primary mới trong transaction; cross-user bị từ chối | TC-01, TC-08 |
| AC-02 | Mở Hôm nay khi có group | hiển thị pet chính bằng dữ liệu server; loading/error/empty không dựng số giả | TC-02–TC-04 |
| AC-03 | Có 2–3 group | hub đổi pet chính và dashboard phản ánh sau refresh | TC-03 |
| AC-04 | Chạm chia sẻ | render PNG 1080×1080, preview rồi gọi bridge Android với URI tạm TTL | TC-05–TC-07 |
| AC-05 | Reduce Motion/chữ lớn/320dp | không overflow, không animation bắt buộc | TC-04 |
| AC-06 | Bằng chứng trình bày | ảnh/video emulator dùng font Android thật, không dùng golden Ahem | TC-09 |

## Ngoài phạm vi

Chat/ảnh/`@MindClock`, mic/camera, QR/phòng chờ, lịch hẹn, PvP. Tất cả là task riêng; không thêm package share bên thứ ba nếu bridge hẹp đủ dùng.
