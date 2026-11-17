# MultiCal, ghép bạn học và pet nhóm

**Trạng thái:** thiết kế P2 sau phòng một mình/AI và phòng mời 2 người; chưa có tính năng online production. `MultiCal` ở đây là lớp **tìm giờ rảnh chung** trong MindClock, không phải đọc toàn bộ lịch Google của bạn bè. Android Flutter là client đầu tiên; không thêm web client chỉ để làm phòng học. [PRD](01-prd.md), [phòng hiện hành](08-phong-hoc-ai-va-ban-be.md), [lịch cá nhân](05-lich-hoc-nhac-viec.md), [quyền riêng tư](04-tai-khoan-quyen-rieng-tu.md).

## 1. Một nơi, bốn cách học

Màn `Không gian học` giữ hai lựa chọn dễ thấy: `Học một mình` và `Học cùng MindClock`. Sau khi tính năng xã hội đạt cổng, thêm mục `Học với bạn` riêng, gồm `Mời 1 bạn`, `Nhóm của tôi` và sau cùng `Tìm phòng`. `Học cùng MindClock` là **1 người + AI**, không giả là một người bạn thật; `Mời 1 bạn` là **2 người thật**, AI không tự vào. `Nhóm của tôi` là phòng 2–4 người đã đồng ý; không biến thành đấu PvP. Nhãn loại phòng luôn hiện trong thẻ và trong phòng.

| Cách học | Người tham gia | Việc chung | Âm/camera mặc định | AI |
| --- | --- | --- | --- | --- |
| Một mình | 1 | Mục tiêu cá nhân | Tắt | Không khởi tạo |
| Cùng MindClock | 1 + AI gắn nhãn | Mục tiêu cá nhân, hỏi gợi mở | Tắt; `Học sâu` chỉ chữ | Chỉ khi người học hỏi |
| Với 1 bạn | 2 người thật | Có thể cùng môn/chuyên đề hoặc chỉ cùng khung tập trung | Tắt | Không tự tham gia |
| Nhóm | 2–4 người thật | Agenda và giờ chung; mục tiêu riêng vẫn riêng | Tắt | Chỉ bật bằng đồng ý của mọi người trong phòng; P2 sau |

Trong `Học sâu`, phòng người thật cũng im lặng trong chặng tập trung: không tự phát mic/AI/SFX/pet, có thể trao đổi bằng chữ sau khi chủ động mở; trao đổi giọng nói ở giờ nghỉ hoặc nhịp `Thảo luận`. Không ép mọi người bật mic/cam để được tính phiên. Báo thức Android đã đặt vẫn là luồng riêng. Phòng nhóm không khóa app hoặc chấm mức tập trung từ camera.

## 2. MultiCal: tìm giờ chung mà không lộ lịch riêng

Người tạo nhóm chọn khoảng đề xuất (ví dụ `tối thứ 3–5`), thời lượng 15/25/45 phút hoặc tùy chỉnh, môn/chuyên đề nếu cần và hạn trả lời. Mỗi người chủ động chọn các khung **có thể học** hoặc cho phép MindClock chỉ xuất `rảnh/bận` từ lịch đã xác nhận và quiet hours; mặc định không chia sẻ TKB, tên môn, việc riêng, giờ ngủ hay giờ báo. Chủ nhóm chỉ thấy số người rảnh từng khung, không thấy ai bận vì lý do gì. Đổi lịch hoặc timezone tính lại gợi ý và hỏi xác nhận; không tự sửa chuông cá nhân.

Engine lọc khung nằm trong giờ được từng người cho phép, không trùng giờ ngủ/quiet hours đã chọn, đủ thời lượng và độ lệch timezone hợp lệ. Xếp tối đa ba khung theo: đủ người rảnh → gần thời điểm mong muốn của nhóm → ít phải chờ. Có giải thích `3/4 người rảnh lúc 19:30`. **Không đặt lịch thay ai:** mỗi người xác nhận một khung; chỉ khi đủ người đã chọn cho phiên 4 người mới hiện `Đã hẹn 4 người`. Nếu thiếu, người tạo có thể đổi giờ hoặc tạo phiên nhỏ hơn với người đã xác nhận, và UI ghi đúng số người. Lịch chung là lời hẹn, không tự tạo alarm OS; nhắc lịch chỉ opt-in và ẩn nội dung màn khóa mặc định.

Giai đoạn đầu chỉ dùng khung rảnh nhập trong app. Đồng bộ Google Calendar nếu có sau này là opt-in riêng với quyền tối thiểu, chỉ lấy free/busy và xử lý hủy kết nối; không phụ thuộc tích hợp ngoài để dùng MultiCal. Google Calendar có API free/busy và scope giới hạn, nhưng đó là **khả năng kỹ thuật**, không phải tích hợp đã có. [Tài liệu Google FreeBusy](https://developers.google.com/workspace/calendar/api/v3/reference/freebusy/query), [phạm vi quyền](https://developers.google.com/workspace/calendar/api/auth).

## 3. Tìm bạn/phòng phù hợp

**Lộ trình mở:** (a) mời qua bạn bè hai chiều; (b) phòng nhóm chỉ mời; (c) thử nghiệm tìm phòng với nhóm người dùng đã đủ điều kiện và moderation. Không mở danh sách phòng công khai cho học sinh chưa thành niên ngay khi có backend. Màn tìm phòng chỉ hiển thị khi account đã xác minh, consent xã hội hợp lệ, có block/report, quy tắc tên/avatar và vận hành kiểm duyệt; không có chế độ khách ẩn danh vào phòng người lạ.

Người học chọn `Cùng môn` hoặc `Cùng tập trung`. `Cùng môn` lọc cứng cùng lớp/chương trình phiên bản, môn/chuyên đề tương thích và giờ trùng; `Cùng tập trung` không cần cùng môn, chỉ cùng giờ/nhịp/thời lượng. Cả hai lọc cứng tình trạng block, tuổi/consent, sức chứa, quyền phòng và chế độ mic/cam. Xếp hạng mềm theo khung rảnh, mục tiêu phiên, độ dài, nhịp `Học sâu`/`Ngắt quãng` và ngôn ngữ. Không xếp theo rank PvP, học lực suy đoán, trường cụ thể, giới tính, vị trí hoặc số giờ dậy. Khi không có kết quả, cho tạo phòng chỉ mời, lưu lịch hẹn hoặc học một mình/AI; không hiện người giả hay phòng ảo như đang online.

Thẻ phòng trước khi xin vào chỉ có môn/chủ đề công khai do chủ phòng chọn, khối/chương trình nếu `Cùng môn`, nhịp, thời lượng còn lại, số chỗ, `Im lặng`/`Thảo luận` và quy tắc. Không hiện danh tính thành viên trước khi được chấp nhận; không hiện lịch hoặc mục tiêu riêng. Chủ phòng duyệt yêu cầu, có thể từ chối; lời mời/mã có TTL và giới hạn dùng. Không chat tự do ngoài phiên ở bản đầu. Người học rời, chặn, báo cáo được ở mọi thời điểm; mất kết nối không bị mô tả là “bỏ nhóm”.

## 4. Luồng một buổi nhóm

`Lời hẹn/Thẻ phòng → xem mục tiêu chung, người tham gia và quy tắc → xin vào/duyệt → phòng chờ → từng người xác nhận sẵn sàng → bắt đầu → chặng học → nghỉ/tổng kết → kết thúc`.

Phòng chờ có `Bắt đầu khi đủ người` và `Bắt đầu với người có mặt`; không tự mở cam/mic. Nếu ai tới muộn, họ vào chặng hiện tại và timer cá nhân chỉ tính từ lúc họ thực sự bắt đầu. Mất mạng: timer local của từng người tiếp tục, UI cho `Đang kết nối lại`; server dùng bản chụp room version để phục hồi, không cộng EXP hai lần. Chủ phòng đóng phòng không xóa thời gian hợp lệ đã học của người khác. Chỉ chia sẻ tiến độ **tự chọn** (`Đã xong`/`Còn làm`), không hiển thị bài giải, camera, thời khóa biểu hay EXP cá nhân theo thời gian thực. Tổng kết chung chỉ hiện số người hoàn thành và việc chung đã tự xác nhận; mỗi người nhận recap riêng.

**AI trong nhóm:** chỉ sau khi mọi người đồng ý, AI có thể nhận câu hỏi được gắn `Hỏi MindClock`; AI trả gợi ý một bước cho cả phòng và gắn nhãn rõ. Không nghe lén hội thoại, phân loại “lạc đề”, tự chen lời khi phòng im lặng hoặc đưa đáp án trọn bài. Nếu một người rút consent, AI nhóm dừng ngay; timer/phòng bạn vẫn chạy. 1–1 với AI có thể có đối thoại giọng nói ở nhịp `Thảo luận` sau khi opt-in; `Học sâu` vẫn im lặng và AI chỉ trả chữ khi hỏi.

## 5. Pet nhóm: phần thưởng chung không giữ chân bằng phạt

Pet là nhân vật 2D gốc, **trang trí và tiến hóa hình ảnh** của nhóm; tách khỏi avatar hồ sơ và tướng PvP. Nhóm chọn một trong các pet mặc định; tên pet qua kiểm duyệt như tên nhóm. Pet có ba trạng thái UI `nghỉ`, `vui`, `lên cấp` theo mốc đóng góp đã xác nhận. Không dùng trạng thái `ốm/chết` do một người vắng học, không trừ cấp, EXP hay streak cá nhân vì bạn khác bỏ buổi. Không bảng xếp hạng giờ dậy giữa các nhóm.

Mỗi thành viên hoàn thành phiên hợp lệ nhận EXP cá nhân theo `study-time-v0.1`; nhóm nhận **điểm chăm sóc pet** từ một sự kiện riêng, tối đa một lần/người/ngày và có trần đóng góp ngày để tránh bật timer vô hạn. Điểm nhóm chỉ cấp sau server xác nhận, không nhân EXP cá nhân, không mua sức mạnh PvP. Mất mạng hiện `Đang chờ đồng bộ`; retry không cấp lại. Có thể thêm vật phẩm trang trí từ nhiệm vụ nhóm tự nguyện sau pilot, không bán lợi thế học hay chiến đấu. Thành viên rời nhóm không xóa điểm đã góp; xóa tài khoản xử lý theo chính sách dữ liệu và quy tắc ledger/audit. Mọi người có thể tắt animation pet trong phòng; `Học sâu` không phát hiệu ứng pet.

## 6. UI dọc và lời chữ

Tab `Không gian học`: hai nút chính, mục `Học với bạn` khi được mở, lời hẹn kế tiếp. Màn MultiCal là dải ngày/khung giờ, mỗi ô ghi `2/3 rảnh`, nút `Đề xuất giờ`; không có lịch cá nhân của bạn bè. Màn tìm phòng có hai bộ lọc lớn `Cùng môn`/`Cùng tập trung`, tối đa ba bộ lọc phụ, thẻ phòng gọn và nhãn `Chỉ mời`/`Có thể xin vào`. Phòng dọc ưu tiên timer, mục tiêu, trạng thái mic/cam, số người; ô video chỉ chiếm chỗ khi được bật. Pet nằm ở góc nhỏ của phòng chờ/tổng kết, không che bài và không rung trong Học sâu. Chữ gợi ý: `3 người rảnh lúc 19:30`, `Chờ 1 người xác nhận`, `Bạn có thể học một mình ngay`.

## 7. Cổng mở và tiêu chí kiểm chứng

1. **Mời 1 bạn:** hai account test, block/report, room token/membership, reconnect, mic/cam tắt thật và không lộ dữ liệu A/B.
2. **MultiCal nhóm chỉ mời:** bốn tài khoản, đổi timezone/lịch/quiet hours, nhận đủ xác nhận, hủy/sửa lời hẹn, nhắc không trùng; không lộ TKB.
3. **Tìm phòng:** moderation trực và xử lý báo cáo, tuổi/consent đã duyệt, có empty state thật, giới hạn tạo/join, chống lộ phòng qua ID và thử với nhóm nhỏ; chỉ mở feature flag sau cổng.
4. **AI nhóm/pet:** consent từng người, quota và tắt AI ngay khi rút; ledger pet idempotent và cap, không thưởng vì để máy chạy, không phạt người nghỉ; kiểm thử người dùng xem pet có tạo áp lực xấu hay không.

Mọi KPI trong đồ án gửi kèm (ví dụ tỷ lệ 80% trong 21 ngày) là **giả thuyết thử nghiệm**, không phải điều kiện đạt hay số liệu đã đo. Không dùng camera/sensor để suy xao nhãng, metadata ảnh để tuyên bố chống gian lận, khóa app, pet bị bệnh hoặc “cứu chuộc” điểm của người khác. Kiến trúc và ca kiểm ở [ghép phòng](../02-engineering/12-lich-chung-va-ghep-phong.md) và [nghiệm thu](../03-quality/05-ca-nghiem-thu.md).
