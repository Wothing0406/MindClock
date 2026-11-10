# Đặc tả mở rộng sau MVP

Tài liệu này giữ trọn ý tưởng MindClock ban đầu để đội có hướng coding dài hạn. **Không phải phạm vi DevFest/MVP.** Mỗi phần có điều kiện mở, quy tắc tối thiểu và kiểm thử cần có; chi tiết API/data sẽ được version hóa khi bước vào giai đoạn tương ứng.

## 1. Chọn câu thích ứng theo trình độ

**Mục đích:** người học gặp câu vừa sức và ôn lại chỗ hay sai. Không dùng rank làm thước đo năng lực học.

- `topicMastery` cho mỗi chủ đề nhận giá trị 0–100, khởi đầu 50, cập nhật từ câu đúng/sai có độ tin cậy và thời gian ôn; không tính câu `uncertain` là sai.
- Chỉ chọn câu trong bộ đã duyệt, đúng lớp/môn/chủ đề. Thuật toán ưu tiên: môn trong lịch hôm nay → chủ đề đến hạn ôn → mức khó phù hợp → tránh câu vừa gặp gần đây.
- Tăng độ khó tối đa một bậc/tuần sau ít nhất 5 câu có kết quả rõ; khi tỷ lệ sai cao, giảm độ khó hoặc cho câu nền tảng, không hạ rank/XP.
- Bản chấm AI cung cấp tín hiệu về lỗi chủ đề; người biên tập nội dung phải kiểm tra taxonomy lỗi trước khi dùng làm phân tích.
- **Chỉ số:** tỷ lệ hoàn thành, mức “vừa sức” tự báo, kết quả câu tự làm lại sau 1–7 ngày.

## 2. Linh thú đồng hành

**Mục đích:** tạo cảm giác tiếp nối thói quen tích cực. Thiết kế không trừng phạt hình ảnh linh thú khi người dùng ngủ thêm, bị ốm, bận việc hoặc làm sai.

- Người học chọn một linh thú, có thể tắt tính năng. Vật phẩm/huy hiệu nhận từ mốc **tham gia và tiến bộ cá nhân**; không bán vật phẩm tạo lợi thế học tập.
- Trạng thái linh thú: cơ bản, vui vẻ, tiến hóa theo mốc XP; không có “suy dinh dưỡng”, “bị bệnh” hoặc thông báo cà khịa.
- Ảnh/meme cộng đồng phải có kiểm duyệt, bản quyền và quy tắc nội dung phù hợp người chưa thành niên.
- `pet_profile` có `petType`, `skin`, `evolutionStage`, `earnedAt`; không chứa ảnh/câu trả lời của học sinh.
- Kiểm thử: người dùng hiểu đây là phần thưởng, không thấy xấu hổ vì bỏ một ngày; chế độ tắt không làm mất chức năng học.

## 3. Nhóm học tập và lớp

**Mục đích:** tạo hoạt động tự nguyện cùng bạn học, tránh biến dữ liệu thức dậy thành công cụ giám sát.

- Nhóm mời bằng mã ngắn có hạn dùng; học sinh chấp nhận tham gia và có thể rời nhóm bất cứ lúc nào. Không tự động gắn lớp từ danh bạ.
- Điểm nhóm tính theo **tỷ lệ tham gia** với trần đóng góp mỗi người/ngày để lớp đông không luôn thắng; không công khai ai đã tắt khẩn cấp.
- Bảng thành tích dùng biệt danh, có lựa chọn ẩn khỏi bảng. Không có chat tự do ở phiên bản đầu để giảm rủi ro quấy rối.
- `groups/{groupId}`, `memberships`, `group_day_aggregate`; tổng hợp theo ngày, không chia sẻ ảnh bài làm.
- Kiểm thử quyền: người ngoài không đọc được nhóm; rời nhóm chặn truy cập; không suy ra lịch ngủ của một cá nhân từ nhóm quá nhỏ.

## 4. Dashboard giáo viên

**Mục đích:** chỉ ra chủ đề nhiều học sinh đang vướng để giáo viên điều chỉnh bài ôn.

- Chỉ hiển thị dữ liệu sau khi nhà trường/giáo viên và học sinh tham gia đúng quy trình đồng ý. Bản đầu hiển thị **tổng hợp chủ đề** khi đủ số học sinh, ví dụ ít nhất 5 người; không hiện ảnh hoặc thời điểm thức dậy từng em.
- Chỉ số: số người thử chủ đề, tỷ lệ câu rõ chấm đúng, nhóm lỗi phổ biến, biến động theo tuần; luôn ghi mẫu số và tỷ lệ `uncertain`.
- Không gắn nhãn “học sinh yếu” từ một ảnh AI chấm. Không dùng dữ liệu để chấm điểm chính thức.
- `classrooms`, `class_memberships`, `topic_aggregates`; giáo viên có quyền theo lớp, hết quyền khi rời lớp/trường.
- Kiểm thử: lớp ít người không lộ cá nhân; kết quả AI bị sửa phải cập nhật tổng hợp; phụ huynh không truy cập dashboard giáo viên.

## 5. Góc nhìn phụ huynh

**Mục đích:** hỗ trợ trao đổi về thói quen học, không giám sát mọi hành vi sáng sớm.

- Học sinh và người giám hộ thấy rõ dữ liệu nào được chia sẻ: số buổi ôn trong tuần, chủ đề đang học, lời khen/gợi ý hỗ trợ. Không mặc định chia sẻ ảnh, lịch sử tắt chuông, giờ ngủ hoặc thứ hạng.
- Quyền theo quan hệ giám hộ được xác thực và có quy trình thu hồi/phân quyền theo độ tuổi, chính sách áp dụng. Không tự nối tài khoản qua cùng email/số điện thoại.
- Câu chữ hướng dẫn phụ huynh hỗ trợ thay vì phạt khi thiếu streak.
- Kiểm thử: thu hồi quyền có hiệu lực; không thể xem dữ liệu ngoài phạm vi đã chọn.

## 6. Đấu trường kiến thức 1v1

**Mục đích:** hoạt động ôn tự chọn, tách khỏi báo thức. Không ép thi đấu lúc mới thức dậy.

- Trận theo chủ đề, lớp và độ khó; hai người nhận câu tương đương từ bộ đã duyệt. Cần cân bằng độ khó trước khi áp dụng ELO.
- Bắt đầu bằng trận **không tính hạng** và bảng kết quả riêng tư. Chỉ mở ELO khi có đủ người chơi, bộ câu cân bằng, kiểm soát độ trễ và tranh chấp kết quả.
- Nếu có ELO: kết quả từ server, thời hạn nộp theo server clock, xử lý mất kết nối, hòa, hủy trận, AI `uncertain`, chống nộp lại. Không trừ ELO khi AI chấm chưa chắc. K-factor và matchmaking phải được thử nghiệm, không chốt số trong MVP.
- Không cho nhắn tin tự do giữa trẻ em, có chặn/báo cáo người dùng; leaderboard biệt danh và opt-out.
- `matches`, `match_participants`, `match_submissions`, `rating_ledger`; audit để giải quyết tranh chấp.
- Kiểm thử: cùng đề/độ khó, race condition, trễ mạng, nộp kép, hủy trận, phản hồi chấm sai, lạm dụng tài khoản.

## 7. Nhiều môn và đa phương thức

- **Toán/Lý/Hóa:** ảnh bài viết tay phù hợp khi rubric đánh giá được các bước. Cần chuẩn hóa ký hiệu, đơn vị, nhiều cách giải.
- **Anh:** trước tiên câu trả lời ngắn, từ vựng/ngữ pháp; phát âm là nhánh riêng, cần tập âm thanh và consent rõ. Không nói “chấm chuẩn giọng” khi chưa có đánh giá bởi giáo viên.
- **Văn/Sử:** câu mở cần rubric và chấm hỗ trợ, hạn chế tự động kết luận đúng/sai nhị phân; ưu tiên gợi ý và tự đánh giá.
- **Sinh/Địa/Công nghệ:** bộ câu do giáo viên duyệt, có nguồn nội dung và cập nhật theo chương trình học.
- Mỗi môn có `answerSpec` và evaluator riêng; không ép mọi bài vào một prompt chung.

## 8. Tính bền vững

Mục tiêu tiếp cận rộng, nhưng Gemini và hạ tầng có chi phí. Trước khi nói “miễn phí cho mọi học sinh”, đo số lượt chấm/ngày, token/ảnh, tỉ lệ dùng offline, chi phí người dùng hoạt động và nguồn tài trợ. Không bán dữ liệu học sinh, không dùng quảng cáo cá nhân hóa nhắm vào trẻ em. Kế hoạch kinh doanh chỉ chốt sau khi có pilot và rà soát quyền riêng tư.

