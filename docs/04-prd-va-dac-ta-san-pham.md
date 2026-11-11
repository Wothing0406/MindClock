# PRD — MindClock

> **Cập nhật 11/11/2026:** chế độ tự chọn `Báo thức thử thách` theo [docs/31](31-bao-thuc-thu-thach.md) **không có Hoãn**, chỉ gợi ý sau lần sai rõ thứ ba, luôn có Dừng khẩn cấp. Cá nhân hóa nhiều môn/tổ hợp do người dùng chọn theo [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md). Các quy tắc Hoãn/gợi ý sớm/Toán đơn môn bên dưới là mô tả MVP cũ hoặc chế độ thường; nếu mâu thuẫn, dùng docs/31–32 cho chế độ thử thách mới.

**Phiên bản tài liệu:** 1.0 · **Ngày:** 10/11/2026 · **Trạng thái:** sẵn sàng cho triển khai MVP, các giai đoạn sau cần kiểm chứng thêm.

## 1. Tóm tắt sản phẩm

MindClock là trợ lý báo thức gắn với một thử thách **tự nhớ lại kiến thức** của môn học trong ngày. Ứng dụng giúp học sinh thức dậy theo giờ đã chọn, thử giải một câu ngắn trên giấy, nhận phản hồi có kiểm soát và nhìn thấy tiến bộ. Vòng cốt lõi: **đặt lịch → chuông reo → tự làm → nhận gợi ý → hoàn thành → ôn lại sau**.

Slogan: **Đánh thức phản xạ, bứt phá tư duy mỗi sớm mai.**

### Mục tiêu

1. Báo thức chạy tin cậy và có cách tắt an toàn kể cả khi không có mạng.
2. Câu hỏi ngắn, liên quan lịch học, vừa sức và không tạo thêm áp lực khi mới thức dậy.
3. AI nhận diện bài viết tay, phản hồi có dẫn chứng ở bước giải và biết nói “chưa chắc chắn”.
4. Tiến độ học tập phản ánh nỗ lực thực tế, không dùng phạt để ép học.
5. Tôn trọng quyền riêng tư của học sinh, đặc biệt khi người dùng chưa thành niên.

### Ngoài mục tiêu MVP

Thay thế đồng hồ báo thức hệ thống trên mọi điện thoại; chẩn đoán giấc ngủ hoặc năng lực học; bảo đảm chống gian lận; sinh và chấm mọi môn không có người duyệt; theo dõi học sinh cho phụ huynh/giáo viên; đấu ELO; mạng xã hội; quảng cáo nhắm vào trẻ em.

## 2. Người dùng và việc cần làm

| Vai trò | Nhu cầu | Phạm vi |
| --- | --- | --- |
| Học sinh lớp 9 | Dậy đúng giờ và biết một điều cần ôn trước tiết học | MVP |
| Học sinh lớp 12, sinh viên năm đầu | Ôn theo lịch, tăng dần độ khó | Sau pilot |
| Giáo viên | Xem lỗ hổng kiến thức tổng hợp và gợi ý ôn | Giai đoạn 3, khi có đồng ý |
| Phụ huynh | Xem tiến độ ở mức phù hợp | Giai đoạn 3, khi có đồng ý và giới hạn dữ liệu |

**Persona đầu tiên:** Minh, 14 tuổi, học lớp 9, đặt báo thức 06:30, có tiết Toán, thỉnh thoảng bấm ngủ thêm. Đây là persona giả định, cần xác nhận qua phỏng vấn.

## 3. Phạm vi theo đợt

| Mức | Chức năng | Điều kiện chấp nhận tổng quát |
| --- | --- | --- |
| D0 — demo DevFest | Lịch mẫu, chuông mô phỏng, chọn nhiều môn; một câu Toán đã duyệt chạy trọn luồng và một câu cấu trúc môn khác nếu kịp; phản hồi/XP mẫu | Có một luồng thật, nêu rõ phần mô phỏng và môn nào đã được kiểm chứng |
| M1 — MVP Android | Đăng nhập, lịch học, báo thức thiết bị, ngân hàng câu, chụp và chấm, gợi ý, XP/streak, thống kê cá nhân cơ bản, offline fallback | Dùng được liên tục 7 ngày trên thiết bị thật |
| M2 — pilot | Mở thêm môn **theo từng bộ câu đã duyệt**, thích ứng độ khó có giới hạn, quản lý bộ câu, phản hồi khi AI chấm sai, quản lý đồng ý/xóa dữ liệu | Mỗi môn mở phải có evaluator/fallback an toàn, đạt tiêu chí kiểm thử |
| M3 — mở rộng | Linh thú, nhóm lớp, dashboard giáo viên/phụ huynh, thi đấu, iOS | Có nhu cầu xác nhận và thiết kế quyền truy cập riêng |

## 4. User stories MVP và tiêu chí chấp nhận

| ID | User story | Tiêu chí chấp nhận |
| --- | --- | --- |
| US01 | Là học sinh, tôi chọn giờ dậy và ngày lặp | Tạo/sửa/xóa báo thức; hiển thị lần reo kế tiếp theo múi giờ thiết bị; báo rõ khi thiếu quyền |
| US02 | Tôi chọn môn và mục tiêu ôn thi | Chọn nhiều môn ưu tiên, thời khóa biểu, phương thức trả lời; ngày không có môn dùng câu ôn dự phòng hoặc “chỉ báo thức” |
| US03 | Tôi được báo thức dù mất mạng | Chuông, rung, hoãn/tắt hoạt động cục bộ; không chờ backend; câu đã tải trước hoặc câu dự phòng có sẵn |
| US04 | Tôi có thể bắt đầu thử thách | Khi nhấn “Bắt đầu”, âm thanh giảm; câu hỏi trong ngân hàng có thời gian dự kiến không quá 90 giây |
| US05 | Tôi chụp bài viết tay | Xem trước, chụp lại, gửi; không gửi tự động khi chưa nhấn “Gửi bài” |
| US06 | Tôi biết mình sai ở đâu | Phản hồi nêu bước liên quan; sai thì một gợi ý, ảnh mờ thì yêu cầu chụp lại; không dùng từ “gian lận” |
| US07 | Tôi có thể rời chuông an toàn | Chế độ thường có thể Hoãn; chế độ thử thách không có Hoãn nhưng luôn Dừng khẩn cấp; không phạt điểm |
| US08 | Tôi xem tiến độ | Hiện số buổi hoàn thành, XP, chuỗi ngày theo quy tắc; không đưa điểm số giả làm “năng lực tư duy” |
| US09 | Tôi sửa cài đặt quyền riêng tư | Biết ảnh gửi tới dịch vụ AI; xem và xóa dữ liệu học tập của mình; ảnh không lưu mặc định |
| US10 | Tôi báo AI chấm sai | Gửi phản hồi kèm mã phiên và kết quả, không cần công khai ảnh; XP có thể được sửa sau kiểm tra |

## 5. Quy tắc nghiệp vụ

### Báo thức

- Báo thức là **hành vi cục bộ trên thiết bị**. Server lưu cấu hình để đồng bộ, nhưng không điều khiển việc phát chuông.
- Mỗi báo thức có `localTime`, `timeZone`, tập `weekdays` theo ISO 1=Thứ Hai … 7=Chủ nhật, `enabled`, `snoozeMinutes=5` mặc định.
- Khi đổi giờ, ngày lặp, múi giờ, quyền báo thức, khởi động lại máy hoặc cập nhật app, thiết bị phải tính và đặt lại lần reo kế tiếp. Nếu hệ điều hành không cấp quyền báo thức đúng giờ, app giải thích rõ và dùng phương án hệ thống cho phép; **không hứa đúng phút**.
- Chuông khởi động ngay với câu hỏi đã có tại máy. Nếu không có câu, vẫn phát báo thức và hiện lựa chọn “Bắt đầu ôn sau”.
- Từ lúc chuông reo: “Hoãn 5 phút” và “Tắt khẩn cấp” luôn thấy và bấm được. Khi bấm “Bắt đầu”, giảm âm thanh; nếu app bị đóng/mất mạng, người dùng vẫn tắt được.
- Một lần reo chỉ tạo một `alarm_session`; lặp callback hoặc khởi động lại không tạo thêm XP.

### Chọn câu và học tập

- MVP chọn từ **ngân hàng đã duyệt** theo môn/chủ đề của ngày học, trình độ và lịch sử lỗi. Không để Gemini tự sinh câu chưa duyệt rồi chấm ngay lúc sáng.
- Mục tiêu 60–90 giây, tối đa một câu trong chuông; câu khó hơn dành cho buổi ôn tự chọn.
- Nếu không có môn hôm nay, ưu tiên chủ đề đã sai gần đây; không có dữ liệu thì dùng câu dự phòng mức dễ.
- Trước khi người học thử, chỉ cho gợi ý khởi đầu nếu họ yêu cầu; không hiện đáp án. Sau hoàn thành hoặc bỏ qua, người học có thể xem lời giải đầy đủ để học.
- Độ khó thích ứng theo tỷ lệ đúng của ít nhất 5 lần gần nhất cùng chủ đề, thay đổi tối đa một bậc mỗi tuần. Không gắn độ khó trực tiếp với rank.

### Chấm và tiến độ

- Kết quả chấm là `correct`, `incorrect`, `uncertain`. Chỉ `correct` đủ tin cậy mới tự động cấp XP hoàn thành; `uncertain` đưa đường chụp lại, nhập đáp án hoặc hoàn thành không chấm.
- `incorrect` cho một gợi ý và thử lại; không trừ XP. Sau tối đa 2 lần thử, cho phép xem lời giải và kết thúc.
- XP: hoàn thành câu đúng lần đầu `+10`, đúng sau gợi ý `+6`, hoàn thành nhưng không chấm `+2`, tắt/hoãn `0`. Số này là cấu hình ban đầu và cần điều chỉnh qua pilot.
- Chỉ một lần cấp XP cho mỗi phiên, theo `xp_ledger` idempotent. **Streak** tăng khi ngày địa phương có ít nhất một phiên hoàn thành thử thách; hoãn và tắt khẩn cấp không tăng/giảm streak tức thời; ngày không hoàn thành làm streak kết thúc. Có thể cho “ngày nghỉ” tối đa 1 ngày/tuần ở giai đoạn M2.
- Rank là phần hiển thị từ XP, không làm thay đổi quyền được học. Mốc đề xuất: Học viên 0, Đồng 100, Bạc 300, Vàng 700, Bạch Kim 1500, Kim Cương 3000. “Học Bá Thần Thoại” chỉ mở sau khi cân bằng sản phẩm.

## 6. Chỉ số và điều kiện thành công

**North star cho pilot:** số ngày một học sinh tự nguyện hoàn thành một lần ôn ngắn trước giờ học mỗi tuần. Chỉ số phụ: tỷ lệ chuông reo đúng, tỷ lệ bắt đầu/hoàn thành, thời gian chấm, tỷ lệ `uncertain`, tỷ lệ người dùng báo chấm sai, mức khó chịu tự báo, số ngày ngủ đủ theo tự báo nếu có đồng ý. Các chỉ số học tập và giấc ngủ cần được diễn giải riêng; không suy ra quan hệ nhân quả từ một pilot nhỏ.

## 7. Ràng buộc phi chức năng

- Chuông hoạt động offline; hành động hoãn/tắt phản hồi trên thiết bị trong 1 giây ở điều kiện bình thường.
- API chấm đặt timeout 15 giây ở client; quá hạn chuyển trạng thái “chưa thể chấm” và cho hoàn thành an toàn.
- Ảnh gửi tối đa 5 MB, chỉ JPEG/PNG/HEIC nếu pipeline hỗ trợ; nén trên máy, xóa dữ liệu tạm sau xử lý.
- Không ghi ảnh, token, câu trả lời đầy đủ, tên học sinh vào log.
- Giao diện chữ lớn, độ tương phản tốt, có nhãn đọc màn hình và không phụ thuộc màu để báo đúng/sai.
- Ngôn ngữ đầu tiên `vi-VN`; lưu thời điểm chuẩn UTC và múi giờ IANA cho lịch địa phương.

## 8. Rủi ro sản phẩm và cách xử lý

| Rủi ro | Cách xử lý |
| --- | --- |
| Tạo áp lực khi mới thức dậy | Câu rất ngắn, âm thanh giảm khi bắt đầu, hoãn/tắt khẩn cấp |
| AI đọc/chấm sai | Ngân hàng câu duyệt trước, đối chiếu đáp án, trạng thái `uncertain`, nút báo lỗi |
| Học sinh chụp bài người khác | Không hứa chống gian lận; thiết kế ưu tiên động lực tự học |
| Mất mạng/quyền báo thức | Chuông và câu dự phòng local; hướng dẫn cấp quyền, kiểm thử thiết bị |
| Lộ dữ liệu trẻ em | Thu thập tối thiểu, riêng tư mặc định, kiểm soát truy cập, xóa dữ liệu |
| Cơ chế rank tạo áp lực | Không trừ điểm vì sai, không công khai leaderboard trong MVP |

## 9. Cần xác nhận với người dùng trước M2/M3

Tính phù hợp của câu hỏi ngay sau khi thức dậy; thời lượng chấp nhận được; học sinh có muốn chụp giấy không; giáo viên thực sự cần số liệu gì; phụ huynh được xem mức nào; linh thú giúp duy trì học tập hay làm phân tâm; cơ chế đấu có gây áp lực/thiếu công bằng không.

