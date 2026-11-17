# Nhân vật, sprite, hiệu ứng, avatar và khung

**Trạng thái:** [`assets/game/`](../../assets/game) chứa art nghiên cứu từ prototype, **chưa** là asset Flutter được duyệt phát hành; không có arena Flutter/PvP live. Nhân vật phải là bản gốc, không sao chép tạo hình phim/diễn viên/biểu tượng nhận diện. Chủ dự án từng xác nhận quyền đăng repo ảnh phái sinh; **quyền thương mại/nhận diện/âm thanh vẫn phải rà riêng**.

## 1. Cây asset và manifest

```text
assets/game/
├─ manifest.json                  stage/anchor/facing/action/frame/version
├─ characters/<slug>/
│  ├─ source/                     master + sheet pose/action/state/victory
│  ├─ runtime/                    idle/clip WebP + frames/<action>/fNN.webp
│  ├─ poses/                      ảnh tĩnh QA
│  ├─ fx/                         basic/skill1/skill2/passive riêng tướng
│  └─ audio/                      basic/skill1/skill2/stun/victory riêng tướng
├─ effects/runtime/              impact/healing/stun chung
├─ maps/                         sân dọc và source
├─ ui/avatars/                   avatar mặc định + source
├─ ui/rank/                      khung mỹ thuật và badges/ riêng
└─ audio/                        impact/heal chung
```

Canvas sprite 512×512 RGBA, anchor chân `(256,478)`, logical stage 360×380, actor root trái `(92,350)`/phải `(268,350)`, vẽ 240×240; không crop/scale mỗi frame khác nhau. Native facing Hà Nhân/Hàn Bối Pháp nhìn phải, Tuyệt Đỉnh nhìn trái; renderer lật **chỉ nhân vật** theo slot, không lật chữ/HP/map/FX. Kiểm tướng nhìn vào nhau, chân cùng baseline, không cắt ở màn 320/360/390dp. Manifest là nguồn thông số asset, không là combat authority.

## 2. VFX, audio và motion

Mỗi tướng có vệt đòn riêng; projectile bay từ attacker tới defender, impact trên người nhận, healing/ward/passive trên chủ. Choáng quanh người bị choáng; thắng chỉ sau result server. UI giảm chuyển động có ảnh/chữ thay thế và `Bỏ qua` không đổi HP. Âm game tắt mặc định cho tới thao tác người dùng; âm chuông là tài nguyên Android riêng, không lấy từ `assets/game/audio`. Tránh tia chung lặp cho mọi tướng, flash mạnh, particle dày trên máy yếu.

Frame hiện có là sequence/sheet nghiên cứu, chưa chứng minh animation mượt; cần artist duyệt mặt/tay/trang phục/đạo cụ xuyên frame, test fps/memory/âm trên máy mục tiêu. Khi mở game Flutter, task nhập/copy asset đã duyệt vào `app/assets/game/`, khai báo `pubspec.yaml`, ghi `asset_version`/hash, lazy load và fallback tĩnh; **không đọc path repo** ở runtime. Không tạo 3D cho P0/PvP đầu.

## 3. Hồ sơ/khung/rank phân biệt

Avatar profile là ảnh người dùng chọn (6 mặc định hoặc upload sau consent/duyệt), khác **nhân vật chiến đấu**. Khung chỉ trang trí quanh avatar; badge rank là ảnh riêng theo tier/bậc do server cấp. Hồ sơ của chủ có avatar/alias/môn/tiến độ/lịch sử đấu và lịch sử báo thức riêng; người khác chỉ xem projection opt-in, **không** giờ dậy, TKB, bài/ảnh, email hoặc uy tín nội bộ. Ảnh upload mục tiêu JPEG/PNG/WebP ≤2 MB, crop 1:1, backend kiểm magic bytes/decode/EXIF, tạo bản 256×256; pending không công khai, có reject/appeal/delete. Đây là **đặc tả tương lai**, chưa có API/asset storage production.

## 4. Prompt/brief tạo asset mới

Mỗi tướng cần một brief riêng có: silhouette/tuổi biểu kiến trung tính, bảng màu 3–4 màu, trang phục/đạo cụ gốc, native facing, 8 hành động `idle/basic/skill1/skill2/hurt/stun/heal/victory`, kích thước/anchor, FX projectile/self/impact, SFX cue, reduced-motion still, export PNG/WebP/SVG, license/provenance. Mô tả humor bằng chi tiết nhỏ sau trận (giấy bay lệch, tóc rối, tháp giấy nghiêng), không khiến tướng thành trò nhạo người học. Không dùng prompt “giống nhân vật/phim X”; reviewer chọn một master still rồi giữ nhất quán giữa mọi frame. Mỗi skill phải có hit origin/target rõ, không dính hiệu ứng của tướng khác.

## 5. Pipeline và cổng

Các script `scripts/build_game_assets.py`, `build_game_projectiles.py`, `build_rank_frames.py`, `build_rank_badges.py`, `build_game_audio.py`, `check_game_assets.py`, `render_stage_previews.py` dùng `assets/game/`. QA tự động kiểm số file/alpha/anchor/facing/audio/manifest; QA mắt kiểm motion/FX/hit/đọc chữ; QA sản phẩm kiểm quyền và hiệu năng Flutter. Asset pass script **không** đồng nghĩa đủ quyền phát hành hoặc animation đã chuẩn. [GDD](01-pvp-gdd.md), [quality](../03-quality/01-ke-hoach-kiem-thu.md).

Inventory theo mode và asset còn thiếu cho UI luyện đơn/1v1/2v2 nằm ở [bảng asset gap](04-che-do-don-doi-va-asset-gap.md#6-asset-đang-có-và-khoảng-thiếu). Không tạo thêm tướng trước khi layout bốn actor và FX đúng target đạt trên Android.
