# Phân tích tính khả dụng và khả thi của MindClock

**Kết luận làm việc:** ý tưởng có một lõi đáng thử: biến khoảnh khắc dậy thành một lần tự nhớ lại bài học theo lịch. Sản phẩm chỉ nên mở rộng RPG/xã hội sau khi chứng minh người học chấp nhận thử thách sáng sớm, báo thức hoạt động tin cậy và AI phản hồi đủ tốt. Đây là đánh giá dựa trên nguồn công khai và giả thuyết, **không phải kết quả thị trường của MindClock**.

## 1. Bài toán có thật đến mức nào?

Tự nhớ lại kiến thức có cơ sở nghiên cứu tốt hơn chỉ xem lại thụ động trong nhiều bối cảnh, nhưng chuyển nó sang 60–90 giây ngay khi vừa thức dậy là giả thuyết mới cần đo. [Tổng quan retrieval practice](https://pubmed.ncbi.nlm.nih.gov/41803160/). Đối với tuổi 13–18, thời lượng ngủ khuyến nghị là 8–10 giờ/24 giờ; sản phẩm không thể quảng bá “dậy càng sớm càng tốt”. [Khuyến nghị AASM](https://pubmed.ncbi.nlm.nih.gov/27707447/).

### Phân tách ba nhu cầu

| Nhu cầu | Bằng chứng cần có từ người dùng | Rủi ro nếu đo sai |
| --- | --- | --- |
| Dậy đúng giờ | Số lần ngủ tiếp, thời điểm phải đi học, cách báo thức hiện nay thất bại | Làm app báo thức nặng nề nhưng không được dùng lâu |
| Tự học thay vì chép AI | Học sinh thực sự muốn thử trước khi xem đáp án; bài ngắn phù hợp | Quiz bị bỏ qua hoặc chụp hộ để lấy XP |
| Ôn đúng môn trong ngày | Lịch học có ổn định, câu hỏi có liên quan bài sắp học | “Cá nhân hóa” chỉ là gắn nhãn môn, ít giá trị |

Không gộp ba vấn đề thành một câu chuyện “AI giải quyết tất cả”. Mỗi vấn đề có chỉ số và phỏng vấn riêng.

## 2. So sánh với sản phẩm đã có

[Alarmy](https://alar.my/en/blog/alarmy-wake-up-mission) đã có nhiệm vụ Toán và chụp ảnh để tắt chuông; [Quizlet](https://quizlet.com/features/how-quizlet-works) dùng luyện tập truy hồi kiến thức. Vì vậy **“báo thức giải toán” và “AI tạo quiz” không phải điểm mới độc quyền**. MindClock phải chứng minh phần ghép: *môn trong lịch hôm nay + lời giải viết tay có phản hồi theo bước + một vòng ôn ngắn an toàn*. Điểm khác biệt này là giả thuyết cạnh tranh, cần hỏi người dùng liệu nó đáng chuyển ứng dụng hay không.

## 3. Khả thi kỹ thuật

| Thành phần | Đánh giá | Cần chứng minh |
| --- | --- | --- |
| Android alarm local | Khả thi, nhưng quyền OS, màn khóa, chế độ pin và OEM là rủi ro cao | Không lỡ chuông trên ma trận thiết bị hỗ trợ; có fallback khi thiếu quyền. [Android alarm docs](https://developer.android.com/develop/background-work/services/alarms) |
| iOS alarm | Có hướng với AlarmKit trên iOS 26+, cần phân nhánh cho bản cũ | Thiết bị thật, UX quyền, chính sách cửa hàng. [Apple AlarmKit](https://developer.apple.com/documentation/AlarmKit) |
| Gemini đọc ảnh bài viết tay | API nhận ảnh; độ đúng của chữ viết và logic toán phải tự đánh giá | Tập ảnh 50+, lỗi false-correct, ảnh mờ, thời gian. [Image understanding](https://ai.google.dev/gemini-api/docs/image-understanding) |
| Gemini output có cấu trúc | Dùng được để tạo schema nhất quán; vẫn cần validate ngữ nghĩa | Không cấp XP khi JSON đúng nhưng nội dung sai. [Structured output](https://ai.google.dev/gemini-api/docs/structured-output) |
| Firestore + FastAPI | Phù hợp MVP cá nhân, nhưng cần thiết kế query, idempotency và rules | Quyền A/B, transaction điểm, chi phí đọc/ghi |
| Offline | Chuông local khả thi; chấm ảnh không hoạt động offline | Chế độ hoàn thành không chấm và đồng bộ sau không gây trùng |

## 4. Khả dụng với học sinh

**Điểm mạnh tiềm năng:** một việc rõ ràng khi dậy; liên quan tiết học; phản hồi ngay ở bước làm sai; tiến độ cá nhân. **Điểm cản:** chụp giấy lúc sáng bất tiện, ánh sáng yếu, camera chậm, mạng chậm, sai do chữ xấu, áp lực bị “chấm” trước khi đi học. Do đó có phương án nhập đáp án, hoãn/tắt, giảm âm khi bắt đầu và câu ngắn. Kiểm thử trực tiếp với học sinh có giá trị hơn đánh giá của đội chỉ trên màn hình đẹp.

## 5. Khả thi vận hành/chi phí

Mỗi lượt chấm ảnh tốn API, mạng, lưu lượng và thời gian. Nếu 1.000 người dùng × 1 ảnh/ngày, đó là khoảng 30.000 lượt chấm/tháng trước khi tính chụp lại; cần đo token/ảnh và giá theo model thực tế rồi lập ngân sách. Đây là **kịch bản tính công suất**, không phải dự báo người dùng. Dùng bộ câu có sẵn giảm gọi AI sinh đề. Có rate limit, quota/ngày, feature flag tắt chấm khi lỗi/chi phí vượt ngưỡng. [Giá Gemini API](https://ai.google.dev/gemini-api/docs/pricing) thay đổi theo model/tier nên không chốt chi phí trên một con số tĩnh.

Với dữ liệu người chưa thành niên, lựa chọn tier/điều khoản xử lý ảnh là quyết định trọng yếu. Trang giá Gemini hiện mô tả free tier có thể dùng nội dung để cải thiện sản phẩm, paid tier không dùng như vậy theo bảng công bố; cần xác nhận điều khoản áp dụng trước pilot và không lấy free tier làm mặc định cho ảnh học sinh. [Nguồn Google](https://ai.google.dev/gemini-api/docs/pricing).

## 6. Ma trận rủi ro ưu tiên

| Rủi ro | Tác động | Khả năng | Giảm rủi ro | Chủ sở hữu |
| --- | --- | --- | --- | --- |
| Chuông không reo | Rất cao | Trung bình–cao | Native alarm, test máy thật/OEM, fallback, công bố giới hạn | Mobile |
| AI chấm sai mà bảo đúng | Cao | Trung bình | Validator, `uncertain`, bộ ảnh đánh giá, báo lỗi | AI/backend |
| Buổi sáng gây khó chịu | Cao | Chưa biết | Phỏng vấn, thử 7 ngày, câu ngắn, tắt an toàn | Product |
| Dữ liệu ảnh trẻ em không phù hợp chính sách | Rất cao | Trung bình | Paid tier/điều khoản, consent, không lưu mặc định, review trước pilot | Product/backend |
| Chi phí API tăng | Trung bình | Trung bình | Quota, cache, đo token, feature flag | Backend |
| Gamification gây áp lực | Trung bình–cao | Trung bình | XP chỉ thưởng, không shame, opt-out, đo mức khó chịu | Product |
| Nội dung câu hỏi sai/lệch chương trình | Cao | Trung bình | Người duyệt, revision, retire, nguồn bản quyền | Content |

## 7. Các thí nghiệm quyết định “đi tiếp hay đổi hướng”

| Giả thuyết | Thử nhanh | Tín hiệu đi tiếp | Nếu không đạt |
| --- | --- | --- | --- |
| Học sinh chấp nhận câu 60–90 giây khi dậy | 5–10 người thử 7 ngày | Phần lớn người tham gia muốn tiếp tục, mức khó chịu không cao | Cho thử thách sau khi tắt chuông hoặc chuyển thành nhắc ôn |
| Ảnh viết tay tạo giá trị hơn nhập đáp án | Cho thử cả hai cách | Người học thấy phản hồi theo bước hữu ích, thời gian chụp chấp nhận được | Dùng nhập đáp án làm mặc định, ảnh là tùy chọn |
| AI đủ tin cậy trên chủ đề hẹp | 50 bài có nhãn giáo viên | Đạt cổng AI trong test plan | Giới hạn dạng bài hoặc chỉ dùng AI gợi ý, không tự cấp XP |
| Lịch học làm câu hỏi phù hợp | So với câu ôn ngẫu nhiên trong pilot nhỏ | Phản hồi phù hợp cao hơn, hoàn thành không giảm | Chuyển sang chủ đề do người học tự chọn |
| Báo thức đủ tin cậy | Ma trận thiết bị/điều kiện | Không lỡ chuông trên thiết bị hỗ trợ | Không phát hành dưới nhãn “báo thức”; chỉ làm app ôn sáng |

Ngưỡng “phần lớn” ở bảng là tiêu chí khám phá ban đầu; trước pilot cần chốt con số và mẫu phù hợp. Pilot nhỏ không chứng minh quan hệ nhân quả hay hiệu quả học tập dài hạn.

## 8. Phán đoán phạm vi

**Nên xây:** alarm local an toàn, câu ngắn đã duyệt, phản hồi có căn cứ, tiến độ cá nhân. **Chưa nên xây:** chấm tự do tất cả môn, phạt uy tín, ELO, dashboard theo dõi cá nhân, linh thú “suy dinh dưỡng”. Những ý tưởng này chỉ có giá trị khi lõi đã được dùng lặp lại và dữ liệu/chính sách đủ tin cậy.

