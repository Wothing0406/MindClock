# Sổ thiết kế linh thú và phong cách RPG

**Mục tiêu:** cảm giác đồng hành ấm áp trong hành trình học; nhân vật không đánh giá phẩm chất hay trí thông minh của học sinh. Phong cách khớp [hệ UI](13-he-thiet-ke-ui.md) và [quy chuẩn v2](27-quy-chuan-giao-dien-va-figma.md): “bình minh trên trang vở”, hình tròn đồng hồ, giấy, bút và ánh sáng sáng sớm. Chỉ thiết kế sprite/FX 2D; roster và kỹ năng hiện hành theo [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md), mở nhân vật bằng Đồng Mực theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md).

Trong [Solo RPG](35-solo-rpg-dong-bo-va-ky-nang.md), mỗi nhân vật chọn hai trong bốn thẻ chung và một thẻ riêng; tất cả dùng cùng HP/câu hỏi, không có thưởng tốc độ mode viết. Kỹ năng riêng cần qua cổng cân bằng trước ranked. Phụ kiện/khung là cosmetic. Bản giao diện từng nhân vật, avatar, khung và bảng ở [docs/43](43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md); quyền sở hữu/API/test ở [docs/44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md).

## 1. Hướng mỹ thuật thống nhất

- **Dáng:** nhân vật 2D phẳng với nét giấy/bút và mảng màu ấm, silhouette dễ đọc ở 48 px; tối đa 2–3 mảng màu chính/nhân vật. Tránh texture chi tiết, bóng kim loại và khối 3D. Pixel art chỉ dùng nếu cả bộ UI chuyển sang pixel art, không trộn phong cách.
- **Biểu cảm:** mắt/trán/tư thế rõ; không biến nhân vật thành người chấm điểm, không chỉ trỏ/xấu hổ khi sai.
- **Màu:** lấy `ink`, `primary`, `sunrise` từ token chung; thêm tối đa hai màu riêng mỗi nhân vật, phải kiểm tra tương phản trên nền đêm và nền giấy.
- **Kích thước:** trang chủ 96–128 dp, màn hồ sơ 160–220 dp, avatar leaderboard 40–48 dp. Ở màn chuông chỉ dùng icon nhỏ hoặc ẩn để giữ ưu tiên giờ và nút tắt.
- **Bản quyền:** vẽ nhân vật gốc, không dùng meme/nhân vật nổi tiếng hay asset từ game khác. Lưu source, tác giả, licence và quyền sử dụng trong `assets/credits` khi coding.

## 2. Bốn nhân vật khởi đầu

| ID | Tên hiển thị | Silhouette và vật liệu | Tính cách/giọng nói | Màu riêng | Dấu hiệu nhận diện ở avatar nhỏ |
| --- | --- | --- | --- | --- | --- |
| `cu_muc` | Cú Mực | Cú tròn, hai chỏm lông như ngòi bút, bụng hình mặt đồng hồ | Điềm tĩnh, tò mò; “Thử thêm một bước nhé” | Lam tím nhạt, vàng giấy | Hai chỏm bút + đôi mắt lớn |
| `cao_nang` | Cáo Nắng | Cáo tai tam giác, đuôi cong như nét mặt trời mọc | Năng động nhưng dịu; “Mình bắt đầu từ phần dễ thôi” | Cam đất, kem | Tai nhọn + đuôi cong |
| `rong_giay` | Rồng Giấy | Rồng nhỏ thân dạng tờ giấy gấp, sừng như góc giấy | Kiên trì, vui; “Sai một bước thì sửa một bước” | Xanh ngọc nhạt, vàng ấm | Góc giấy trên đầu + đuôi gấp |
| `hiep_si_bia_vo` | Hiệp Sĩ Bìa Vở | Người mặc áo giáp bìa vở, vai là mép giấy, tay cầm kẹp giấy | Điềm đạm, hơi vụng; “Để mình giữ nhịp” | Lam xám, kem | Mũ bìa vở + kẹp giấy |

Tên cần kiểm thử với học sinh miền Trung để đảm bảo dễ gọi và không gây hiểu sai. Nhân vật không gắn giới tính mặc định. Chọn một nhân vật miễn phí ban đầu, các nhân vật còn lại mở bằng Đồng Mực kiếm từ nhiệm vụ; đổi giữa nhân vật **đã sở hữu** miễn phí. Có tùy chọn **Tắt linh thú** trong Cài đặt; tắt hình vẫn giữ khả năng trả lời và xem kỹ năng bằng chữ.

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

Không có state “suy dinh dưỡng”, “phạt”, “cà khịa”. Tiến hóa có 3 lớp cosmetic: **Mầm** (bản gốc), **Bạn đồng hành** (phụ kiện vở/bút), **Người khám phá** (vệt ánh sáng/vòng đồng hồ). Mốc đề xuất ở 0/250/800 XP cá nhân, cần chỉnh sau pilot. Không tiến hóa theo RP, giờ thức dậy hay tiền thật. Khi nghỉ, nhân vật giữ nguyên. Huy hiệu mùa có thể gắn cạnh avatar nhưng không che tên/rank. Mở nhân vật khác bằng Đồng Mực không làm biến mất cấp cosmetic đã có.

## 4. Inventory asset để giao họa sĩ và dev

Mỗi nhân vật cần một `character sheet` 2D gồm front, 3/4, profile; các trạng thái học tập ở trên và `ready/attack/guard/charge/win` cho trận; bản sáng/tối, avatar tròn, icon silhouette. Lưu file nguồn 2D và quyền sử dụng; export PNG/WebP nền trong suốt ở kích thước cần dùng sau khi đo trên Flutter. Mỗi cử động ngắn 4–8 frame, 8–12 fps nếu cần, bản tĩnh là fallback bắt buộc. Mọi chuyển động tuân thủ giảm chuyển động của OS và [ngân sách hiệu năng](27-quy-chuan-giao-dien-va-figma.md#6-chuyển-động-không-gây-lag); manifest FX chi tiết ở docs/37 §5.

Tên file dự kiến: `pet_<id>_<state>_<stage>_<theme>.<ext>`. Metadata: `id`, `displayNameVi`, `altTextVi`, `stage`, `states`, `palette`, `assetVersion`, `credit`. Không tải remote asset lúc chuông reo; bundle bản nhỏ trong app. Ảnh đại diện gửi bảng xếp hạng chỉ là `avatarId` từ whitelist, không cho upload ảnh cá nhân ở v1.

## 5. Quy tắc UI và nội dung

- **Trang chủ:** linh thú đặt bên dưới thông tin báo thức, không che giờ; có nút xem nhân vật.
- **Sau bài:** linh thú mừng nỗ lực, không tuyên bố “thông minh hơn” từ một bài.
- **Đấu trường:** avatar 40–48 dp và tên; kết quả thua có câu “Bạn đã hoàn thành trận, xem lại cách giải”, không có cảnh thú bị đánh.
- **Màn hồ sơ:** chọn linh thú miễn phí lúc bắt đầu, xem nhân vật khác và giá Đồng Mực cố định, đổi phụ kiện, xem mốc XP và lịch sử coin. Không có gacha/loot box hoặc ép streak.
- **Accessibility:** alt text nêu trạng thái hữu ích (“Cú Mực đang chào”), không mô tả trang trí lặp lại; màu không là tín hiệu duy nhất; tắt animation theo cài đặt.

## 6. Brief tạo concept art

> Thiết kế bốn nhân vật **sprite 2D gốc** cho ứng dụng học tập tiếng Việt MindClock: Cú Mực, Cáo Nắng, Rồng Giấy và Hiệp Sĩ Bìa Vở. Chất liệu giấy và nét bút phẳng, bình minh trên trang vở, thân thiện với học sinh 13–18 tuổi. Silhouette rõ ở avatar 48 px, mỗi nhân vật 2–3 mảng màu, ánh mắt ấm áp. Tạo front và 3/4, biểu cảm bình thường, suy nghĩ, vui sau khi hoàn thành; thêm pose hồi, hút, choáng/thẻ riêng theo docs/40. Nền trong suốt, không chữ, không vũ khí sắc, không yếu tố phạt hay bệnh tật, không giống nhân vật có bản quyền.

**Điều kiện duyệt:** 5 người xem nhận ra bốn nhân vật ở 48 px; đủ phân biệt khi bỏ màu; câu thoại không tạo áp lực; file có nguồn gốc/quyền sử dụng. Chưa có artwork thật trong repo.

