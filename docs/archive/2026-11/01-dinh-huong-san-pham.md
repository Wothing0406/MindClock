# MindClock — định hướng sản phẩm cho DevFest Miền Trung 2026

> Cập nhật: 10/11/2026. Đây là tài liệu ý tưởng và phạm vi demo, chưa khẳng định chức năng nào đã được triển khai.

## 1. Câu nói 20 giây

**MindClock biến khoảnh khắc tắt báo thức thành một lần tự nhớ lại kiến thức của môn học trong ngày.** Học sinh giải một câu ngắn trên giấy; AI đọc lời giải, chỉ ra bước cần xem lại và gợi ý để em tự sửa. Mỗi sáng hoàn thành một thử thách vừa sức, em nhìn thấy tiến bộ học tập và thói quen dậy đúng giờ.

**Slogan:** Đánh thức phản xạ, bứt phá tư duy mỗi sớm mai.

## 2. Bài toán và giả thuyết cần kiểm chứng

| Nhận định ban đầu | Giả thuyết có thể kiểm chứng | Cách kiểm chứng |
| --- | --- | --- |
| Học sinh dễ tắt báo thức rồi ngủ tiếp | Một thử thách 60–90 giây sẽ giúp các em chủ động rời giường hơn | So sánh số ngày dậy đúng giờ trong tuần dùng thử với tuần trước đó |
| Nhiều em xem lời giải AI nhưng chưa tự làm được | Câu hỏi tự nhớ lại kiến thức, kèm gợi ý từng nấc, giúp nhận ra chỗ chưa hiểu | Bài kiểm tra ngắn không có AI vào ngày hôm sau; phỏng vấn học sinh |
| Sáng đến lớp chưa biết ôn gì | Câu hỏi gắn với thời khóa biểu sẽ thấy liên quan hơn câu hỏi ngẫu nhiên | Hỏi học sinh mức độ phù hợp; theo dõi tỷ lệ hoàn thành |

Đây là **giả thuyết sản phẩm**, chưa phải kết quả đã được chứng minh cho MindClock. Nghiên cứu về thực hành truy hồi kiến thức ủng hộ hướng thiết kế ôn tập chủ động, nhưng không chứng minh rằng một câu hỏi lúc báo thức sẽ cải thiện điểm số hay giấc ngủ của mọi học sinh. [Tổng quan nghiên cứu về retrieval practice](https://pubmed.ncbi.nlm.nih.gov/41803160/).

## 3. Chọn một người dùng đầu tiên

**Học sinh lớp 9** có lịch học cố định, đang ôn chuyển cấp, dùng điện thoại Android và muốn dậy đúng giờ đi học. Một bạn thử nghiệm tiêu biểu: *Minh, 14 tuổi, có tiết Toán đầu buổi, đặt báo thức 06:30 và thường bấm ngủ thêm.* Tên và tình huống này là nhân vật minh họa, không phải dữ liệu khảo sát.

Trong bản demo, chỉ cần một môn **Toán lớp 9**, một chuyên đề **phương trình bậc nhất**, một thời khóa biểu mẫu và một buổi sáng mô phỏng. Việc chọn hẹp giúp giám khảo nhìn thấy chất lượng vòng học tập trọn vẹn.

## 4. Vòng trải nghiệm cốt lõi

1. **Tối hôm trước:** Người học chọn giờ dậy và môn Toán cho buổi học tiếp theo. Hệ thống chọn câu hỏi ngắn từ bộ câu đã có đáp án và tiêu chí chấm.
2. **Khi báo thức reo:** Màn hình hiện một câu hỏi giải được trong 60–90 giây. Khi người học bắt đầu, âm lượng giảm để tránh tạo căng thẳng.
3. **Tự làm trên giấy:** Người học chụp ảnh các bước giải. AI nhận diện nội dung ảnh và đối chiếu với tiêu chí chấm, trả về bước đúng, bước cần xem lại và mức độ chắc chắn.
4. **Nếu sai hoặc ảnh mờ:** Hệ thống gợi ý *một bước tiếp theo* hoặc yêu cầu chụp lại; không kết luận người học gian lận. Có thể tạm hoãn hoặc tắt khẩn cấp.
5. **Sau khi hoàn thành:** Báo thức dừng, hiện EXP, chuỗi ngày và một chủ điểm nên ôn lại sau giờ học.

**Ví dụ demo:** “Giải phương trình `2(x − 3) = 10`. Hãy viết ít nhất hai bước biến đổi.” Lời giải mẫu: `2x − 6 = 10` → `2x = 16` → `x = 8`. Nếu người học viết `2x − 3 = 10`, gợi ý Socratic là: “Khi nhân 2 với cả biểu thức trong ngoặc, số 3 đổi thành bao nhiêu?”

## 5. Giá trị khác biệt cần chứng minh

MindClock kết nối **báo thức, nội dung học trong ngày và phản hồi trên bài làm do học sinh tự viết** thành một vòng ngắn. Điểm khác biệt không nằm ở việc “AI tự sinh mọi đề” hay “không thể gian lận”; các tuyên bố đó khó kiểm chứng và không cần cho demo. Đội cần cho thấy AI đọc được ảnh thật, chỉ ra **đúng bước sai** và đưa gợi ý hữu ích, đồng thời người dùng vẫn có quyền tắt báo thức an toàn.

## 6. Phạm vi sản phẩm

| Mức | Nội dung | Điều kiện hoàn thành |
| --- | --- | --- |
| **Demo tối thiểu** | Chọn lịch học mẫu; báo thức mô phỏng; câu Toán đã duyệt; chụp ảnh; phản hồi đúng/sai/chưa rõ; một gợi ý; EXP | Đi hết luồng trên một thiết bị, không cần thuyết minh để hiểu |
| **Bản thử nghiệm sau cuộc thi** | Báo thức hệ thống Android; nhiều chủ đề; lưu tiến độ 7 ngày; cơ chế người học báo “AI chấm sai” | Có kiểm thử trên thiết bị thật và bộ ảnh chữ viết tay đa dạng |
| **Tầm nhìn** | Linh thú, tổ đội, dashboard giáo viên, phụ huynh, đấu ELO, âm thanh | Chỉ mở sau khi xác thực nhu cầu, quyền riêng tư, độ tin cậy và tác động với người học |

**Không đưa vào demo một buổi sáng:** nhiều môn, tạo đề hoàn toàn tự do, chấm phát âm, đấu 1v1 thời gian thực, dashboard toàn trường. Có thể đặt hình minh họa “sắp tới” trong một trang tầm nhìn, ghi rõ chưa hoạt động.

## 7. Nguyên tắc an toàn và tin cậy

- **Không khóa báo thức vô hạn.** Người học luôn có nút tạm hoãn và tắt khẩn cấp. Sai bài không kéo dài tiếng chuông hay trừ “uy tín”.
- **Không phạt vì lỗi AI hoặc ảnh xấu.** Nếu AI không chắc, cho chụp lại hoặc dùng cách trả lời khác. Điểm thưởng gắn với nỗ lực và hoàn thành, không coi ảnh là bằng chứng chống gian lận.
- **Không cổ vũ thiếu ngủ.** Ứng dụng khuyến khích giờ ngủ phù hợp; học sinh 13–18 tuổi thường được khuyến nghị ngủ 8–10 giờ mỗi 24 giờ. [Khuyến nghị AASM](https://pubmed.ncbi.nlm.nih.gov/27707447/).
- **Bảo vệ học sinh chưa thành niên.** Mặc định không công khai danh tính, ảnh bài làm và bảng xếp hạng; xóa ảnh sau khi chấm nếu không cần lưu. Tính năng phụ huynh/giáo viên cần sự đồng ý và quyền truy cập rõ ràng.
- **Nói đúng khả năng công nghệ.** Gemini có thể nhận ảnh và trả về dữ liệu có cấu trúc, nhưng JSON đúng định dạng không bảo đảm chấm đúng nội dung; phải kiểm tra giá trị đầu ra và xử lý trường hợp không chắc chắn. [Image understanding](https://ai.google.dev/gemini-api/docs/image-understanding), [Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output).

## 8. Chỉ số của thử nghiệm nhỏ

Thử nghiệm tự nguyện với 5–10 học sinh trong 7 ngày, có sự đồng ý phù hợp với lứa tuổi. Ghi: số ngày dậy đúng giờ, tỷ lệ thử thách hoàn thành, thời gian hoàn thành trung vị, số lần AI chấm sai được người học báo, mức độ phiền và một câu tự làm lại vào hôm sau. **Không hứa “chữa ngủ nướng”, “tăng IQ”, “cải thiện nhịp sinh học” hoặc “miễn phí hoàn toàn”** khi chưa có dữ liệu và mô hình chi phí.

## 9. Quyết định cần thống nhất trong đội

1. Người dùng đầu tiên là lớp 9 hay lớp 12? Tài liệu hiện chọn lớp 9.
2. Đội thi được mang sản phẩm/prototype chuẩn bị trước hay chỉ được làm tại sự kiện? Chưa thấy công bố trong trang sự kiện.
3. Pitch dài bao nhiêu phút, demo có Internet không, có yêu cầu dùng công nghệ Google nào không? Cần hỏi ban tổ chức trước khi chốt kịch bản.

