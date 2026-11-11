# Thiết kế nhân vật, avatar, khung hạng và bảng xếp hạng

**Trạng thái:** đặc tả giao diện để dựng Figma/Flutter, **chưa có artwork hoặc màn chạy thật**. Luật kỹ năng ở [40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md), số RP/bậc ở [37](37-kinh-te-rank-va-nhan-vat-2d.md), token và chuyển động ở [27](27-quy-chuan-giao-dien-va-figma.md), quyền bảng ở [21](21-dau-truong-xep-hang.md). Màn hằng ngày dùng ngôn ngữ ngắn, không emoji, không quảng cáo.

## 1. Bộ nhân vật giao họa sĩ

Mỗi nhân vật có một **master 3/4**, bản đứng nhìn thẳng, silhouette đơn sắc, avatar vuông trong suốt, bản tĩnh và sprite trạng thái. Thiết kế gốc dùng nét giấy/bút phẳng, tối đa 3 mảng màu chính; không lấy hình người thật, meme có bản quyền hoặc tạo vẻ đau đớn khi mất HP. Tên/ID, silhouette và kit phải giữ ổn định qua asset revision. Màu phụ dưới đây là **đề xuất thiết kế**, phải đo tương phản trên nền giấy/đêm; không đổi token chữ/nút của app.

| ID / tên | Hình nhận ra ở 48 dp | Bảng màu phụ đề xuất | Tư thế và biểu cảm | Dấu hiệu kỹ năng riêng |
| --- | --- | --- | --- | --- |
| `cu_muc` · Cú Mực | đầu tròn, hai chỏm lông như ngòi bút, mắt lớn | lam mực `#53688B`, kem giấy `#E9DDBF` | đứng thẳng/nhìn vở; vui bằng mắt, không nhảy liên tục | lọ mực sáng một nhịp ở `owl_ink_charge`, +10 đòn đúng vòng sau |
| `cao_nang` · Cáo Nắng | hai tai nhọn, đuôi cong như nét mặt trời | cam đất `#B96542`, kem `#F2D5AD` | nghiêng người nhẹ, đuôi tạo hướng nhìn; không tạo cảm giác vội/thi nhanh | nét giấy lách sang bên ở `fox_feint`, 16 sát thương và chặn 6 nếu trúng đòn |
| `rong_giay` · Rồng Giấy | sừng là góc gấp giấy, đuôi xếp nếp | ngọc nhạt `#5B9B91`, vàng giấy `#E5BD70` | thân giấy gấp, vững; mắt bình tĩnh | một tờ giấy gập trước avatar ở `dragon_fold`, 5 sát thương/chặn 16 |
| `hiep_si_bia_vo` · Hiệp Sĩ Bìa Vở | mũ/giáp bìa vở và một kẹp giấy rõ | lam xám `#697C8D`, kem `#E9DCC7` | người mặc giáp giấy, tay trống hoặc giữ kẹp giấy; không vũ khí sắc | kẹp giấy nằm trên thẻ riêng đối thủ ở `binder_stun`, khóa thẻ riêng vòng kế |

**Pose tối thiểu mỗi nhân vật:** `idle` tĩnh, `think`, `ready`, `attack`, `guard`, `heal`, `stunned`, `win`, `rest`; biến thể `hurt` không dùng. `stunned` là dấu kẹp/thẻ bị khóa, người học vẫn được trả lời. `rest` không buồn/ốm. Cảnh báo lỗi và chữ không được đặt lên mặt avatar. Tên file/manifest theo [22 §4](22-nhan-vat-rpg.md); thêm `silhouette_asset`, `avatar_asset`, `static_fallback`, `anchor_x/y`, `source_credit`, `asset_version`, `kit_version`. Mỗi frame giữ cùng điểm neo, có vùng trong suốt để FX không cắt tai/đuôi/kẹp.

**Bộ duyệt asset:** PNG/WebP nền trong suốt ở kích thước xuất thực tế sau khi đo Flutter; avatar 48 dp và bản 2×/3×, master trận 96 dp, silhouette 48 dp. Năm người học nhìn bản không màu ở 48 dp vẫn phân biệt được 4 nhân vật; nếu không, sửa silhouette trước khi làm animation. Có alt text như `Cú Mực`, không đọc màu/chi tiết trang trí. Sprite/FX có source file, tác giả và quyền dùng; ảnh sinh từ công cụ phải kiểm quyền đầu ra riêng.

## 2. Màn chọn nhân vật và avatar

`Tôi → Nhân vật`: đầu trang là nhân vật đang dùng (hình tĩnh, tên, một câu mô tả), dưới là lưới bốn ô cùng kích thước. Một ô có `Đang dùng`, ô đã sở hữu có `Chọn`, ô chưa sở hữu có `Xem thử` và giá `300 Đồng Mực` nếu cửa hàng đã mở. Trang chi tiết cho xem kỹ năng riêng bằng **số và chữ**, ví dụ `Nạp Mực · 12 sát thương; đòn đúng vòng sau +10`; có ví dụ nhỏ và điều kiện `chỉ khi bài đúng rõ`. Không phải chơi trận mới biết kỹ năng. `Xem thử` không mua hoặc trang bị; mua có màn xác nhận giá/số dư, xong có `Dùng nhân vật này` hoặc `Để sau`.

Khách chưa đăng nhập được chọn avatar **trên máy** để xem giao diện; chưa có sở hữu/ví server. Khi tạo tài khoản, cho chọn **một trong bốn nhân vật miễn phí đúng một lần**; không tự mua hộ hay lấy coin. Đăng xuất/đổi tài khoản không hiện lựa chọn/coin của người trước; chuông local vẫn giữ hoạt động theo [24](24-dang-ky-va-quan-ly-tai-khoan.md). Không cho tải ảnh cá nhân làm avatar ở v1; `avatarId` luôn thuộc allowlist asset đã duyệt. Đổi nhân vật đã sở hữu miễn phí, không đổi HP gốc/RP hay lịch học.

## 3. Khung avatar và bậc hạng

Có **hai lớp khác nhau**: viền tiến độ học từ XP (riêng tư, trang trí) và viền RP đấu trường theo môn/mùa (chỉ hiện khi đã bật ranked và đủ 5 trận). Không gọi cả hai là `rank`; trên UI dùng `Tiến độ học` và `Hạng đấu trường`. Khung không mang sức mạnh. Avatar không bị thu nhỏ quá 40 dp hoặc che mặt; viền và nhãn phải nhìn được khi không có màu.

| RP tier | Hình khung tối giản | Nhãn đọc màn hình | Màu phụ đề xuất |
| --- | --- | --- | --- |
| Đồng | vòng đơn + 1 rãnh ở đáy | `Đồng, bậc 1 đến 5` | nâu đồng dịu |
| Bạc | vòng đôi mảnh + 2 rãnh | `Bạc, bậc 1 đến 5` | xám bạc đậm |
| Vàng | vòng đôi + 3 rãnh | `Vàng, bậc 1 đến 5` | vàng đất đậm |
| Bạch Kim | khung 4 cạnh bo + 4 rãnh | `Bạch Kim, bậc 1 đến 5` | xanh xám |
| Kim Cương | khung 5 cạnh nhẹ + 5 rãnh | `Kim Cương, bậc 1 đến 5` | xanh ngọc đậm |
| Tinh Anh | vòng nét kép + 6 rãnh ngắn | `Tinh Anh, bậc 1 đến 5` | lam mực |

**Bậc 1–5 luôn là chữ/số** `Đồng 4`, kèm 5 vạch ngắn chỉ bậc hiện tại; không tạo 30 file khung riêng. Component `RankFrame(tier, division, avatarId, size, reducedMotion)` dựng từ 6 nền khung vector và 5 vạch; màu chỉ là phụ. Kích thước: 48 dp trong bảng, 72 dp ở hồ sơ, 96 dp ở màn lên bậc. Chừa ít nhất 4 dp giữa viền và silhouette. Khi `unranked/placement`, dùng viền thường và nhãn `Đang xếp hạng`; khi chưa opt-in hoặc mùa đóng, không giả khung rank đang hoạt động. Lên bậc: một chuyển động 300–500 ms sau kết quả, cho bỏ qua; Reduce Motion dùng khung tĩnh ngay. XP frame giữ vòng giấy đơn giản, không trùng hình RP.

## 4. Bốn màn đấu trường cần thiết kế

| Màn | Trật tự thông tin từ trên xuống | Hành động/trạng thái |
| --- | --- | --- |
| Sảnh | `Giao hữu` trước, chọn môn/khối/bộ nội dung, `Nhập mã mời`/`Mời bạn`; sau đó khu `Có hạng` khóa khi chưa mở | không ghép khác chương trình để lấp hàng chờ; nếu chưa đủ người, `Luyện môn này` |
| Phòng chờ/trận | hai avatar + HP dạng số/thanh, môn/vòng/giờ server, thẻ đã khóa, **đề và ô viết chiếm phần lớn**, nút Nộp, mạng/reconnect | trước khi lộ đề chỉ chọn thẻ; lúc đang chấm không hiện ai thắng; FX chỉ sau event server |
| Kết quả | thắng/hòa/thua hoặc trận không tính hạng, RP trước → sau **nếu ranked hợp lệ**, XP/coin hàng riêng, một chủ đề cần ôn | `Xem cách giải`, `Báo chấm sai`, `Về sảnh`; void/uncertain nêu `Điểm hạng không đổi` |
| Bảng mùa | selector môn/khối/bộ nội dung/mùa, giải thích RP, thời điểm cập nhật, top 20 + vị trí của tôi khi đủ quyền | `Ẩn tôi khỏi bảng`, trạng thái chưa đủ người/đang cập nhật/mất mạng; không hiện trường, giờ dậy, ảnh bài |

**Dòng bảng:** hạng bằng chữ/số, avatar 40–48 dp có khung, biệt danh tối đa hai dòng, nhãn bậc, RP; không hiện MMR, số giờ học, streak hoặc lịch. Người cùng RP có **cùng số hạng**; thứ tự ổn định theo `userId` nội bộ để tránh nhảy, không dùng thời điểm nộp/giờ dậy. Trang công khai không hiển thị `myPosition` nếu người dùng chưa opt-in; khi đã opt-in, vị trí của tôi nằm hàng riêng không tự cuộn tới đáy. Có thể ẩn biệt danh bất cứ lúc nào; cache trên client phải bỏ hàng cũ ngay và API kiểm quyền tại thời điểm đọc.

**Trạng thái bắt buộc:** `giao hữu chưa mở`, `ranked chưa đạt cổng`, `đang xếp hạng (<5 trận)`, `bảng chưa đủ người`, `đang tải`, `dữ liệu cũ do mất mạng`, `đã rời bảng`, `mùa kết thúc`, `trận chờ chấm`, `trận void/uncertain`, `asset thiếu`. Không dùng `0 RP` để thay một trạng thái chưa có dữ liệu. Prototype Figma/HTML phải ghi `Mô phỏng` nếu chưa nối backend; không thể hiện các hàng mẫu là người thật.

## 5. Kiểm tra giao diện và hiệu năng

- Figma dựng các màn 320/360/390 dp, cỡ chữ 200%, TalkBack; kiểm tra bốn nhân vật ở 48 dp dạng màu và silhouette, khung 6 tier/5 division, trạng thái tối và sáng. Token từ [13](13-he-thiet-ke-ui.md) và [27](27-quy-chuan-giao-dien-va-figma.md); UI học tập vẫn là ưu tiên, nhân vật không che đề/nút Dừng.
- Sprite preload phòng chờ, FX sau reveal 300–500 ms, một FX tại một thời điểm, không chờ FX để tiếp tục; giảm chuyển động/frame tĩnh, không GIF mạng/3D/emoji. Đo máy Android yếu; nếu giật thì bỏ animation trước khi giảm cỡ đề.
- Test với 5–8 học sinh: nhận biết `Giao hữu` khác `Có hạng`, XP khác RP/Đồng Mực, chọn miễn phí/mua, biết ai thấy biệt danh và tìm nút Ẩn. Ghi bấm nhầm/thời gian/câu nói; đây là test khả dụng, chưa chứng minh game cuốn hút hay cân bằng.
