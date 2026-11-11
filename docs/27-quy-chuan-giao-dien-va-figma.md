# Quy chuẩn giao diện MindClock v2 — tối giản cho học sinh Việt

**Quyết định mỹ thuật:** giao diện học tập phẳng, sáng rõ; nhân vật và kỹ năng là sprite 2D gốc với nét giấy/bút. Màn báo thức, đề bài và lời giải vẫn dễ đọc. Tài liệu này cụ thể hóa [hệ UI](13-he-thiet-ke-ui.md), [linh thú](22-nhan-vat-rpg.md), [kinh tế/asset 2D](37-kinh-te-rank-va-nhan-vat-2d.md) và [hành trình](23-hanh-trinh-san-pham.md). Đây là **spec thiết kế**, chưa có file Figma hay sprite hoàn thiện.

Quy tắc câu chữ và asset không emoji ở [docs/30](30-ngon-ngu-va-tai-san-giao-dien.md). Prototype hiện tại dùng SVG placeholder; React chỉ dùng nếu đội chọn làm web/dashboard, không thay thế bộ asset nhân vật.

## 1. Bản sắc và những điều cần tránh

**Một hình ảnh nhớ được:** vòng đồng hồ nét đơn, trên nền giấy sáng sau khi thức dậy. Nét kẻ giấy chỉ dùng ở vùng câu hỏi, không phủ khắp app. Chừa khoảng trắng và để nội dung thật tạo nhịp; không tạo nhiều card giống nhau, gradient mờ và bóng đổ cho mọi khối.

**Tông Việt Nam:** câu chữ ngắn, tự nhiên, phù hợp học sinh lớp 9–12: `Ngày mai có Toán`, `Thử một câu ngắn`, `Xem gợi ý`, `Chụp bài`, `Dừng chuông`. Tránh `Quest`, `Battle pass`, `AI-powered`, `Học bá thần thoại` ở tác vụ cơ bản. Nội dung thi đấu có thể dùng `Giao hữu`, `Bảng tuần`, `Điểm đấu trường` khi người dùng chủ động vào tab đó.

**Không giống giao diện AI phổ biến:** không dùng nền tím xanh gradient, kính mờ, glow, bot chat nổi mọi màn, emoji thay icon, hàng loạt thẻ bo 24 px, chữ in hoa giãn rộng, prompt AI như màn chính. AI chỉ xuất hiện dưới tên dễ hiểu `Gợi ý` và `Nhận xét bài làm`; giải thích ở phần quyền dữ liệu rằng bài có thể được gửi đến dịch vụ AI.

## 2. Token để thiết kế và coding

Giữ palette đã chọn trong [docs/13](13-he-thiet-ke-ui.md): `paper #F7F7F2`, `surface #FFFFFF`, `ink #1B2741`, `inkMuted #526078`, `primary #126F73`, `sunrise #F4B95F`, `night #101A30`, `outline #D7DFE5`. Không thêm màu cho từng màn. Màu rank là màu **trang trí phụ**, không thay màu nút hành động, chữ hoặc trạng thái đúng/sai.

| Vai trò | Quy tắc |
| --- | --- |
| Chữ | Một font chính hỗ trợ dấu Việt đầy đủ, đề xuất Be Vietnam Pro sau khi xác nhận licence/glyph; fallback Noto Sans. Chỉ 3 trọng lượng 400/600/700. |
| Cỡ | Giờ 56–64 sp; tiêu đề màn 26–28; tiêu đề mục 18–20; nội dung 16; phụ 14. Không dùng chữ dưới 12 sp. |
| Nhịp | Lề 20 dp ở màn hẹp; khoảng 8/12/16/24/32 dp; chữ canh trái, chỉ số giờ và avatar có thể canh giữa. |
| Hình | Card chỉ dùng khi gom một nhiệm vụ hoặc dữ liệu liên quan. Vùng nội dung thường phân bằng khoảng trắng, không cần viền. |
| Góc | 8 dp cho chip, 14–16 dp cho nút/card, 24 dp cho tờ đề nổi bật; không bo đồng loạt. |
| Nút | Mỗi màn một hành động chính; nút phụ dạng chữ/viền. Vùng chạm mục tiêu ≥48×48 dp; cách nhau đủ để không bấm nhầm khi mới ngủ dậy. |
| Tương phản | Văn bản thường ≥4.5:1, icon/đường điều khiển ≥3:1 trên nền thực tế; trạng thái phải có chữ đi kèm. |

## 3. Hệ icon

**Chọn một bộ duy nhất:** icon nét tròn 24 px, stroke tương đương 2 px ở kích thước chuẩn; không trộn emoji, outline và icon đặc theo ngẫu hứng. Nếu dùng thư viện icon, chốt licence/phiên bản và chọn tập con trong repo khi coding. Với 4 tab, icon có hai trạng thái outline/filled cùng hình học; tab chọn có thêm nhãn màu `primary`, không chỉ đổi màu icon.

| Vị trí | Icon gợi ý | Nhãn luôn hiện | Hành động |
| --- | --- | --- | --- |
| Tab 1 | đồng hồ đơn | Hôm nay | Báo thức/lịch hôm nay |
| Tab 2 | bút trên trang | Luyện tập | Chọn môn và làm bài |
| Tab 3 | hai lá bài hoặc hai chấm đối diện | Đấu trường | Giao hữu/bảng khi đã mở |
| Tab 4 | người đơn giản | Tôi | Tiến bộ, nhân vật, cài đặt |
| Câu hỏi | quyển vở | Câu hôm nay | Mở đề |
| Gợi ý | bóng đèn nét nhỏ | Xem gợi ý | Hiện đúng một gợi ý |
| Chụp | camera | Chụp bài | Xin quyền rồi mở camera |
| Nhập | bàn phím | Nhập đáp án | Đường thay thế camera |
| Hoãn/Dừng | đồng hồ có dấu cộng / hình vuông dừng | Hoãn 5 phút / Dừng chuông | Dùng chữ rõ, không chỉ icon |
| Riêng tư | ổ khóa | Quyền riêng tư | Xem dữ liệu/consent |

Không dùng biểu tượng kiếm, vương miện hoặc tia sét ở màn báo thức/học. Icon rank là **huy hiệu riêng** trong hồ sơ và bảng. Mỗi icon có `semanticLabel` tiếng Việt; icon chỉ trang trí thì ẩn khỏi trình đọc màn hình.

## 4. Bố cục và thao tác từng màn

```text
HÔM NAY                       LÀM BÀI
Ngày/tiết học                 Quay lại · Toán 9
Giờ báo thức kế tiếp          Câu hỏi trên nền giấy
Nút sửa giờ                   Chỗ viết/nhập đáp án
Môn cần ôn hôm nay            Xem gợi ý
Tiến bộ ngắn                  Chụp bài | Nhập đáp án
Tab bar                       Gửi bài

ĐẤU TRƯỜNG                    TÔI
Giao hữu (nút chính)          Tên/biệt danh riêng tư
Môn + khối                    XP và hạng học tập
Bảng tuần (nếu opt-in)        Nhân vật + phụ kiện
Giải thích cách tính          Quyền riêng tư/cài đặt
Tab bar                       Tab bar
```

**Chuông reo:** chỉ giờ lớn, môn/câu một dòng, `Bắt đầu thử thách`, `Hoãn 5 phút`, `Dừng chuông`; nút Dừng không chìm vào menu. **Làm bài:** tối đa một câu, không banner rank/nhân vật che bài. **Kết quả:** một câu nhận xét và một bước cần sửa; chỉ sau đó mới có XP/huy hiệu. **Đấu trường:** hiển thị giao hữu trước bảng, không mở bằng bảng thành tích để tránh áp lực. **Tôi:** tách `Hạng học tập` khỏi `Điểm đấu trường` bằng nhãn giải thích, không để hai số cạnh nhau như cùng thang đo.

Mỗi thao tác phải có trạng thái `đang xử lý`, `thành công`, `không có dữ liệu`, `mất mạng`, `không đủ quyền`. Tên nút và thông báo kết quả dùng cùng động từ: `Lưu báo thức` → `Đã lưu báo thức`; `Gửi bài` → `Đã nhận bài`. Không dùng toast biến mất cho lỗi cần xử lý.

## 5. Nhân vật sprite 2D và khung rank

**Quyết định kỹ thuật thiết kế:** vẽ sprite 2D gốc, xuất WebP/PNG trong suốt; một hành động dùng 4–8 frame ở 8–12 fps khi cần. Giữ một bản tĩnh cho máy yếu, giảm chuyển động hoặc asset lỗi. Preload trong phòng chờ; hiệu ứng kỹ năng chỉ sau reveal và không trì hoãn đề. Xem [manifest asset và cổng cân bằng](37-kinh-te-rank-va-nhan-vat-2d.md#5-sprite-2d-và-bộ-asset-kỹ-năng).

| Thành phần | Thiết kế | Giới hạn |
| --- | --- | --- |
| Nhân vật | Nét giấy/bút phẳng, 2–3 mảng màu, mắt rõ, không bóng kim loại | 3/4 front là góc chính; silhouette rõ ở 48 px |
| Khung avatar thường | Vòng mảnh màu `outline`, nền giấy | Không gradient/glow |
| Đồng/Bạc/Vàng | Vòng đôi mảnh, chấm/rãnh 1/2/3 ở cạnh dưới; màu đồng/bạc/vàng dịu | Nhận ra cả khi bỏ màu nhờ số rãnh |
| Bạch Kim/Kim Cương | Hình vòng có 4/5 cạnh nhẹ, nét rõ; nhãn hạng bên dưới | Không gai nhọn/vương miện lớn; không rung/nhấp nháy |
| Huy hiệu mùa | Phù hiệu nhỏ bên cạnh tên, mở trang giải thích khi chạm | Không gắn lên mặt nhân vật |

Khung học tập từ XP là cosmetic; điểm đấu trường dùng nhãn đầy đủ `Đồng 4 · Toán 9` và 1–5 vạch nhỏ cho bậc theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md), không chỉ màu. Khi lên bậc, hiển thị một lần ở màn kết quả trận, có thể đóng ngay; không chiếm màn báo thức. Nhân vật giữ nguyên vẻ khỏe/vui khi người dùng nghỉ hoặc sai bài. Chi tiết 3 nhân vật và asset tại [docs/22](22-nhan-vat-rpg.md).

## 6. Chuyển động không gây lag

| Tình huống | Chuyển động tối đa | Fallback |
| --- | --- | --- |
| Nhấn nút/chuyển màn | 120–220 ms, chỉ opacity/transform, không blur toàn màn | Thay trạng thái tức thì |
| Hoàn thành bài | Một cử động nhân vật 500–800 ms, chạy một lần | Ảnh tĩnh + chữ |
| Lên hạng | Vòng khung xuất hiện 300–500 ms, không hạt sáng | Khung tĩnh |
| Trang chủ idle | Mặc định **tĩnh**; nếu thử nghiệm thích hợp, cử động rất thưa khi màn đang mở | Luôn tĩnh khi pin yếu/giảm chuyển động |
| Chuông reo | Không animation trang trí | UI tĩnh, ưu tiên nút Dừng |

Nguyên tắc coding: preload asset nhỏ trong bundle; không tải animation từ mạng khi chuông reo. Tạm dừng hoạt họa khi tab không hiện, app background, pin yếu hoặc OS bật giảm chuyển động. Tránh nhiều animation đồng thời, shader/blur/glow, particle và canvas vẽ lại toàn màn. Đo trên máy Android yếu trong đội: mục tiêu thao tác không giật ở 60 Hz, frame build/raster thông thường dưới ~16 ms; nếu không đạt, giảm frame/kích thước hoặc bỏ animation. Kích thước asset mục tiêu ban đầu: avatar ≤50 KB, ảnh nhân vật thường ≤200 KB, chuỗi động tổng ≤500 KB/nhân vật; số này là ngân sách thiết kế cần đo trên file thật, không phải cam kết hiệu năng.

## 7. Cấu trúc file Figma để đội dựng

Tạo file `MindClock · UI v1` khi đội bắt đầu thiết kế, với trang: `00 Foundations` (tokens/chữ/icon), `01 Components` (nút, chip, card, avatar, khung rank và variants), `02 Core flows` (onboarding, báo thức, làm bài, phản hồi), `03 Social` (giao hữu, bảng, hồ sơ), `04 States` (loading/empty/error/offline/permissions), `05 Handoff` (prototype link, asset export, ghi chú). Frame điện thoại 360×800 và 390×844, kiểm tra 320 dp; tất cả nội dung là tiếng Việt thật, không dùng lorem ipsum. Components dùng Auto Layout, màu/chữ/spacing lấy từ Variables/Styles, tên layer rõ cho Flutter.

**Bàn giao cho coder:** mỗi màn có trạng thái mặc định + lỗi/empty; luồng click qua được; icon set, font licence, asset render, kích thước xuất, alt text, hành vi giảm chuyển động, khoảng chạm và bản mô tả nút Dừng. Không ghi “Figma đã thiết kế” khi mới có spec này. Đối chiếu screenshot Flutter trên máy thật với frame; sai khác có chủ đích phải ghi vào task coding.

## 8. Checklist duyệt giao diện

- Học sinh mới hiểu nút chính của từng màn trong 5 giây; không cần biết thuật ngữ AI/RPG.
- Đọc được chữ Việt dấu đầy đủ ở 320 dp và khi phóng chữ 150–200%.
- Nút Dừng chuông luôn hiện; không lẫn với “Gửi bài”.
- Một bộ icon đồng nhất, nhãn chữ đủ; không dùng emoji như asset cuối.
- Nhân vật không che đề/giờ, khung rank không làm bảng khó đọc.
- Bật giảm chuyển động hoặc máy yếu vẫn sử dụng đầy đủ tính năng.
- Có test với 5–8 học sinh mục tiêu, ghi chỗ họ bấm nhầm và chỉnh trước khi khóa design.

