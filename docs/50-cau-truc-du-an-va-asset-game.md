# Cấu trúc repo và pipeline tài sản game

**Trạng thái:** chuẩn tổ chức cho prototype sân luyện ngày 12/11/2026. [Luật PvP thử nghiệm](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) có thẩm quyền về HP/giáp/khí. [Sân dọc](51-san-dau-doc-mobile-va-hieu-ung.md) có thẩm quyền về tọa độ và FX. Chưa có app Android/iOS hoặc backend.

## 1. Cây thư mục hiện tại

```text
MindClock/
├─ AGENTS.md                 quy tắc làm việc của agent
├─ README.md                 giới thiệu, tình trạng thật, cách xem demo
├─ docs/                     PRD, UX, API, SQL, game, kiểm thử và runbook
├─ tasks/                    mỗi thay đổi code/UI có spec, plan, tests, worklog, handoff
├─ data/sources/             metadata nguồn đề; không chứa corpus đã tích hợp
├─ demo/
│  ├─ index.html             bản xem trước sản phẩm
│  ├─ arena.html             sân luyện web dọc, offline
│  ├─ arena.css / arena.js   giao diện và luật mô phỏng cục bộ
│  ├─ arena-renderer.js      canvas, sprite, FX, âm thanh
│  └─ assets/game/
│     ├─ manifest.json       kích thước sân/anchor/cấu trúc asset
│     ├─ maps/               battle plate; không có collision
│     ├─ ui/avatars/         sáu avatar mặc định
│     ├─ ui/rank/            khung thường + sáu khung hạng mỹ thuật
│     │  └─ badges/          sáu huy hiệu hạng độc lập với khung
│     ├─ effects/            FX trạng thái chung
│     ├─ audio/              impact/heal chung và manifest âm thanh
│     └─ characters/{ha-nhan,han-boi-phap,tuyet-dinh}/
│        ├─ source/          master, sheet pose/action/state/victory để dựng lại
│        ├─ runtime/         idle, clip WebP và frames/{action}/fNN.webp
│        ├─ poses/           ảnh tĩnh để rà từng tư thế
│        ├─ fx/              basic, skill1, skill2, passive riêng
│        └─ audio/           basic, skill1, skill2, stun, victory riêng
└─ scripts/                  dựng/check asset, chưa phải build app
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

Môi trường tác giả: Python 3, Pillow, NumPy, OpenCV cho pipeline ảnh; Node.js chỉ để kiểm logic JS. Demo web không cần npm, tài khoản hay dịch vụ trả tiền.

```powershell
python scripts/build_game_assets.py
python scripts/build_game_projectiles.py
python scripts/build_rank_frames.py
python scripts/build_rank_badges.py
python scripts/build_game_audio.py
python scripts/check_game_assets.py
python scripts/render_stage_previews.py
node tasks/T009-arena-doc-va-asset/test_arena_rules.js
python -m http.server 8000
```

`build_game_assets.py` lấy sheet trong từng `source/`, tách nền, chuẩn hóa anchor và xuất WebP. `build_game_projectiles.py` xuất 9 SVG nền trong; `build_rank_frames.py` xuất khung SVG và passive riêng; `build_rank_badges.py` xuất sáu huy hiệu hạng; `build_game_audio.py` tạo âm thanh tổng hợp nguyên bản. Script check kiểm cấu trúc, số frame, bbox/foot, alpha, tên FX/âm, đỉnh âm và manifest. `render_stage_previews.py` xuất ba ảnh ghép để nhìn tỉ lệ/hướng. Kết quả ảnh không thay cho mắt người: đội cần xem chuyển động, hướng nhìn và chạm đòn trên Chrome Android thật ở 320/360/390 dp trước demo.

## 4. Quy tắc đặt tên và phiên bản

`character_id` nghiệp vụ: `ha_nhan`, `han_boi_thap`, `tuyet_dinh`; slug thư mục: `ha-nhan`, `han-boi-phap`, `tuyet-dinh`. Tên hiển thị thứ hai hiện là **Hàn Bối Pháp**, còn `han_boi_thap` chỉ là ID kế thừa của đặc tả v0.1; chốt catalog trước backend. Action cố định `idle/basic/skill1/skill2/hurt/stun/heal/victory`. Khung hạng là mỹ thuật mẫu, **không mở ranked**. Khi sửa số/kit, tăng `combat_rule_version`, đồng bộ docs/46, backend contract và test; asset đổi riêng qua `asset_version`.

## 5. Quy trình đội và nguồn quyền

Mỗi lần code: mở [docs/README](README.md) và [tasks/README](../tasks/README.md), tạo task từ template, viết AC ↔ test, rồi sửa theo lát cắt. Trước khi merge/push, rà `git diff`, link docs, test asset, test luật và xem trên thiết bị thật. Ghi kết quả thực vào `tests.md`, `worklog.md`, `handoff.md`. Không gọi một storyboard hay clip frame sequence là app đã chạy. Quyền đăng repo đã được chủ dự án xác nhận; khi phát hành app phải duyệt quyền thương mại và provenance từng file.
