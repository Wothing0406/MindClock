# Avatar, khung hạng và bảng đấu trường

**Trạng thái:** roster/kit cũ đã hủy. Ba tướng v0.1 **Hà Nhân, Tuyệt Đỉnh, Hàn Bối Pháp** đã có sprite/web demo **nghiên cứu** theo [docs/49–51](49-sprite-ba-nhan-vat-va-web-demo.md), chưa duyệt quyền phát hành hoặc cân bằng. ID của tướng thứ ba giữ `han_boi_thap` tới khi chốt catalog. Không dùng likeness nhân vật phim hoặc coi asset này là cuối. Luật RP ở [37](37-kinh-te-rank-va-nhan-vat-2d.md), bảng ở [21](21-dau-truong-xep-hang.md), backend ở [44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md).

**Màn chọn nhân vật, action tray và asset mới:** theo [docs/46 §§4–5](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md). Khung rank/bảng bên dưới vẫn áp dụng.

## Ô chọn nhân vật bản phác thảo

Ba ô cùng kích thước: `Hà Nhân · Bền bỉ`, `Tuyệt Đỉnh · Sát thương`, `Hàn Bối Pháp · Phòng thủ`. Web prototype có thể chọn sprite nghiên cứu để xem mô tả và chiêu, phải ghi `Mô phỏng cục bộ`; **không có Mua/Chọn để đấu thật**. Bản public cần art được duyệt quyền. Không lấy ảnh/câu thoại phim làm placeholder.

## Màn đấu trường giữ lại

1. **Sảnh:** `Giao hữu`, chọn môn/lớp/bộ nội dung; `Có hạng` khóa tới khi đạt cổng chất lượng. Có đường `Luyện môn này` nếu không ghép được.
2. **Phòng chờ/trận:** hai avatar trung tính, HP bằng số và thanh, vòng hiện tại; đề và vùng viết chiếm phần lớn. Chỉ hiện FX sau event server, không cho animation quyết định kết quả.
3. **Kết quả:** thắng/hòa/thua hoặc void; RP trước/sau nếu ranked hợp lệ, XP/coin riêng, `Xem cách giải`, `Báo chấm sai`.
4. **Bảng mùa:** lọc môn/lớp/bộ nội dung/mùa, top 20 và vị trí mình khi đã opt-in; biệt danh, RP, bậc, thời gian cập nhật; không hiện giờ dậy/ảnh bài/đời tư.

## Khung rank

**Khung khác huy hiệu:** khung bao avatar là trang trí; [huy hiệu hạng riêng](52-ho-so-avatar-huy-hieu-va-lich-su.md) là biểu trưng server xác nhận theo môn/mùa, xuất ở kết quả ranked và hồ sơ công khai đã opt-in. Web demo có cả hai dạng asset để xem, không cấp hạng thật.

Sáu tier `Đồng`, `Bạc`, `Vàng`, `Bạch Kim`, `Kim Cương`, `Tinh Anh`; mỗi tier có 5 bậc bằng nhãn chữ/số và vạch. Khung là cosmetic, không cộng sức mạnh. Thiết kế 6 nền vector, không làm 30 ảnh riêng; avatar không nhỏ hơn 40 dp, không dùng màu làm tín hiệu duy nhất. `unranked/placement` dùng viền thường và nhãn `Đang xếp hạng`. Khi chưa opt-in, không giả khung rank đang chạy. Lên bậc có chuyển động 300–500 ms có thể bỏ qua; Reduce Motion hiện tĩnh.

## Cổng thiết kế nhân vật sau này

Trước khi vẽ sprite/code catalog: chốt roster mới bằng quyết định của chủ dự án; kiểm tra tên/hình không sao chép IP; tạo master 3/4, silhouette, avatar 48 dp, bản tĩnh, bộ trạng thái, alt text, credit và giấy phép. Thử nhận diện với 5 người học ở 48 dp, cỡ chữ 200% và nền sáng/tối. Kỹ năng phải qua playtest cân bằng trước ranked. Prototype dùng avatar trung tính và ghi `Mô phỏng`.
