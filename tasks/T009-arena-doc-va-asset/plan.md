# Kế hoạch T009

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Asset contract và test trước: logical viewport, actor roots/anchors, effect event timeline, manifest | AC liên kết TC; script kiểm hình học | [x] |
| 2 | Sắp xếp mỗi nhân vật một folder; chuẩn hóa tất cả frame/clip/master, cập nhật exporter/runtime | không còn đường dẫn cũ, không cắt chân | [x] |
| 3 | Tạo map, rank/khung avatar/avatar mặc định, VFX riêng và thắng trận; âm thanh | asset thật, manifest/nguồn/quyền | [x] |
| 4 | Sửa web portrait, projectile/target FX, thẻ nhân vật/đề/nút/mute | thao tác mobile đọc rõ; logic số không sai | [x] (tĩnh/logic, chờ máy thật) |
| 5 | README, docs cấu trúc/asset/runtime và docs nguồn chuẩn | không mô tả mock là đã chạy thật | [x] |
| 6 | QA: logic, media, orientation/size, audio, responsive, diff, push | kết quả thực và remote commit xác minh | [ ] (chờ push, kiểm trình duyệt thật) |
| 7 | Sửa riêng facing Hàn Bối Pháp theo phản hồi 13/11; đồng bộ renderer/manifest/builder/preview/docs và push | AC-09/TC-09 đạt | [x] (tĩnh/logic; chờ Android thật) |

## Rủi ro

Nhiều asset có thể làm repo lớn, tải chậm trên điện thoại; phải nén và đo. Chủ dự án đã xác nhận quyền đăng GitHub; quyền thương mại vẫn cần rà khi phát hành app. CUA browser local từng bị chặn, dùng kiểm tra cục bộ không phụ thuộc UI và ghi rõ nếu còn thiếu visual QA.
