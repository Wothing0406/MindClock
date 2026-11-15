# Cảnh mở màn trước câu học: nội dung và nguồn video

**Vai trò:** trong lượt báo thức thử thách, một cảnh ngắn tạo tình huống cần giải thích rồi chuyển sang **câu đã duyệt cùng kiến thức**. Đây là nội dung học, không phải clip truyền động lực chung. [Luồng sáng](09-giac-ngu-va-bao-thuc.md), [MorningCard](../02-engineering/11-eduskills-vn-tich-hop.md), [ngân hàng câu](../02-engineering/05-ngan-hang-cau-hoi.md). Chưa có bộ video đã được duyệt/đóng gói trong app chỉ vì tài liệu này có ví dụ.

## 1. Một cảnh nên diễn ra như thế nào

Một `MorningCard` dùng **6–12 giây** trong app sau khi âm chuông đã được dừng, tỷ lệ dọc. Nhịp biên tập: 0–3 giây đặt bối cảnh, 3–8 giây có biến cố hoặc dữ kiện thiếu, 8–12 giây dừng ở câu cần suy nghĩ. Đến điểm dừng, chuyển thẳng vào câu tự luận ngắn; không có lời giải trong cảnh. Sau kết thúc lượt, kể cả bỏ lượt, có thể xem đoạn kết/lời giải đã duyệt. `Bỏ qua mở màn` chỉ bỏ cảnh, không bỏ câu. Không phát âm video chồng lên chuông; tắt tiếng mặc định hoặc dùng âm riêng đã có quyền và phù hợp mức âm user chọn.

Không yêu cầu **video quay thật** cho mọi câu. Cảnh có thể là motion graphic 2D từ tài sản gốc, clip đội tự quay, hoặc đoạn tư liệu có quyền. Nếu máy yếu/Reduce Motion/asset lỗi/offline, dùng một ảnh tĩnh kèm 1–2 câu chữ tương đương; câu và Dừng khẩn cấp vẫn hoạt động. Chỉ cache trước media `published`, không tải/stream đúng giây báo thức. Giới hạn chiều dài và kích thước tệp là ngân sách hiệu năng phải đo trên máy Android mục tiêu, không được kéo dài thời gian chờ để nạp clip.

## 2. Thư viện tình huống theo môn

| Môn | Cảnh 6–12 giây có thể làm | Điểm dừng → câu có trình bày | Nguồn nên ưu tiên |
| --- | --- | --- | --- |
| Vật lí | Quả bóng/chiếc cặp tiếp tục chuyển động khi xe mô hình dừng; con lắc qua vị trí thấp | “Hiện tượng gì? Nêu một lý do.” | Đội tự quay mô hình hoặc vẽ 2D để kiểm soát điều kiện. Tư liệu [con lắc Foucault trên Pexels](https://www.pexels.com/video/a-pendulum-display-on-public-swinging-during-daytime-6117694/) chỉ là ứng viên bối cảnh, chưa gắn với câu/rubric. |
| Hóa học | Cận cảnh dung dịch đổi màu; dừng **trước** khi cho biết chất nào đã thêm | “Nếu biết hai chất A/B trong đề, em dự đoán hiện tượng và giải thích.” | Thí nghiệm đội quay có biên bản chất/điều kiện. [Clip đổi màu Pexels](https://www.pexels.com/video/chemical-reaction-in-beaker-with-color-change-37348838/) chỉ minh họa màu; **không suy phản ứng/chất từ hình stock**. |
| Sinh học | Hạt nảy mầm/khí khổng/chu trình tế bào dạng thời gian rút gọn | “Yếu tố nào giúp quá trình này diễn ra? Vì sao?” | Tự quay hoặc tư liệu [hạt nảy mầm Pexels](https://www.pexels.com/video/plant-tl-3-18356707/) sau khi reviewer xác nhận câu không đòi chi tiết clip không cung cấp. |
| Toán | Đường parabol 2D hiện lên theo tham số, một điểm vượt khỏi dự đoán của nhân vật | “Từ đồ thị/dữ kiện, viết một bước để tìm đỉnh hoặc nghiệm.” | Motion graphic vector do đội tạo; stock footage thường không chứa dữ kiện toán chính xác. |
| Lịch sử | Timeline/bản đồ tái hiện mốc đã kiểm; dừng trước hệ quả | “Sự kiện tiếp theo liên hệ thế nào với nguyên nhân vừa thấy?” | Bản đồ/hình gốc đội vẽ; tư liệu từ Wikimedia Commons phải kiểm **giấy phép từng file** và tính đúng lịch sử. |
| Địa lí | Bản đồ 2D với một lớp khí hậu/dân số ẩn, sau đó hiện một dữ kiện | “Dựa vào bản đồ/số liệu, giải thích sự khác biệt.” | Dữ liệu đã được reviewer duyệt, đồ họa đội vẽ; không lấy số liệu từ video nền ngẫu nhiên. |
| Tiếng Anh | Hai avatar gốc nói một câu hội thoại, dừng ở lựa chọn cách diễn đạt phù hợp | “Viết câu đáp và giải thích một lựa chọn từ/ngữ pháp.” | Hoạt ảnh 2D, giọng/sound do đội tạo hoặc cấp quyền; phụ đề tiếng Việt khi cần. |
| Ngữ văn | Chữ động trên một đoạn **do đội viết/có quyền** hoặc tranh gốc, dừng trước một cách hiểu | “Nêu một chi tiết và điều em suy ra từ nó.” | Text/illustration gốc; không lấy đoạn phim/nhạc/văn bản còn bản quyền chỉ vì thấy online. |

Hà Nhân/Tuyệt Đỉnh/Hàn Bối Pháp có thể xuất hiện như **người đặt tình huống hoặc đoán sai nhẹ** nếu asset gốc và quyền đã duyệt; không cần mọi video chứa tướng PvP. Câu học không được trở thành câu đố đoán mẹo hoặc câu hỏi về một đoạn phim không liên quan môn học. Một cảnh có thể dùng cho nhiều biến thể câu **chỉ khi** cùng `learningOutcome` và reviewer duyệt từng liên kết.

## 3. Nguồn để lấy media

Ưu tiên theo thứ tự:

1. **Đội tự tạo:** motion graphic 2D từ asset gốc, quay thí nghiệm/đồ vật bằng điện thoại, thu âm câu thoại của đội. Dễ khớp chính xác câu hỏi và tránh clip làm sai kiến thức. AI/EduSkills có thể viết **storyboard nháp**, không tự biến skill môn thành tệp video; reviewer môn chốt nội dung.
2. **Pexels/Pixabay:** lấy cảnh nền hoặc hiện tượng thật rồi cắt/dựng thành cảnh ngắn có lời dẫn gốc. [Pexels cho phép dùng/sửa trong app](https://www.pexels.com/license/); [Pixabay cho phép dùng/sửa có điều kiện](https://pixabay.com/service/license-summary/). Kiểm người nhận diện được, logo, vật thể có quyền và ngữ cảnh từng clip; lưu bằng chứng tại ngày lấy.
3. **Wikimedia Commons:** hữu ích cho tư liệu lịch sử/địa lí/khoa học; giấy phép và yêu cầu ghi nguồn nằm trên **trang file cụ thể**, có thể là CC BY/CC BY-SA và nghĩa vụ ghi công/chia sẻ tương ứng. [Hướng dẫn tái sử dụng](https://commons.wikimedia.org/wiki/Commons:Reusing_content_outside_Wikimedia/licenses/en).
4. **Mixkit:** chỉ chọn file ghi **Video Free License** hợp phạm vi. Cùng website còn có **Restricted License** cho mục đích cá nhân; không đưa một clip vào app chỉ vì nút tải ghi “free”. [Bảng giấy phép Mixkit](https://mixkit.co/license/).

Không tải lại clip từ YouTube/TikTok, phim/hoạt hình hoặc kênh giáo dục rồi cắt vào app nếu chưa có quyền cụ thể. Link xem/nhúng không tự cấp quyền đóng gói, chỉnh sửa và phát hành clip; YouTube có [chính sách riêng cho API/player](https://developers.google.com/youtube/terms/developer-policies/). Không dùng ảnh/video học sinh thật nếu chưa có quyền và đồng ý phù hợp. Nhạc nền/âm thanh phải kiểm quyền **riêng** với hình.

## 4. Sổ nguồn và đường duyệt trước publish

Mỗi `assetId` cần registry: `sourceKind`, `sourceUrl`, `creator`, `licenseName`, `licenseUrl`, `capturedAt`, bằng chứng giấy phép lưu nội bộ, `commercialAppUseAllowed`, `editAndBundleAllowed`, `attributionText`, người/logo/nhạc và quyền liên quan, `contentHash`, bản cắt, `reviewerId`, `learningOutcome`, `questionId + revision`, `status=draft|reviewed|published|retired`. Với clip tự tạo, lưu người tạo và xác nhận quyền thành phần. Credit nếu cần có trong màn `Nguồn nội dung`; không giấu vì là clip vài giây.

Quy trình: storyboard theo môn/lớp/câu → chọn quay/tạo/nguồn → kiểm quyền từng clip → biên tập 6–12 giây + phụ đề + poster tĩnh → reviewer bộ môn kiểm cảnh/câu/rubric → kiểm trên máy yếu/không mạng/Reduce Motion → publish immutable version. Asset bị rút quyền hoặc sai kiến thức phải retire và chuyển về bản chữ/câu khác; không để alarm phụ thuộc tệp đó. [Acceptance MEDIA-01–03](../03-quality/05-ca-nghiem-thu.md).

Khi mở task asset, mỗi card có một manifest và biến thể theo nền tảng trong cấu trúc dự kiến `assets/learning/morning_cards/<cardId>/` gồm `manifest.json`, `poster.webp`, `hook.mp4` hoặc bộ animation 2D, `captions.vtt`, âm tùy chọn. Backend lưu bản được duyệt theo `assetId + version + contentHash`; client chỉ cache bản cần cho những alarm sắp tới, không tải toàn bộ thư viện. Tệp nguồn chỉnh sửa, chứng cứ giấy phép và bản gốc stock lưu riêng trong kho biên tập có kiểm soát; không commit bừa vào APK/Git. Đây là đường dẫn **dự kiến**, chưa tạo folder/clip chạy thật.
