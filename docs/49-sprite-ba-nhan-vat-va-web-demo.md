# Sprite ba nhân vật và sân luyện web

**Trạng thái:** art và UX prototype ngày 12/11/2026. [Mở demo](../demo/arena.html). Không có PvP online, chấm trình bày, điểm rank hay báo thức thật. Luật thử nghiệm ở [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md); tọa độ và motion ở [docs/51](51-san-dau-doc-mobile-va-hieu-ung.md); cấu trúc file ở [docs/50](50-cau-truc-du-an-va-asset-game.md).

## Tham chiếu và quyền

Người dùng gửi ba ảnh: ảnh 1 Hà Nhân (mặt trắng, nón rơm, áo lam); ảnh 2 Hàn Bối Pháp (tóc xám, áo tối); ảnh 3 Tuyệt Đỉnh (tóc trắng, áo đỏ). Ảnh gốc không được chép vào repo. **Chủ dự án xác nhận ngày 12/11/2026 có quyền đăng công khai ảnh tham chiếu và sprite phát sinh lên GitHub.** Bộ art vẫn là nghiên cứu; quyền dùng thương mại/nhận diện phim và giấy phép đầu ra cần rà riêng trước phát hành ứng dụng. `han_boi_thap` là ID kit cũ, tên hiển thị hiện là Hàn Bối Pháp; chốt catalog trước backend.

## Bộ file và cách dựng

Mỗi tướng có folder riêng trong [`demo/assets/game/characters`](../demo/assets/game/characters): `source/` chứa master và sheet; `runtime/` chứa idle, 7 action WebP và frame riêng; `poses/` chứa 6 ảnh kiểm tư thế; `fx/` có 3 projectile SVG + passive SVG riêng; `audio/` có 5 âm riêng. Map, avatar mặc định, khung rank và FX chung nằm dưới [`demo/assets/game`](../demo/assets/game). [Manifest](../demo/assets/game/manifest.json) giữ anchor, facing, logical stage và thời lượng frame.

Ảnh 3×2 tạo bằng mô hình ảnh theo từng nhân vật và tách nền/đăng ký vào canvas 512×512. **Không có image-to-video route** ở môi trường này: Animated WebP là chuỗi 6 frame được ghép, trạng thái 2 tư thế lặp thành 4 frame; còn sai khác mặt/tay/đạo cụ và cần họa sĩ duyệt trước sản phẩm thật. Riêng thắng có 6 frame; Hà Nhân chuyển động tay/mặt khá nhẹ nên runtime thêm một nhịp nhấc nhỏ. Đừng gọi đây là animation hoàn thiện hay video sinh tự động.

Chạy pipeline và QA theo [docs/50 §3](50-cau-truc-du-an-va-asset-game.md). Trên web, chọn tướng → trả lời câu mẫu → viết một bước làm → chọn đòn; câu mẫu chỉ chấm đáp án cố định, **không chấm nội dung cách làm**. Nút trạng thái xem riêng hurt/stun/heal/victory. FX dựa vào tọa độ người đánh và mục tiêu, không dính cố định vào ảnh tướng; âm tắt mặc định.

## Tiêu chí duyệt art trước khi đưa vào app

- Trùng bộ mặt, trang phục, màu và đạo cụ giữa mọi frame; không có phụ kiện xuất hiện mất tích vô cớ.
- Anchor chân `(256,478)` và bbox 512² không bị cắt; nhìn phải/trái đúng theo slot; outline rõ ở 240 px, bản 48 px có fallback/avatar riêng.
- Mỗi chiêu có silhouette/vệt riêng, điểm chạm trúng đối thủ, buff ở người sở hữu; không lóe, không phủ đề.
- Artist duyệt từng frame khi lặp nhiều lần; so trên Android thật, giảm chuyển động và tắt âm.
- Ghi provenance từng nguồn/ảnh và xác minh quyền trước khi công khai/tái sử dụng thương mại.

Phần kiểm thử thực tế và giới hạn còn lại nằm tại [task T009](../tasks/T009-arena-doc-va-asset/tests.md). Chỉ gọi sân này là bản xem thử, không suy diễn rằng giao hữu/ranked đã hoạt động.
