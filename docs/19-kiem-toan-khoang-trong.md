# Kiểm toán khoảng trống tài liệu và quyết định sản phẩm

**Ngày rà soát:** 10/11/2026. **Trạng thái repo:** chỉ có đặc tả; chưa có app/build. Tài liệu này là danh sách kiểm tra để đội không nhầm kế hoạch với tính năng đã chạy.

## 1. Kết luận nhanh

Bộ docs 01–18 đủ để bắt đầu lát cắt Android báo thức + câu hỏi + chấm hỗ trợ. Các phần còn thiếu để biến ý tưởng thành sản phẩm đa nền tảng và cộng đồng được đặc tả tại [iOS](20-ios-demo-va-phat-hanh.md), [đấu trường](21-dau-truong-xep-hang.md), [nhân vật](22-nhan-vat-rpg.md) và [hành trình sử dụng](23-hanh-trinh-san-pham.md). Đây là **đặc tả giai đoạn sau**, chưa tự động mở phạm vi coding MVP.

## 2. Khoảng trống theo mức ưu tiên

| Mức | Khoảng trống trước lần rà soát | Cách xử lý trong docs | Bằng chứng còn cần trước khi code/phát hành |
| --- | --- | --- | --- |
| P0 | Lời hứa “chỉ giải đúng mới tắt chuông” xung đột quyền tắt của OS và an toàn | Chốt chuông luôn có tắt/hoãn; thử thách học là bước tự nguyện sau khi mở app | Test AlarmKit và Android trên máy thật, kể cả màn khóa |
| P0 | Chưa có cách demo iOS trên máy Windows | Ba mức demo, checklist Mac/Xcode/TestFlight và kịch bản sân khấu | Mac, iPhone iOS 26+, Apple ID, build ký thật |
| P0 | Chưa có định nghĩa thắng/thua, điểm, tính hạng và xử lý AI chưa chắc cho thi online | Luật trận, bảng môn/khối/tuần, rating ledger, API, test | Bộ câu đã duyệt và hiệu chuẩn độ khó, thử tải và chống gian lận |
| P0 | Chưa phân biệt XP/streak/rank học tập/ELO | Tách bốn chỉ số và quyền tham gia bảng | User test xem người học hiểu từng chỉ số |
| P1 | Thiết kế linh thú còn khái quát, chưa thể giao việc cho họa sĩ/dev | Character bible, trạng thái, asset spec, accessibility | Ảnh gốc có quyền sử dụng, thử nhận diện ở 48 px |
| P1 | Chưa có flow từ onboarding tới tham gia thi online, rời bảng, đổi nhân vật | Wireflow, nhãn tiếng Việt và trạng thái lỗi | Prototype test với 5–8 người học/phụ huynh phù hợp |
| P1 | Chưa có ranh giới giữa demo giả lập và năng lực thật | Nhãn demo, ba mức iOS, fixture đã kiểm soát | Video/thiết bị dự phòng và log demo không chứa dữ liệu thật |
| P1 | Chưa có chính sách leaderboard cho người chưa thành niên | Biệt danh, opt-in, không lộ giờ dậy/lớp nhỏ, không chat tự do | Rà soát pháp lý và đồng ý trước pilot |
| P2 | Chưa có mô hình đo khả thi kinh tế của trận thời gian thực | Ước lượng theo số trận, đọc/ghi, ảnh, AI và giới hạn | Dữ liệu pilot, báo giá hạ tầng thực tế |

## 3. Những giả thuyết chưa thể gọi là sự thật

1. Học sinh sẽ thấy thử thách buổi sáng hữu ích hơn phiền: cần phỏng vấn và thử 7–14 ngày.
2. Gemini đọc được lời giải viết tay tiếng Việt đủ tin cậy cho điểm thưởng cạnh tranh: cần tập ảnh đa dạng, người chấm chuẩn và ngưỡng `uncertain`.
3. Một bộ câu có thể so sánh công bằng giữa hai người: cần chuyên gia môn học hiệu chuẩn, không chỉ cùng nhãn “khó”.
4. Báo thức AlarmKit có hành vi giống Android trên mọi iPhone: cần thử thiết bị; OS sở hữu nút dừng.
5. Thi đấu/xếp hạng tạo động lực lành mạnh: cần đo cả cảm giác áp lực và tỷ lệ tắt tính năng.

## 4. Quyết định phạm vi để coding

| Giai đoạn | Xây thật | Demo được phép | Chưa đưa vào |
| --- | --- | --- | --- |
| DevFest buổi sáng | Một lát cắt Android hoặc bản tương tác rõ nhãn, một môn Toán, 1 câu đã duyệt, phản hồi AI có `uncertain` | iPhone mở bản prototype/web hoặc build iOS đã chuẩn bị trước; bảng xếp hạng dữ liệu mẫu phải ghi “Mô phỏng” | ELO thật, chat, dashboard phụ huynh, sinh đề tự do |
| Pilot học tập | Báo thức ổn định, câu theo lịch, tiến bộ cá nhân, sửa lỗi chấm | Trận không tính hạng với nhóm thử nhỏ | Bảng công khai rộng |
| Cộng đồng | Trận theo môn/khối, bảng tuần opt-in, nhóm; rating khi đạt cổng chất lượng | Dữ liệu staging riêng | Cạnh tranh dựa giờ thức dậy hoặc phạt sai bằng trừ XP |

## 5. Cổng ra quyết định trước khi mở ELO

- Có tối thiểu một tập câu đủ lớn trong từng môn/khối được người dạy duyệt, cùng bản rubric và độ khó đã kiểm tra.
- Hai người nhận cùng câu hoặc hai câu tương đương đã hiệu chuẩn; thời gian tính ở server; thử mạng yếu.
- Kết quả AI `uncertain` không làm thay đổi rating; có cơ chế khiếu nại và sửa điểm có audit.
- Bảng xếp hạng chỉ người tự bật; biệt danh; không hiển thị giờ báo thức, vị trí, trường/lớp cụ thể nếu dễ nhận diện.
- Có người phụ trách nội dung, hỗ trợ và vận hành. Nếu thiếu một cổng, duy trì trận giao hữu và bảng riêng tư.

## 6. Việc đội cần tự xác nhận

- Quy chế DevFest, phần được làm trước cuộc thi, kết nối mạng, thiết bị được mang vào, hạn nộp và cách chấm.
- Thành viên có Mac/Xcode và iPhone phiên bản phù hợp hay không; nếu không, chọn demo iOS ở mức prototype và nói rõ.
- Đối tượng thí điểm/độ tuổi, cơ chế xin đồng ý, bộ câu có quyền sử dụng.
- Người chịu trách nhiệm duyệt đáp án, xét khiếu nại, vận hành dịch vụ và ngân sách.

