# MindClock — nghiên cứu nhanh và kiểm chứng trước cuộc thi

> Cập nhật: 10/11/2026. Tài liệu này phân biệt nguồn công khai, giả thuyết của đội và dữ liệu cần tự thu thập.

## 1. Điều đã kiểm tra từ nguồn công khai

- [GDG DevFest MienTrung 2026 — Hackathon](https://gdg.community.dev/events/details/google-gdg-mientrung-presents-hackathon_gdg-devfest-mientrung-2026/): trang sự kiện ghi **14/11/2026, 06:00–13:00 giờ Việt Nam** và địa điểm Grand Tourane Hotel, Đà Nẵng. Không thấy nêu chi tiết tiêu chí chấm, thời lượng pitch hoặc quy định dùng sản phẩm làm trước.
- [GDG DevFest MienTrung 2026 — sự kiện chung](https://gdg.community.dev/events/details/google-gdg-mientrung-presents-gdg-devfest-mientrung-2026-learn-beyond-limits/): trang riêng ghi **14/11/2026, 13:00–17:00 giờ Việt Nam** và nêu Hackathon, Codelab, Demo Day. Không suy ra rằng tất cả đội đều pitch lúc 13:00.
- [Gemini Image understanding](https://ai.google.dev/gemini-api/docs/image-understanding): Gemini nhận được ảnh làm đầu vào. Khả năng đọc đúng chữ viết tay và lập luận Toán trong điều kiện chụp thật phải do đội tự kiểm thử.
- [Gemini Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output): có thể buộc kết quả theo cấu trúc; tài liệu Google yêu cầu kiểm tra cả **giá trị** đầu ra vì đúng định dạng không đồng nghĩa đúng nội dung.
- [Android exact alarms](https://developer.android.com/develop/background-work/services/alarms): báo thức đúng giờ trên Android chịu các yêu cầu và quyền của hệ điều hành. Vì vậy bản demo có thể mô phỏng chuông, nhưng không gọi đó là đã có báo thức hệ thống khi chưa thử trên thiết bị thật.
- [Tổng quan retrieval practice](https://pubmed.ncbi.nlm.nih.gov/41803160/): thực hành truy hồi kiến thức có cơ sở nghiên cứu về học tập; tác động của MindClock cần được đo riêng.
- [Khuyến nghị thời lượng ngủ cho thanh thiếu niên](https://pubmed.ncbi.nlm.nih.gov/27707447/): lứa tuổi 13–18 được khuyến nghị 8–10 giờ ngủ mỗi 24 giờ. Thiết kế không được khuyến khích rút ngắn giấc ngủ để lấy điểm streak.

## 2. Phỏng vấn nhanh 3–5 người

Chọn ít nhất 2 học sinh thuộc nhóm mục tiêu và 1 giáo viên; nếu phỏng vấn người chưa thành niên, xin sự đồng ý phù hợp và không ghi dữ liệu nhận diện vào tài liệu công khai. Mỗi cuộc 8–10 phút.

1. Trong 7 ngày gần đây, em/ bạn đã tắt báo thức rồi ngủ tiếp bao nhiêu lần? Lần gần nhất diễn ra thế nào?
2. Buổi sáng trước tiết học đầu, em có tự ôn gì không? Nếu có, em chọn nội dung ra sao?
3. Khi gặp bài khó, em thường làm gì trước khi xem lời giải AI?
4. Nếu báo thức hỏi một câu 60 giây, điều gì khiến em muốn thử? Điều gì khiến em khó chịu hoặc bỏ dùng?
5. Em có sẵn sàng chụp bài viết tay không? Ảnh đó nên được lưu bao lâu, ai được xem?
6. Cho xem storyboard, yêu cầu người được hỏi kể lại họ nghĩ ứng dụng sẽ làm gì và chỉ ra điểm khó hiểu.

**Cách ghi:** vấn đề thực tế họ kể, tần suất tự báo, nguyên văn một câu ngắn nếu được phép, và điều khiến đội đổi thiết kế. Không biến 3–5 cuộc nói chuyện thành “khảo sát đại diện”.

## 3. Kiểm thử AI trên ảnh thật

Chuẩn bị tối thiểu **10 ảnh** cho đúng một câu Toán demo: 3 bài đúng khác cách trình bày, 3 bài sai với lỗi khác nhau, 2 ảnh mờ/thiếu sáng, 2 ảnh có chữ xấu hoặc gạch sửa. Dùng bài của thành viên đội hoặc tình nguyện viên có đồng ý.

Mỗi ảnh, chấm tay trước theo tiêu chí:

- Có đọc được đề và các bước không?
- Kết quả cuối đúng hay sai?
- Bước đầu tiên sai nằm ở đâu?
- Phản hồi của AI có viện dẫn đúng phần trong ảnh không?
- Hệ thống có nên trả “chưa chắc chắn” không?

Lập bảng `ảnh | nhãn do người chấm | kết quả AI | lỗi | thời gian phản hồi | xử lý`. Không chỉ chọn ảnh đẹp để báo cáo; ghi cả lỗi. Với một cuộc thi một buổi sáng, chỉ cần đưa **một ví dụ đúng và một ví dụ sai thật** lên sân khấu, kèm thông tin “thử 10 ảnh, đúng X/10” nếu con số đã đo. Không tự điền X.

## 4. Tiêu chí demo đạt

| Tiêu chí | Đạt khi |
| --- | --- |
| Câu hỏi phù hợp | Người xem hiểu vì sao câu Toán xuất hiện từ lịch học |
| Tự nghĩ trước | Hệ thống không đưa đáp án trước khi người học thử |
| Phản hồi có ích | Nêu đúng bước sai và một gợi ý có thể hành động |
| Không chắc thì nói không chắc | Ảnh mờ không bị phán sai/gian lận |
| An toàn | Có hoãn và tắt khẩn cấp dễ thấy |
| Trung thực | Phân biệt luồng trực tiếp, video ghi trước, màn hình minh họa và tính năng tương lai |

## 5. Câu cần tránh trong hồ sơ dự thi

| Tuyên bố dễ bị hỏi vặn | Cách diễn đạt có thể bảo vệ |
| --- | --- |
| “Cách duy nhất tắt chuông là giải đúng.” | “Thử thách khuyến khích người học bắt đầu tự giải; luôn có cách hoãn hoặc tắt khẩn cấp.” |
| “Gemini xác thực chống gian lận.” | “Gemini nhận diện bài viết tay và gợi ý theo các bước; chưa thể xác minh ai là người viết.” |
| “AI tự sinh đề chuẩn chương trình, chấm chính xác.” | “Demo dùng câu đã duyệt và tiêu chí chấm rõ; cần kiểm thử độ tin cậy trên ảnh thật.” |
| “Giúp chữa ngủ nướng và tăng điểm số.” | “Đội sẽ đo hành vi dậy đúng giờ và mức độ nhớ bài trong thử nghiệm nhỏ.” |
| “Miễn phí cho mọi học sinh.” | “Mục tiêu là tiếp cận rộng; chi phí vận hành và mô hình tài trợ cần được kiểm chứng.” |
| “Linh thú, ELO, dashboard đã hoàn thiện.” | “Đây là các hướng mở rộng sau khi vòng học tập cốt lõi được xác thực.” |

