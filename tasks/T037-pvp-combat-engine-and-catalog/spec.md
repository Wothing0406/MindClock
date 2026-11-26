# Đặc tả T037: Combat Engine thuần & Chốt Catalog Tướng PvP 1v1

## 1. Mục tiêu
Chốt danh mục nhân vật chuẩn hóa, giải quyết dứt điểm sự sai lệch định danh `han_boi_phap` và `han_boi_thap`, và hiện thực hóa Combat Engine thuần túy (Pure Functional Core) chuẩn xác theo `docs/04-game/01-pvp-gdd.md` với `combat_rule_version = "solo-three-v0.1"`.

## 2. Nguồn thẩm quyền & Ràng buộc
- Nguồn: `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `assets/game/manifest.json`.
- Server-authoritative: Toàn bộ trạng thái HP, giáp, ward, qi, sát thương, hồi phục và kết quả round do server tính toán. Client tuyệt đối không tự tính toán kết quả hay quyết định thắng/thua.

## 3. Catalog nhân vật chuẩn hóa
Ba nhân vật ban đầu:
1. **Hà Nhân (`ha_nhan`):**
   - Vai trò: Bền bỉ, burst thấp.
   - Nội tại: 2 round đúng liên tiếp hồi 8 giáp sau settle, tối đa 2 lần/trận.
   - Chiêu 1 (1 qi, dùng 1 lần): "Bước Vững" — 25 damage + hồi 6 giáp.
   - Chiêu 2 (2 qi, dùng 1 lần): "Tĩnh Tâm Phản Kích" — 32 damage + hồi 8 HP nếu còn sống.
2. **Tuyệt Đỉnh (`tuyet_dinh`):**
   - Vai trò: Sát thương cao, ít thủ.
   - Nội tại: 2 round đúng liên tiếp buff Đánh thường kế +6 damage (tổng 34), tối đa 2 lần/trận, không cộng dồn.
   - Chiêu 1 (1 qi, dùng 1 lần): "Một Nét Thành Chiêu" — 38 damage.
   - Chiêu 2 (2 qi, dùng 1 lần): "Đường Kiếm Cuối Trang" — 46 damage; Đánh thường round sau còn 22 damage; CẤM dùng ở round 6.
3. **Hàn Bối Pháp (`han_boi_phap`, legacy alias `han_boi_thap`):**
   - Tên hiển thị: "Hàn Bối Pháp".
   - ID chuẩn: `han_boi_phap` (tương thích slug `han-boi-phap` trong `manifest.json`), alias `han_boi_thap` được hỗ trợ ánh xạ tự động.
   - Vai trò: Tanker, kiểm soát nhịp độ.
   - Nội tại: Giáp về 0 lần đầu tiên trong trận -> tạo 12 ward cho round kế tiếp, 1 lần duy nhất/trận.
   - Chiêu 1 (1 qi, dùng 1 lần): "Dựng Tháp" — 18 damage + tạo 14 ward trong round.
   - Chiêu 2 (2 qi, dùng 1 lần): "Trấn Tháp" — 28 damage + hồi 16 giáp.

## 4. Thứ tự xử lý Round (Resolution Pipeline)
1. **Kiểm tra bài làm:**
   - Chỉ `grade == "correct"` mới được kích hoạt hành động (`basic`, `skill_1`, `skill_2`).
   - `incorrect`, `timeout`, `uncertain` -> không gây sát thương, không tạo buff/hồi.
2. **Kích hoạt Buff phòng thủ trong round:**
   - Ward từ passive round trước (nếu có) được đưa vào đầu round.
   - Ward từ chiêu thức (ví dụ Chiêu 1 Hàn Bối Pháp +14 ward) kích hoạt ngay trước khi nhận đòn.
   - Ward tối đa 20 và biến mất sau khi kết thúc round.
3. **Áp dụng sát thương đồng thời (Simultaneous Damage):**
   - Sát thương trừ tuần tự: `ward -> armor -> HP`.
4. **Hồi máu & Giáp:**
   - Chỉ áp dụng SAU KHI trừ sát thương.
   - Nếu `HP <= 0`, nhân vật đã bị hạ gục -> KHÔNG được hồi máu/giáp cứu mạng.
   - HP tối đa 100, giáp tối đa 50.
5. **Cập nhật Năng lượng (Qi) & Nội tại:**
   - Trả lời đúng (`correct`) nhận +1 qi sau round (tối đa 3). Không dùng qi này trong cùng round.
   - Secret round: Round 3 hoặc 5 nhận thêm +1 bonus qi sau round.
   - Cập nhật chuỗi đúng liên tiếp và cờ nội tại.
6. **Xác định kết quả:**
   - Cả 2 HP == 0 -> Hòa (draw).
   - 1 bên HP == 0 -> Bên còn lại thắng (KO).
   - Sau round 6: Bên có HP cao hơn thắng. Nếu HP bằng nhau: Bên có giáp cao hơn thắng. Nếu bằng nhau: Hòa.
