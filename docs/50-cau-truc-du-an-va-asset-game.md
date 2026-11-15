# Cấu trúc repo và pipeline tài sản game

**Trạng thái:** hợp đồng art/sprite nghiên cứu, di chuyển sang `assets/game/` ngày 15/11/2026. Cây repo và hướng production ở [57](57-cau-truc-repo-production.md). [Luật PvP thử nghiệm](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) có thẩm quyền về HP/giáp/khí; [sân dọc](51-san-dau-doc-mobile-va-hieu-ung.md) về tọa độ và FX. Flutter/API đã có mã nhưng PvP chưa được triển khai.

## 1. Cây tài sản game hiện tại

```text
assets/game/
├─ manifest.json             kích thước sân/anchor/cấu trúc asset
├─ maps/                     battle plate; không có collision
├─ ui/avatars/               sáu avatar mặc định
├─ ui/rank/                  khung thường, sáu khung hạng mỹ thuật và badges/
├─ effects/                  FX trạng thái chung
├─ audio/                    impact/heal chung và manifest âm thanh
└─ characters/{ha-nhan,han-boi-phap,tuyet-dinh}/
   ├─ source/                master, sheet pose/action/state/victory để dựng lại
   ├─ runtime/               idle, clip WebP và frames/{action}/fNN.webp
   ├─ poses/                 ảnh tĩnh để rà từng tư thế
   ├─ fx/                    basic, skill1, skill2, passive riêng
   └─ audio/                 basic, skill1, skill2, stun, victory riêng
```

Không đưa file ảnh tham chiếu gốc của người dùng vào repo. `source/` là art phái sinh phục vụ nghiên cứu. Chủ dự án đã xác nhận quyền đăng công khai sprite trong repo ngày 12/11/2026; quyền thương mại/nhận diện cần rà trước phát hành ứng dụng. Bộ câu hỏi ngoài chỉ được ghi metadata nguồn theo [docs/38](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md).

## 2. Hợp đồng sprite và VFX

- Canvas sprite **512 × 512 RGBA**, anchor chân `(256,478)`, không crop/fit mỗi frame theo bbox. Frame đầu của từng action quyết định một phép scale/translate cho toàn bộ action; frame sau giữ transform đó.
- Logical stage **360 × 380**. Root trái `(92,350)`, phải `(268,350)`. Vẽ mỗi canvas sprite ở **240 × 240**: `x=rootX−120`, `y=rootY−478/512×240`; vùng alpha nhân vật hiển thị xấp xỉ 189 px cao. Gốc **Hà Nhân và Hàn Bối Pháp nhìn phải**, Tuyệt Đỉnh nhìn trái. Chỉ lật sprite theo slot để hai bên nhìn nhau; Hàn Bối Pháp ở trái giữ ảnh gốc, ở phải mới lật. Lật quanh canvas/anchor, không lật map, chữ, HP hoặc số sát thương.
- Map portrait được crop bằng **cover**, không kéo méo. Nền tĩnh, không có va chạm/chuyển màn. Chân nhân vật nằm trên nền đất; FX không được chôn vào ảnh nhân vật.
- Projectile có `attacker_side`, điểm đầu `(attackerX ± 28,251)`, điểm cuối `(targetX ∓ 28,251)`, bay từ 120 đến 515 ms theo cung cao 22 px. `impact` chỉ ở mục tiêu lúc 515–815 ms. `selfEffect` chỉ ở người dùng chiêu. Đòn phản công đảo hướng. Chín SVG projectile trong từng folder nhân vật có hình học/màu khác nhau; không dùng chung một splash cho mọi chiêu.
- `passive.svg` chỉ vẽ trên người sở hữu; `stun` quanh đầu, `healing` trên người được hồi, `victory` theo sprite/âm thanh của tướng. FX không thay số HP/giáp; kết quả thật phải từ event server. Giảm chuyển động dùng ảnh tĩnh/chữ và có `Bỏ qua`.
- Audio WAV mono 22,05 kHz, đỉnh mục tiêu ≤ −12 dBFS, tắt mặc định và chỉ bật sau click. Không dùng bộ âm này cho báo thức. Máy yếu có thể bỏ FX và âm mà số vẫn đúng.

## 3. Dựng lại và kiểm tra

Môi trường tác giả: Python 3, Pillow, NumPy, OpenCV cho pipeline ảnh. Asset hiện chỉ là nguồn nghiên cứu; lệnh dưới đây không build APK.

```powershell
python scripts/build_game_assets.py
python scripts/build_game_projectiles.py
python scripts/build_rank_frames.py
python scripts/build_rank_badges.py
python scripts/build_game_audio.py
python scripts/check_game_assets.py
python scripts/render_stage_previews.py
```

`build_game_assets.py` lấy sheet trong từng `source/`, tách nền, chuẩn hóa anchor và xuất WebP. `build_game_projectiles.py` xuất 9 SVG nền trong; `build_rank_frames.py` xuất khung SVG và passive riêng; `build_rank_badges.py` xuất sáu huy hiệu hạng; `build_game_audio.py` tạo âm thanh tổng hợp nguyên bản. Script check kiểm cấu trúc, số frame, bbox/foot, alpha, tên FX/âm, đỉnh âm và manifest. `render_stage_previews.py` xuất ba ảnh ghép lịch sử để nhìn tỉ lệ/hướng. Khi đưa vào Flutter phải làm renderer và kiểm trên Android thật bằng task riêng.

## 4. Quy tắc đặt tên và phiên bản

`character_id` nghiệp vụ: `ha_nhan`, `han_boi_thap`, `tuyet_dinh`; slug thư mục: `ha-nhan`, `han-boi-phap`, `tuyet-dinh`. Tên hiển thị thứ hai hiện là **Hàn Bối Pháp**, còn `han_boi_thap` chỉ là ID kế thừa của đặc tả v0.1; chốt catalog trước backend. Action cố định `idle/basic/skill1/skill2/hurt/stun/heal/victory`. Khung hạng là mỹ thuật mẫu, **không mở ranked**. Khi sửa số/kit, tăng `combat_rule_version`, đồng bộ docs/46, backend contract và test; asset đổi riêng qua `asset_version`.

## 5. Quy trình đội và nguồn quyền

Mỗi lần code: mở [docs/README](README.md) và [tasks/README](../tasks/README.md), tạo task từ template, viết AC ↔ test, rồi sửa theo lát cắt. Trước khi merge/push, rà `git diff`, link docs, test asset, test luật và xem trên thiết bị thật. Ghi kết quả thực vào `tests.md`, `worklog.md`, `handoff.md`. Không gọi một storyboard hay clip frame sequence là app đã chạy. Quyền đăng repo đã được chủ dự án xác nhận; khi phát hành app phải duyệt quyền thương mại và provenance từng file.
