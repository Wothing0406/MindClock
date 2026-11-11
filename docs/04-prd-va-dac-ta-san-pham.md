# PRD — MindClock

> **Nguồn hành vi hiện hành:** nhu cầu người học ở [docs/41](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md); `Báo thức thử thách` không có Hoãn, Dừng khẩn cấp luôn có theo [docs/31](31-bao-thuc-thu-thach.md); môn/lịch theo [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md); bài giải/chấm theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). Không dùng luật MVP cũ ở các tài liệu lưu trữ khi trái các nguồn này.

> **Giai đoạn sau MVP:** Solo online/HP theo [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md); tiền trong game, nhân vật sprite 2D có kỹ năng riêng và 30 bậc RP theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md); nguồn câu ngoài/ba dạng từ 2025 theo [docs/38](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md). Đây là đặc tả/lộ trình, không phải chức năng đã chạy. Không đưa corpus ngoài vào app khi quyền chưa rõ.

**Phiên bản tài liệu:** 1.1 · **Ngày:** 11/11/2026 · **Trạng thái:** đặc tả để coding từng lát cắt; tác động sản phẩm/chấm AI/ranked chưa được kiểm chứng với học sinh.

## 1. Tóm tắt sản phẩm

MindClock là trợ lý báo thức gắn với một thử thách **tự nhớ lại kiến thức** của môn học trong ngày. Người học đặt giờ theo lịch của mình, giải một câu ngắn bằng chữ hoặc giấy, nhận phản hồi có kiểm soát và biết một việc cần ôn tiếp. Vòng cốt lõi: **đặt lịch → chuông reo → tự làm → nhận phản hồi → hoàn thành → ôn lại sau**. Gợi ý chỉ xuất hiện theo luật mode; sản phẩm không khuyến khích dậy sớm hơn nhu cầu học.

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
| D0 — demo DevFest | Lịch mẫu, chuông mô phỏng có nhãn, một câu **đội tự viết** kèm đáp án + cách làm chữ; phản hồi fixture hoặc AI với ảnh giả có nhãn | Giám khảo thấy rõ phần live/mô phỏng, nút Dừng và tình huống `uncertain`; không gọi câu chưa duyệt là đã xuất bản |
| M1 — MVP Android | Khách dùng báo thức local; tài khoản khi đồng bộ; lịch học, báo thức thiết bị, câu duyệt, nhập chữ hoặc chụp, chấm/gợi ý, XP/streak riêng tư, offline fallback | Dùng được liên tục 7 ngày trên thiết bị thật; không buộc camera/tài khoản để chuông hoạt động |
| M2 — pilot | Mở thêm môn **theo từng bộ câu đã duyệt**, thích ứng độ khó có giới hạn, quản lý bộ câu, phản hồi khi AI chấm sai, quản lý đồng ý/xóa dữ liệu | Mỗi môn mở phải có evaluator/fallback an toàn, đạt tiêu chí kiểm thử |
| M3 — mở rộng | Linh thú, nhóm lớp, dashboard giáo viên/phụ huynh, thi đấu, iOS | Có nhu cầu xác nhận và thiết kế quyền truy cập riêng |

## 4. User stories MVP và tiêu chí chấp nhận

| ID | User story | Tiêu chí chấp nhận |
| --- | --- | --- |
| US01 | Là học sinh, tôi chọn giờ dậy và ngày lặp | Tạo/sửa/xóa báo thức; hiển thị lần reo kế tiếp theo múi giờ thiết bị; báo rõ khi thiếu quyền |
| US02 | Tôi chọn môn và mục tiêu ôn thi | Chọn nhiều môn ưu tiên, thời khóa biểu, phương thức trả lời; ngày không có môn dùng câu ôn dự phòng hoặc “chỉ báo thức” |
| US03 | Tôi được báo thức dù mất mạng | Chuông/rung/Dừng khẩn cấp hoạt động cục bộ; Hoãn chỉ ở chế độ thường; không chờ backend; câu đã tải trước hoặc câu dự phòng có sẵn |
| US04 | Tôi có thể bắt đầu thử thách | Khi nhấn “Bắt đầu”, âm thanh giảm; câu hỏi trong ngân hàng có thời gian dự kiến không quá 90 giây |
| US05 | Tôi trả lời theo cách phù hợp | Nhập đáp án + lý do bằng chữ hoặc chụp nháp; xem trước và tự bấm gửi; không bắt buộc camera |
| US06 | Tôi biết mình sai ở đâu | Ở chế độ thử thách lần sai rõ 1–2 chỉ báo chưa đúng; từ lần 3 hoặc sau khi kết thúc mới nêu bước liên quan/gợi ý; ảnh mờ/AI bất đồng là `uncertain`, không dùng từ “gian lận” |
| US07 | Tôi có thể rời chuông an toàn | Chế độ thường có thể Hoãn; chế độ thử thách không có Hoãn nhưng luôn Dừng khẩn cấp; không phạt điểm |
| US08 | Tôi xem tiến độ | Hiện số buổi hoàn thành, XP, chuỗi ngày theo quy tắc; không đưa điểm số giả làm “năng lực tư duy” |
| US09 | Tôi sửa cài đặt quyền riêng tư | Biết ảnh gửi tới dịch vụ AI; xem và xóa dữ liệu học tập của mình; ảnh không lưu mặc định |
| US10 | Tôi báo AI chấm sai | Gửi phản hồi kèm mã phiên và kết quả, không cần công khai ảnh; XP có thể được sửa sau kiểm tra |

## 5. Quy tắc nghiệp vụ

### Báo thức

- Báo thức là **hành vi cục bộ trên thiết bị**. Server lưu cấu hình để đồng bộ, nhưng không điều khiển việc phát chuông.
- Mỗi báo thức có `localTime`, `timeZone`, tập `weekdays` theo ISO 1=Thứ Hai … 7=Chủ nhật, `enabled`, `challengeMode`. `snoozeMinutes=5` chỉ có ý nghĩa ở **chế độ thường**; chế độ thử thách không có Hoãn.
- Khi đổi giờ, ngày lặp, múi giờ, quyền báo thức, khởi động lại máy hoặc cập nhật app, thiết bị phải tính và đặt lại lần reo kế tiếp. Nếu hệ điều hành không cấp quyền báo thức đúng giờ, app giải thích rõ và dùng phương án hệ thống cho phép; **không hứa đúng phút**.
- Chuông khởi động ngay với câu hỏi đã có tại máy. Nếu không có câu, vẫn phát báo thức và hiện lựa chọn “Bắt đầu ôn sau”.
- Từ lúc chuông reo: `Dừng khẩn cấp` luôn tới được và dừng local, kể cả khi app/API lỗi; `Hoãn 5 phút` chỉ ở chế độ thường. Khi bấm `Mở câu hỏi`, có thể giảm âm để đọc; không tắt chuông tự động trước khi hoàn thành hoặc Dừng khẩn cấp ở chế độ thử thách.
- Một lần reo chỉ tạo một `alarm_session`; lặp callback hoặc khởi động lại không tạo thêm XP.

### Chọn câu và học tập

- MVP chọn từ **ngân hàng đã duyệt** theo môn/chủ đề của ngày học, trình độ và lịch sử lỗi. Không để Gemini tự sinh câu chưa duyệt rồi chấm ngay lúc sáng.
- Mục tiêu 60–90 giây, tối đa một câu trong chuông; câu khó hơn dành cho buổi ôn tự chọn.
- Nếu không có môn hôm nay, ưu tiên chủ đề đã sai gần đây; không có dữ liệu thì dùng câu dự phòng mức dễ.
- Trong chế độ thử thách không có gợi ý trước bài làm; sau hai lần sai rõ vẫn chưa có gợi ý, lần sai rõ thứ ba mới có gợi ý phương pháp. Sau khi kết thúc có thể xem lời giải đầy đủ.
- Ba phiên chấm hợp lệ đầu ở mức dễ; độ khó tăng từng bậc theo bằng chứng cùng môn/chủ đề và trần người dùng chọn theo docs/39. Không tăng vì ngày trôi hoặc rank.

### Chấm và tiến độ

- Kết quả chấm là `correct`, `incorrect`, `uncertain`. Chỉ `correct` đủ tin cậy mới cấp **XP đúng bài**; `uncertain` đưa đường chụp lại, nhập chữ hoặc hoàn thành không chấm. `+2 XP` ghi nhận nỗ lực chưa chấm chỉ khi backend đã nhận attempt hợp lệ theo quy tắc dưới; không gọi đó là kết quả đúng.
- `incorrect` trong chế độ thử thách cho thử lại, gợi ý theo docs/31; không trừ XP. Sau nhiều lần sai có câu tương đương dễ hơn hoặc Dừng khẩn cấp, không kẹt vòng lặp.
- XP thử nghiệm: đúng lần đầu `+10`, đúng sau gợi ý `+6`; **hoàn thành không chấm online có attempt server xác minh** `+2`; Dừng khẩn cấp/Hoãn `0`. Offline chưa xác minh thì hiển thị `Chưa đồng bộ`, không tự ghi XP có thẩm quyền; nếu người học không chọn gửi bài sau, không có điểm từ bài đó. Không trừ điểm vì sai/nghỉ.
- Chỉ một lần cấp XP cho mỗi phiên, theo `xp_ledger` idempotent. **Streak** tăng khi ngày địa phương có ít nhất một phiên hoàn thành thử thách; hoãn và tắt khẩn cấp không tăng/giảm streak tức thời; ngày không hoàn thành làm streak kết thúc. Có thể cho “ngày nghỉ” tối đa 1 ngày/tuần ở giai đoạn M2.
- **Hạng học tập** là mốc trang trí từ XP, không làm thay đổi quyền học. **Bậc đấu trường** là RP riêng theo môn/mùa, chỉ sau opt-in và cổng ranked ở docs/37; không gọi hai chỉ số chung là `rank`. Mốc XP đề xuất: Học viên 0, Đồng 100, Bạc 300, Vàng 700, Bạch Kim 1500, Kim Cương 3000; cần thử xem người học có hiểu khác RP không.

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
| Tạo áp lực khi mới thức dậy | Câu rất ngắn, có thể giảm âm khi đọc, Dừng khẩn cấp mọi mode; Hoãn chỉ chế độ thường; hỏi cảm giác người học trong pilot |
| AI đọc/chấm sai | Ngân hàng câu duyệt trước, đối chiếu đáp án, trạng thái `uncertain`, nút báo lỗi |
| Học sinh chụp bài người khác | Không hứa chống gian lận; thiết kế ưu tiên động lực tự học |
| Mất mạng/quyền báo thức | Chuông và câu dự phòng local; hướng dẫn cấp quyền, kiểm thử thiết bị |
| Lộ dữ liệu trẻ em | Thu thập tối thiểu, riêng tư mặc định, kiểm soát truy cập, xóa dữ liệu |
| Cơ chế rank tạo áp lực | Không trừ điểm vì sai, không công khai leaderboard trong MVP |

## 9. Cần xác nhận với người dùng trước M2/M3

Tính phù hợp của câu hỏi ngay sau khi thức dậy; thời lượng chấp nhận được; học sinh có muốn chụp giấy không; giáo viên thực sự cần số liệu gì; phụ huynh được xem mức nào; linh thú giúp duy trì học tập hay làm phân tâm; cơ chế đấu có gây áp lực/thiếu công bằng không.

