# Pet nhóm và thẻ chia sẻ — thiết kế đề xuất

## Trạng thái thật

T070 đã tạo bộ art pet Mầm gốc: master, 4 giai đoạn ngoại hình và 6 reaction **tĩnh**, đóng gói WebP/alpha trong assets/companions và app/assets/companions. [Asset và QA](../../assets/companions/README.md). T074 đã có nhóm kín, pet ledger và EXP nhóm server-authoritative. T075 đưa pet chính lên màn Hôm nay, cho đổi pet chính giữa tối đa 3 nhóm và xuất thẻ PNG 1080×1080 qua Android share sheet. Chu kỳ animation toàn thân vẫn chưa có; ảnh tĩnh không được mô tả như animation.

## Một pet chung có gì để quay lại?

Đề xuất nhân vật gốc tên **Mầm**: thú nhỏ tròn như hạt đậu, hai tai hình lá, đeo túi giấy đựng bút. Hình dáng rõ ở 48px, nét mặt vui nhẹ, không dùng tạo hình phim/game của bên khác. Đặt tên pet do cả nhóm chọn, có quy tắc moderation như biệt danh. Cần duyệt master trước khi sản xuất hoạt ảnh.

Mỗi người học vì mục tiêu riêng; đóng góp hợp lệ giúp nhóm xây một góc bàn học cho Mầm. Điểm thú vị đến từ ngoại hình mới và phản ứng cụ thể: xếp bút quá ngay ngắn rồi làm rơi một cây, ôm chồng sách cao hơn mình, ngủ trong hộp bút. Không spam tiếng/meme khi đang học sâu. Khi không ai học, Mầm nghỉ tại tổ ấm; không bệnh, không mất máu hoặc trách người vắng.

Ba vòng tiến triển riêng:
- Ngày chăm: một dấu xác nhận/ngày từ server, không nhân vì nhấn nhiều lần. Theo quy tắc nhóm hiện hành: ít nhất một thành viên đủ điều kiện, hai người trở lên có ghi nhận Cùng nhau.
- Mốc đóng góp tích lũy mở ngoại hình/tổ ấm, không reset khi đứt chuỗi. Không đổi thành RP hoặc sức mạnh tướng.
- Bộ sưu tập theo hoạt động: phiên học hoàn thành, tuần duy trì và ngày nhóm; unlock theo event/catalog có version, retry idempotent. Chưa dùng số phút tự khai để xác nhận học thật.

## Các giai đoạn hình ảnh

| Giai đoạn đề xuất | Thay đổi nhìn thấy | Nội dung mở thêm |
| --- | --- | --- |
| Vừa gặp | Mầm nhỏ bên một cuốn vở | Đặt tên, idle/chào |
| Quen bàn học | Túi bút và khăn nhỏ | Feed/reaction mới, màu tổ ấm |
| Cùng tiến bộ | Lá tai dài hơn, huy hiệu nhóm trên túi | Trang trí kệ sách, hoạt cảnh nâng cấp |
| Góc học chung | Ngoại hình trưởng thành giữ silhouette cũ | Cảnh cả nhóm, khung thẻ kỷ niệm |

Không chốt ngưỡng cấp trước pilot; backend catalog quy định ngưỡng và preview phần sắp mở. Không ngẫu nhiên trả tiền và không ép thức khuya/dậy sớm để giữ pet.

## Asset cần sản xuất

Mỗi stage cần master, thumbnail, pose tĩnh Reduce Motion, idle 4–6 frame, happy/feed 6–8 frame, sleep 4 frame, level-up 8–12 frame. Cần nền tổ ấm, vật phẩm trang trí tách layer, icon chăm, mốc chuỗi và khung thẻ share; âm chúc mừng tùy chọn chỉ sau phiên. Đặc tả export: transparent WebP/PNG, cùng canvas và foot pivot, atlas có manifest frame/duration/hash/provenance; không trộn nhân vật/FX tướng vào pet. Tạo ảnh từng stage giữ model sheet gốc, không dùng một ảnh đứng rồi rung/nháy thay hoạt ảnh.

## Chia sẻ lên mạng xã hội

Nút **Chia sẻ thành tích** sau mốc nhóm hoặc tiến hóa, có preview và tự bỏ qua. Thẻ vuông 1080×1080 hoặc dọc 1080×1920: pet đúng stage, số ngày nhóm được server xác nhận, nhãn “Chuỗi chăm nhóm”, mốc vừa mở, logo nhỏ. Không gọi là streak TikTok hoặc hứa tăng chuỗi của nền tảng khác.

Mặc định không có email, mã phòng riêng, mã mời, TKB, giờ thức dậy, tên thật, vị trí hoặc hình thành viên. Tên nhóm chỉ khi bật chia sẻ; tên/avatar từng bạn chỉ khi người đó đồng ý, không lấy quyền host làm consent thay cả nhóm. Có tùy chọn bỏ toàn bộ tên.

Android dùng share sheet sau thao tác user, xuất ảnh tạm vào cache, cấp đọc bằng `FileProvider` rồi dọn file cũ theo TTL; không tự đăng lên TikTok/Facebook, không cần người dùng đăng nhập các mạng này trong MindClock. Nếu app đích không hỗ trợ thì bridge trả trạng thái rõ, không crash. Mất mạng chỉ dùng snapshot đã xác nhận, không tự tăng số ngày; chưa có dữ liệu thì không dựng thẻ thành tích giả.

T075 mặc định ẩn tên nhóm; switch trong preview mới cho phép hiện. File đã kiểm trên emulator là PNG 1080×1080 và share sheet nhận đúng `image/png`. Máy Android thật vẫn là cổng bắt buộc trước release.

## Điều kiện nghiệm thu

Group membership/consent đúng thời điểm; grant/care idempotent; timezone/ngày nghỉ/system-grace; avatar/asset có quyền; preview không lộ dữ liệu private; cancel share không mất thưởng; Rotate/Reduce Motion và offline không làm sai số ngày; share không tự đăng. Cần kiểm ảnh xuất ra thực tế và Android share sheet trên máy thật trước phát hành.
