# Sổ thiết kế linh thú và phong cách RPG

**Mục tiêu:** cảm giác đồng hành ấm áp trong hành trình học; nhân vật là phần thưởng thị giác, không đánh giá phẩm chất hay trí thông minh của học sinh. Phong cách khớp [hệ UI](13-he-thiet-ke-ui.md) và [quy chuẩn v2](27-quy-chuan-giao-dien-va-figma.md): “bình minh trên trang vở”, hình tròn đồng hồ, giấy, bút và ánh sáng sáng sớm. **Cập nhật:** nhân vật được tạo hình 3D mềm nhưng xuất ảnh nhẹ cho app; không render 3D liên tục.

## 1. Hướng mỹ thuật thống nhất

- **Dáng:** mô hình 3D stylized như đồ chơi bằng giấy/nhựa mờ, ánh sáng ấm một hướng, render ra ảnh 2D nền trong suốt. Silhouette dễ đọc ở 48 px; tối đa 2–3 mảng màu chính/nhân vật. Tránh texture chi tiết, bóng kim loại và pixel art.
- **Biểu cảm:** mắt/trán/tư thế rõ; không biến nhân vật thành người chấm điểm, không chỉ trỏ/xấu hổ khi sai.
- **Màu:** lấy `ink`, `primary`, `sunrise` từ token chung; thêm tối đa hai màu riêng mỗi nhân vật, phải kiểm tra tương phản trên nền đêm và nền giấy.
- **Kích thước:** trang chủ 96–128 dp, màn hồ sơ 160–220 dp, avatar leaderboard 40–48 dp. Ở màn chuông chỉ dùng icon nhỏ hoặc ẩn để giữ ưu tiên giờ và nút tắt.
- **Bản quyền:** vẽ nhân vật gốc, không dùng meme/nhân vật nổi tiếng hay asset từ game khác. Lưu source, tác giả, licence và quyền sử dụng trong `assets/credits` khi coding.

## 2. Ba nhân vật khởi đầu

| ID | Tên hiển thị | Silhouette và vật liệu | Tính cách/giọng nói | Màu riêng | Dấu hiệu nhận diện ở avatar nhỏ |
| --- | --- | --- | --- | --- | --- |
| `cu_muc` | Cú Mực | Cú tròn, hai chỏm lông như ngòi bút, bụng hình mặt đồng hồ | Điềm tĩnh, tò mò; “Thử thêm một bước nhé” | Lam tím nhạt, vàng giấy | Hai chỏm bút + đôi mắt lớn |
| `cao_nang` | Cáo Nắng | Cáo tai tam giác, đuôi cong như nét mặt trời mọc | Năng động nhưng dịu; “Mình bắt đầu từ phần dễ thôi” | Cam đất, kem | Tai nhọn + đuôi cong |
| `rong_giay` | Rồng Giấy | Rồng nhỏ thân dạng tờ giấy gấp, sừng như góc giấy | Kiên trì, vui; “Sai một bước thì sửa một bước” | Xanh ngọc nhạt, vàng ấm | Góc giấy trên đầu + đuôi gấp |

Tên cần kiểm thử với học sinh miền Trung để đảm bảo dễ gọi và không gây hiểu sai. Nhân vật không gắn giới tính mặc định. Cho chọn lại miễn phí; không khóa nhân vật theo thành tích. Có tùy chọn **Tắt linh thú** trong Cài đặt.

## 3. Trạng thái và tiến hóa

| State | Kích hoạt | Diễn hoạt | Nội dung chữ đi kèm |
| --- | --- | --- | --- |
| `idle` | Trang chủ | Thở rất nhẹ hoặc tĩnh | “Hôm nay bạn muốn ôn gì?” |
| `wake` | Sau khi người dùng vào thử thách | Mở mắt, giơ bút | “Bắt đầu cùng mình nhé” |
| `thinking` | Người dùng đang làm | Nhìn giấy, một dấu hỏi nhỏ | Không chen lời tự động |
| `hint` | Người dùng nhấn Gợi ý | Chỉ vào ô công thức/trọng tâm | Gợi ý từ AI đã kiểm soát |
| `celebrate` | Hoàn thành hoạt động | Nảy nhẹ một lần, không flash | “Bạn đã tự làm xong một bước” |
| `rest` | Nghỉ/hoãn/tắt khẩn cấp | Ngồi yên, không buồn ốm | “Khi sẵn sàng, mình tiếp tục nhé” |
| `uncertain` | AI chưa đọc rõ | Nghiêng đầu nhẹ | “Ảnh này chưa rõ, thử cách khác nhé” |

Không có state “suy dinh dưỡng”, “phạt”, “cà khịa”. Tiến hóa có 3 lớp cosmetic: **Mầm** (bản gốc), **Bạn đồng hành** (phụ kiện vở/bút), **Người khám phá** (vệt ánh sáng/vòng đồng hồ). Mốc đề xuất ở 0/250/800 XP cá nhân, cần chỉnh sau pilot. Không tiến hóa theo ELO, giờ thức dậy hay tiền. Khi nghỉ, nhân vật giữ nguyên. Huy hiệu mùa có thể gắn cạnh avatar nhưng không che tên/rank.

## 4. Inventory asset để giao họa sĩ và dev

Mỗi nhân vật cần một `character sheet` gồm: front, 3/4, profile; 7 trạng thái ở trên; bản sáng/tối; 3 kích thước xuất; avatar tròn; icon silhouette đơn sắc. Lưu mô hình nguồn và quyền sử dụng; export PNG/WebP nền trong suốt ở kích thước cần dùng sau khi đo trên Flutter. Có thể xuất chuỗi 6–10 frame cho một cử động ngắn, nhưng bản tĩnh là fallback bắt buộc. Không cần engine 3D trong app. Mọi chuyển động tuân thủ giảm chuyển động của OS và [ngân sách hiệu năng](27-quy-chuan-giao-dien-va-figma.md#6-chuyển-động-không-gây-lag).

Tên file dự kiến: `pet_<id>_<state>_<stage>_<theme>.<ext>`. Metadata: `id`, `displayNameVi`, `altTextVi`, `stage`, `states`, `palette`, `assetVersion`, `credit`. Không tải remote asset lúc chuông reo; bundle bản nhỏ trong app. Ảnh đại diện gửi bảng xếp hạng chỉ là `avatarId` từ whitelist, không cho upload ảnh cá nhân ở v1.

## 5. Quy tắc UI và nội dung

- **Trang chủ:** linh thú đặt bên dưới thông tin báo thức, không che giờ; có nút xem nhân vật.
- **Sau bài:** linh thú mừng nỗ lực, không tuyên bố “thông minh hơn” từ một bài.
- **Đấu trường:** avatar 40–48 dp và tên; kết quả thua có câu “Bạn đã hoàn thành trận, xem lại cách giải”, không có cảnh thú bị đánh.
- **Màn hồ sơ:** chọn linh thú, đổi phụ kiện, xem mốc XP và lý do nhận; không có gacha/loot box, mua vật phẩm, streak pressure.
- **Accessibility:** alt text nêu trạng thái hữu ích (“Cú Mực đang chào”), không mô tả trang trí lặp lại; màu không là tín hiệu duy nhất; tắt animation theo cài đặt.

## 6. Brief tạo concept art

> Thiết kế ba linh thú gốc cho ứng dụng học tập tiếng Việt MindClock: Cú Mực, Cáo Nắng, Rồng Giấy. Tạo hình 3D stylized mềm như đồ chơi bằng giấy/nhựa mờ, bình minh trên trang vở, thân thiện với học sinh 13–18 tuổi. Render ra ảnh 2D nhẹ. Silhouette rõ ở avatar 48 px, mỗi nhân vật chỉ 2–3 mảng màu, ánh mắt ấm áp. Tạo front và 3/4, biểu cảm bình thường, suy nghĩ, vui sau khi hoàn thành. Nền trong suốt, không chữ, không vũ khí, không yếu tố phạt hay bệnh tật, không giống nhân vật có bản quyền.

**Điều kiện duyệt:** 5 người xem nhận ra ba nhân vật ở 48 px; đủ phân biệt khi bỏ màu; câu thoại không tạo áp lực; file có nguồn gốc/quyền sử dụng. Chưa có artwork thật trong repo.

