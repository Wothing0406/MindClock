# Avatar, khung hạng và bảng đấu trường

**Trạng thái:** roster/kit cũ đã hủy; chưa có nhân vật/asset được duyệt. Ba working names của chủ dự án là **Hà Nhân, Tuyệt Đỉnh, Hàn Bối Tháp**; vai trò thử nghiệm ở [22](22-nhan-vat-rpg.md). Không dùng likeness nhân vật phim hoặc coi đây là asset cuối. Luật RP ở [37](37-kinh-te-rank-va-nhan-vat-2d.md), bảng ở [21](21-dau-truong-xep-hang.md), backend ở [44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md). Không lấy ID nhân vật cũ từ lịch sử Git để lập trình.

**Màn chọn nhân vật, action tray và asset mới:** theo [docs/46 §§4–5](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md). Khung rank/bảng bên dưới vẫn áp dụng.

## Ô chọn nhân vật bản phác thảo

Ba ô cùng kích thước: `Hà Nhân · Bền bỉ`, `Tuyệt Đỉnh · Tích lực`, `Hàn Bối Tháp · Phòng thủ`. Mỗi ô dùng silhouette hình học trung tính, nhãn `Đang thiết kế`, một dòng vai trò và nút `Xem ý tưởng`; **không có Mua/Chọn để đấu thật** khi kit chưa chốt. Prototype có thể chọn ô để xem mô tả, phải ghi `Mô phỏng`. Không lấy ngoại hình/câu thoại/ảnh phim làm placeholder.

## Màn đấu trường giữ lại

1. **Sảnh:** `Giao hữu`, chọn môn/lớp/bộ nội dung; `Có hạng` khóa tới khi đạt cổng chất lượng. Có đường `Luyện môn này` nếu không ghép được.
2. **Phòng chờ/trận:** hai avatar trung tính, HP bằng số và thanh, vòng hiện tại; đề và vùng viết chiếm phần lớn. Chỉ hiện FX sau event server, không cho animation quyết định kết quả.
3. **Kết quả:** thắng/hòa/thua hoặc void; RP trước/sau nếu ranked hợp lệ, XP/coin riêng, `Xem cách giải`, `Báo chấm sai`.
4. **Bảng mùa:** lọc môn/lớp/bộ nội dung/mùa, top 20 và vị trí mình khi đã opt-in; biệt danh, RP, bậc, thời gian cập nhật; không hiện giờ dậy/ảnh bài/đời tư.

## Khung rank

Sáu tier `Đồng`, `Bạc`, `Vàng`, `Bạch Kim`, `Kim Cương`, `Tinh Anh`; mỗi tier có 5 bậc bằng nhãn chữ/số và vạch. Khung là cosmetic, không cộng sức mạnh. Thiết kế 6 nền vector, không làm 30 ảnh riêng; avatar không nhỏ hơn 40 dp, không dùng màu làm tín hiệu duy nhất. `unranked/placement` dùng viền thường và nhãn `Đang xếp hạng`. Khi chưa opt-in, không giả khung rank đang chạy. Lên bậc có chuyển động 300–500 ms có thể bỏ qua; Reduce Motion hiện tĩnh.

## Cổng thiết kế nhân vật sau này

Trước khi vẽ sprite/code catalog: chốt roster mới bằng quyết định của chủ dự án; kiểm tra tên/hình không sao chép IP; tạo master 3/4, silhouette, avatar 48 dp, bản tĩnh, bộ trạng thái, alt text, credit và giấy phép. Thử nhận diện với 5 người học ở 48 dp, cỡ chữ 200% và nền sáng/tối. Kỹ năng phải qua playtest cân bằng trước ranked. Prototype dùng avatar trung tính và ghi `Mô phỏng`.
