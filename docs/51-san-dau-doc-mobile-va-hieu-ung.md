# Sân đấu dọc trên điện thoại: tướng, thao tác và hiệu ứng

**Phạm vi:** đặc tả UX/runtime cho sân luyện web cục bộ. Luật trận online phải theo [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md), chấm bài theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). Demo có câu mẫu và đối thủ kịch bản, không chấm phần trình bày bằng AI, không xếp hạng.

## 1. Màn dọc và thứ tự đọc

Ở 320–390 CSS px: tiêu đề ngắn → chọn 1/3 tướng → tên/HP/giáp hai bên → sân canvas **360:380** co theo chiều rộng → trạng thái chữ và `Bỏ qua` → câu mẫu/đáp án/cách làm → ba nút Đánh thường/Chiêu 1/Chiêu 2 → mô tả tướng và nút xem trạng thái → avatar/khung mẫu. Không xoay ngang. Nút tối thiểu 44 CSS px, không có nút chiêu phủ lên đề. Ở desktop, sân và điều khiển nằm hai cột nhưng **cùng một logical stage**, không thay scale/luật theo viewport. Khi bàn phím mở, ô trả lời vẫn cuộn tới được; không khóa trình duyệt.

Trên màn sản phẩm thật, **đề và vùng trình bày lớn hơn trận game**, theo docs/46. Sau nộp, server chấm cả hai rồi mới hiện hành động. Web demo nộp câu số học định sẵn để thử UI; phần cách làm chỉ bắt buộc nhập, chưa được chấm đúng/sai. Nút chiêu khóa khi chưa trả lời đúng/thiếu khí/đã dùng. Không được mô tả demo là học thuật công tâm hay PvP online.

## 2. Ba tướng: thông tin người chơi phải đọc được

| Tướng/vai | Mô tả ngắn trong app | Nội tại và trigger | Chiêu 1 | Chiêu 2 | Cách dùng/đánh đổi |
| --- | --- | --- | --- | --- | --- |
| **Hà Nhân**, đấu sĩ bền bỉ | Tu sĩ áo vải, bình tĩnh, luôn giữ một tập giấy bên người. | **Giữ Nhịp:** 2 bài đúng liên tiếp hồi 8 giáp, tối đa 2 lần/trận. Vòng giấy xanh nổi trên chính Hà Nhân. | **Bước Vững:** 1 khí, 25 damage, hồi 6 giáp sau damage. Vệt giấy bay tới đối thủ, vòng giáp ở Hà Nhân. | **Tĩnh Tâm Phản Kích:** 2 khí, 32 damage, hồi 8 HP nếu sống. Vòng xanh đôi bay tới mục tiêu; vòng hồi ở Hà Nhân. | Dùng khi giáp mỏng. Sát thương dồn thấp, cần giữ chuỗi đúng. |
| **Hàn Bối Pháp**, hộ pháp phòng thủ | Hộ pháp đeo tháp giấy, nghiêm túc hơi quá. | **Tháp Còn Đứng:** giáp vỡ lần đầu nhận 12 chắn ở vòng kế, một lần/trận. Tháp xuất hiện trên chính hộ pháp. | **Dựng Tháp:** 1 khí, 18 damage, +14 chắn trong round. Tháp nhỏ bay tới địch; chắn lớn ở chủ. | **Trấn Tháp:** 2 khí, 28 damage, hồi 16 giáp. Ấn tháp xanh bay tới địch; đường viền giáp ở chủ. | Chọn chắn trước đòn mạnh. Ít damage nên khó kết trận sớm. |
| **Tuyệt Đỉnh**, kiếm sĩ sát thương | Kiếm khách áo đỏ, ra chiêu rất chắc tay; tóc đôi khi không nghe lời. | **Kiếm Ý:** 2 bài đúng liên tiếp cho Đánh thường kế +6, tối đa 2 lần/trận, không cộng dồn. Vệt kiếm đỏ chỉ ở kiếm sĩ. | **Một Nét Thành Chiêu:** 1 khí, 38 damage, không hồi/chắn. Nét mực bay theo hướng đối thủ. | **Đường Kiếm Cuối Trang:** 2 khí, 46 damage, Đánh thường vòng sau chỉ 22; không cho dùng ở round 6. Hai đường kiếm chéo chạm mục tiêu. | Dồn đúng nhịp, nhưng không có hồi giáp và chịu hậu quả chiêu 2. |

Đánh thường chung: 28 damage/0 khí. Mọi con số là v0.1 cần playtest, không có chí mạng/ngẫu nhiên sát thương. Choáng trong bảng xem trạng thái chỉ là mỹ thuật, **không mất lượt**. Nhãn vai trò và nội tại phải hiện trong thẻ tướng và chi tiết, không chỉ nằm trong docs.

## 3. Timeline hiệu ứng và âm thanh

| Thời điểm | Lớp ảnh | Tọa độ và âm |
| --- | --- | --- |
| 0 ms | Pose tướng đánh `basic/skill1/skill2` | Âm riêng tướng/chiêu, sau khi người dùng bật âm. |
| 120–515 ms | Projectile SVG riêng | Từ `attacker root ±28` tới `target root ∓28`, cung cao 22 px. Khi bên phải đánh, hướng đảo. |
| 515 ms | Kết quả số, `hurt` ở đối thủ | Âm impact chung; HP/giáp/chắn phải lấy từ kết quả đã chốt. |
| 515–815 ms | Hit FX ở đối thủ; self FX ở người dùng nếu có hồi/chắn | Không dán projectile lên thân chủ hoặc đặt vòng hồi trên địch. |
| ≤950 ms | Trở về idle | `Bỏ qua` kết thúc motion nhưng không sửa số. |
| Theo event nội tại | Passive riêng trên tướng sở hữu | Không dùng một sprite cho mọi tướng. |
| Kết thúc thắng | 6 frame `victory` + nhịp nhấc nhẹ + âm riêng | Chỉ sau khi kết quả trận/sân được chốt. |

Âm `stun`, `basic`, `skill1`, `skill2`, `victory` là file riêng từng tướng; `impact`, `heal` dùng chung. Mặc định tắt, có nút bật/tắt rõ và không tự phát khi tải trang. Không có âm tiếng người hoặc nhạc bản quyền. Nếu `prefers-reduced-motion`, giữ hình tĩnh/số và không lặp animation; cần kiểm VoiceOver/TalkBack riêng khi có app thật.

## 4. Tính toán kích thước và hiệu năng

Canvas asset 512², vùng hình cao 400 px; vẽ 240² trên stage 360×380 tạo nhân vật xấp xỉ `400/512×240 = 187,5 px` cao. Hai chân cùng root y=350, cách biên dưới 30 px; root x=92/268 cách nhau 176 px. Bbox action phải không chạm mép canvas; projectile/impact là lớp riêng nên không làm đổi kích thước tướng. Draw dùng `requestAnimationFrame` nhưng giới hạn khoảng 35 fps khi có motion, ~7 fps khi đứng; tải frame bằng cache, không gọi AI/mạng giữa trận. Thiết bị thật phải đo thêm frame time/memory, tránh hứa 60 fps.

Một file map gốc portrait được crop giữ tỉ lệ để vừa stage; không ép 9:16 thành 360:380. Khung rank 7 SVG gồm Thường + 6 tier mỹ thuật; **huy hiệu rank riêng 6 SVG** cho kết quả/hồ sơ; avatar mặc định 6 WebP, có preview ảnh tải lên cục bộ; không dùng emoji hệ thống. Asset có thể bị thay bằng fallback tĩnh khi thiếu ảnh. Các vị trí và nội dung là một phần của [manifest](../demo/assets/game/manifest.json), [cấu trúc](50-cau-truc-du-an-va-asset-game.md) và [hồ sơ](52-ho-so-avatar-huy-hieu-va-lich-su.md).

## 5. Điều phải kiểm trên máy trước buổi thi

1. Mở `demo/arena.html` qua máy chủ cục bộ, xem ở 320/360/390 dp; nhân vật nhìn nhau, chân không cắt, đề và nút không tràn khi bàn phím mở.
2. Với cả 3 tướng, làm câu đúng, dùng Đánh thường/2 chiêu; xem vệt xuất phát từ người đánh, bay vào bên còn lại, hit FX và số đặt trên người nhận. Khi đổi tướng, FX và tiếng đổi theo.
3. Gây giáp vỡ cho Hàn Bối Pháp, làm hai bài đúng với Hà Nhân/Tuyệt Đỉnh, kiểm passive bật đúng người và đúng giới hạn.
4. Xem Choáng, Trúng đòn, Hồi phục, Thắng; kiểm âm bật/tắt, bỏ qua, Reduce Motion; không cộng điểm hạng.
5. Dùng Android Chrome trên máy thật. Bản web không thay cho APK báo thức; theo [runbook Android](47-demo-android-va-moi-truong-kiem-thu.md) để làm app sau.
