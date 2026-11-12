# Quy định tên, avatar và phát ngôn trong MindClock

**Trạng thái:** quy tắc sản phẩm để triển khai và duyệt với đội vận hành trước pilot; chưa có hệ thống kiểm duyệt đang chạy. Áp dụng cho biệt danh, tên nhóm, ảnh hồ sơ, câu nói/biểu cảm trong đấu trường, báo cáo và nội dung công khai nếu mở sau này. Học tập cá nhân, câu trả lời bài và lời nháp không được công khai hay biến thành nội dung xã hội mặc định.

## 1. Ngôn ngữ mặc định và nội dung của app

Giao diện dùng `vi-VN`, câu ngắn và mô tả được hành động: `Đặt báo thức`, `Bắt đầu học`, `Nộp bài`, `Xem cách làm`, `Tắt âm`, `Dừng khẩn cấp`. Không hứa “chắc chắn tỉnh táo”, “điểm cao”, “AI chấm công tâm tuyệt đối” hay quảng cáo quá mức. Khi làm sai, nói `Cách làm này chưa khớp đáp án; xem gợi ý hoặc thử lại` thay lời chế giễu. Hài hước có ở tên chiêu/biểu cảm tướng, không nhắm vào năng lực, giấc ngủ, giới tính, vùng miền, hoàn cảnh gia đình hoặc khuyết tật. Không dùng emoji hệ thống trong UI chính; icon vector và nhãn chữ theo [docs/30](30-ngon-ngu-va-tai-san-giao-dien.md).

## 2. Biệt danh và tên nhóm

- 3–20 ký tự hiển thị sau chuẩn hóa Unicode NFC, gộp khoảng trắng liên tiếp, không có ký tự điều khiển/ký tự ẩn; cho chữ cái tiếng Việt, số, khoảng trắng và dấu `-`/`_` đơn giản. Không lấy tên từ email, không bắt tên thật. So độ dài theo grapheme khi coding; giới hạn byte riêng để chống lạm dụng.
- Không chứa số điện thoại, email, đường dẫn/liên kết, tài khoản mạng xã hội, địa chỉ, trường/lớp cụ thể hoặc dữ liệu nhận diện người khác. Không mạo danh giáo viên, ban tổ chức, đội vận hành hoặc người nổi tiếng; không dùng tên có thể gây nhầm là tài khoản chính thức.
- Không dùng lời xúc phạm, miệt thị nhóm được bảo vệ, đe dọa, quấy rối, nội dung tình dục, kích động tự hại/bạo lực, quảng cáo/spam hoặc câu lách luật bằng ký tự gần giống. Từ tiếng địa phương, tên riêng và chữ tiếng Việt hợp lệ không bị chặn chỉ vì trùng chuỗi cấm; bộ lọc chỉ **gợi ý kiểm tra**, có người duyệt/kháng nghị.
- Đổi tên có giới hạn tần suất để tránh né báo cáo; lưu phiên bản tên tối thiểu trong audit nội bộ, không hiển thị tên cũ công khai. Khi bị báo, tạm hiện `Người chơi` trên bảng tới khi duyệt; trận/điểm vẫn nguyên, không tự xóa lịch sử.

## 3. Ảnh hồ sơ và avatar

Sáu avatar mặc định do app cung cấp là đường luôn dùng được. Ảnh tải lên phải do người dùng có quyền sử dụng, không có chân dung/người khác, trẻ em khác, bảng tên, đồng phục có thông tin trường/lớp, giấy tờ, mã QR hoặc thông tin liên hệ nếu chưa có quyền và lý do rõ. Không dùng ảnh khỏa thân, bạo lực đồ họa, miệt thị, quảng cáo, logo mạo danh. Không dùng ảnh học sinh thật trong demo AI free tier. App nhắc `Chọn ảnh của bạn hoặc dùng avatar có sẵn. Ảnh công khai cần được duyệt.`

Preview local không đồng nghĩa được công khai. Backend decode, bỏ EXIF, crop/resize và đánh giá. AI có thể hỗ trợ phát hiện rủi ro nhưng **không quyết định cấm tài khoản một mình**. Trong khi `pending`/`rejected`, người khác thấy avatar mặc định; chủ thấy lý do/đường sửa hoặc xin xem lại. Ảnh bị gỡ phải ngừng phát qua cache/CDN và được xóa theo [docs/25](25-bao-mat-va-du-lieu.md). Không giữ ảnh gốc để huấn luyện hoặc debug mặc định.

## 4. Giao tiếp giữa người chơi

MVP giao hữu/ranked không có chat tự do hoặc mic giữa người chơi. Nếu muốn tương tác, chỉ dùng mẫu đã duyệt như `Chúc bạn làm bài tốt`, `Lượt này khá khó`, `Cảm ơn trận đấu`, `Xem lại bài nhé`; có nút tắt mọi biểu cảm, rate limit, không dùng biểu cảm để làm lộ đáp án/trạng thái chấm trước reveal. Không cho nhắn riêng ngoài trận. Nếu sau này mở chat, cần task riêng cho moderation, tuổi, lưu/xóa, bằng chứng, khiếu nại và test an toàn; không mặc nhiên lấy bộ lọc biệt danh áp cho chat là đủ.

## 5. Quy trình báo cáo, xử lý, kháng nghị

`Báo cáo` tại hồ sơ/bảng/trận → chọn lý do (tên/ảnh mạo danh, thông tin cá nhân, quấy rối, spam, khác) → gửi bằng ID nội dung và mô tả tùy chọn. Không yêu cầu người báo chụp lại ảnh bài/đời tư. Hệ thống xác nhận đã nhận, giới hạn spam, giấu người báo khỏi người bị báo. Nội dung nguy cơ cao có thể **tạm ẩn khỏi công khai** để rà soát; người học vẫn dùng báo thức/học cá nhân. Người duyệt xem bằng chứng tối thiểu, ghi `decision`, `rule_version`, lý do và thời hạn; xử lý theo mức độ (sửa tên/ảnh → cảnh báo → giới hạn phần xã hội), không tự trừ XP/RP do một báo cáo. Tài khoản có đường xem lý do và `Yêu cầu xem lại`; reviewer khác xem khiếu nại nếu khả thi. Cần có năng lực vận hành thực trước khi mở upload công khai; nếu chưa có, chỉ mở avatar mặc định.

## 6. Câu mẫu và test chấp nhận

| Tình huống | Nội dung UI |
| --- | --- |
| Tên chưa hợp lệ | `Tên hiển thị cần 3–20 ký tự và không chứa thông tin liên hệ.` |
| Ảnh chờ duyệt | `Ảnh đang được xem lại. Người khác vẫn thấy avatar mặc định.` |
| Ảnh không được chấp nhận | `Ảnh này chưa thể hiển thị công khai. Chọn ảnh khác hoặc yêu cầu xem lại.` |
| Báo cáo đã nhận | `Đã nhận báo cáo. Chúng tôi sẽ xem nội dung này.` |
| Nội dung bị tạm ẩn | `Nội dung đang được xem lại. Việc học và báo thức vẫn dùng bình thường.` |
| Khiếu nại | `Đã nhận yêu cầu xem lại. Kết quả sẽ hiện trong Tài khoản.` |

Test: Unicode tiếng Việt/emoji/zero-width/homoglyph, tên trùng người khác, mạo danh, chứa số/email/URL, sai kết quả bộ lọc, upload ảnh có EXIF/định dạng giả, báo cáo lặp, ảnh pending/ẩn/xóa, cache sau opt-out, kháng nghị đổi quyết định, và không làm sai/AI uncertain/Dừng khẩn cấp thành vi phạm. Luật này không thay chính sách pháp lý phải được duyệt trước phát hành.
