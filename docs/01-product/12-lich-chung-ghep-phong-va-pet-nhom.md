# Nhóm bạn học, MultiCal và pet chung

Thiết kế pet tiến hóa và thẻ chia sẻ mạng xã hội: [pet nhóm và thẻ chia sẻ](14-pet-nhom-va-the-chia-se.md). T070 đã tạo art pet tĩnh và các stage; ledger nhóm, animation toàn thân và chức năng share vẫn chưa triển khai.

**Trạng thái:** thiết kế P2 sau phòng một mình/AI và phòng mời 2 người; chưa có tính năng online production. `MultiCal` ở đây là lớp **tìm giờ rảnh chung** trong MindClock, không phải đọc toàn bộ lịch Google của bạn bè. Android Flutter là client đầu tiên; không thêm web client chỉ để làm phòng học. [PRD](01-prd.md), [phòng hiện hành](08-phong-hoc-ai-va-ban-be.md), [lịch cá nhân](05-lich-hoc-nhac-viec.md), [quyền riêng tư](04-tai-khoan-quyen-rieng-tu.md).

**Trọng tâm:** người học rủ bạn thân hoặc bạn quen từ mạng xã hội lập một **nhóm cam kết nhỏ**, cùng hẹn học và chăm một pet. Lịch chung chỉ giúp nhóm tìm giờ phù hợp; phòng AI là trợ giúp tự chọn khi không có bạn hoặc khi cần hỏi bài. Pet nhận tiến độ từ ngày hoàn thành thử thách báo thức và nhiệm vụ học, không chỉ từ phút bật timer.

## 0. Tạo nhóm trong chưa đầy một phút

`Tôi → Nhóm của tôi → Tạo nhóm → đặt tên/chọn pet → gửi link hoặc mã mời → bạn chấp nhận`. Link có hạn và không tự thêm người; có thể chia sẻ qua ứng dụng mạng xã hội người dùng chọn, **không đọc danh bạ hoặc đăng bài thay họ**. Người nhận đăng nhập/xác minh và đồng ý tham gia; đủ điều kiện tuổi/consent mới mở tính năng xã hội. Nhóm đầu tối đa 4 người, chỉ thành viên xem được. Có `Rời nhóm`, `Chặn`, `Báo cáo`, đổi trưởng nhóm khi người tạo rời. Mỗi người có thể có bạn bè riêng, nhưng chỉ chọn **một nhóm chăm pet chính cho mỗi ngày**; đổi nhóm có hiệu lực từ ngày kế tiếp để không nhân thưởng.

Link mời nhóm/phòng có thể hiện thành **QR trên màn hình** để bạn ngồi cạnh quét hoặc gửi ảnh QR qua app người dùng chọn; QR và link cùng một token có hạn. Quét QR không tự vào phòng hoặc bật media: người nhận xem trước, đăng nhập và xác nhận. Phòng nhóm có chat giữa thành viên; mời `MindClock AI` là quyết định riêng của cả phòng. Luồng ảnh bài/nhắn AI và avatar có nét mặt cử động xem [phòng học](08-phong-hoc-ai-va-ban-be.md); chế độ một mình vẫn vào được khi không có ai online.

Màn nhóm đầu tiên cho thấy pet, số ngày đã được chăm, nhiệm vụ chung hôm nay, ai **tự chọn hiển thị** trạng thái `Đã hoàn thành`, và nút `Hẹn giờ học`/`Vào phòng`. Không hiện giờ báo thức, giờ thức dậy, bài làm, điểm yếu hay lý do một người vắng. Không gắn nhãn `lười`, `phá chuỗi nhóm` cho ai.

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

## 5. Chuỗi buổi sáng và pet nhóm

Pet là nhân vật 2D gốc, **trang trí và tiến hóa hình ảnh** của nhóm; tách khỏi avatar hồ sơ và tướng PvP. Nhóm chọn một trong các pet mặc định; tên pet qua kiểm duyệt như tên nhóm. Pet có ba trạng thái UI `nghỉ`, `vui`, `lên cấp` theo mốc đóng góp đã xác nhận. Không dùng trạng thái `ốm/chết` do một người vắng học, không trừ cấp, EXP hay streak cá nhân vì bạn khác bỏ buổi. Không bảng xếp hạng giờ dậy giữa các nhóm.

**Ngày chuỗi đúng giờ (mới, tách khỏi chuỗi ôn sáng hiện hành):** trên ngày người học đã tự đặt thử thách, báo thức reo theo lịch local, người học vào lượt trong cửa sổ đúng giờ đã công bố và hoàn thành câu có trình bày, được backend xác nhận `correct` trong cùng buổi sáng. Mốc thử nghiệm để thiết kế/test: mở lượt trong 15 phút từ giờ chuông dự kiến và hoàn thành trong 60 phút; user thấy đồng hồ còn lại, không kéo dài âm chuông. Mốc phải thử trên máy thật và với học sinh trước khi chốt. Đây là **bằng chứng thao tác trong app**, không chứng minh chắc người học đã tỉnh hoặc ngủ đủ. Nếu mở muộn nhưng làm đúng, vẫn nhận EXP/chuỗi ôn sáng theo [quy tắc cũ](09-giac-ngu-va-bao-thuc.md), nhưng không nhận nhãn `Đúng giờ`, ngày chuỗi đúng giờ hay `morning_care`. Ngày nghỉ đã lên lịch và lỗi hệ thống/OS/câu chấm `uncertain` dùng `system_grace`, không tính là người học bỏ cuộc. Lịch ngủ được ưu tiên: app không đề xuất dậy quá sớm để nuôi pet.

**Chăm pet:** mỗi ngày chuỗi đúng giờ đã xác nhận tạo tối đa một `morning_care` cho nhóm chính, cộng một dấu chăm và tiến độ hình ảnh. Nếu người học hoàn thành nhiệm vụ học tự chọn của ngày hoặc phiên học đủ điều kiện, có thể nhận thêm `study_care` theo trần riêng; chỉ bấm vào phòng, mở camera hoặc để timer chạy không chứng minh hiểu bài. Một sự kiện sáng không thể nuôi nhiều nhóm, retry không cấp lại. Pet hiển thị `Đang chờ đồng bộ` khi offline, chỉ lên cấp khi server xác nhận. Không đổi điểm pet thành rank/PvP hoặc EXP cá nhân.

**Chuỗi nhóm:** nhóm chọn những **ngày muốn chăm pet**; mỗi thành viên vẫn tự chọn giờ báo và có thể lên lịch nghỉ riêng, nhóm không ép bật báo thức. Một ngày theo lịch nhóm được tính `Đã chăm` khi **ít nhất một** thành viên có `morning_care` hợp lệ; từ hai người trở lên có thẻ `Cùng nhau` và thưởng mỹ thuật nhỏ, không thêm sức mạnh. Các ngày liên tiếp được chăm tạo chuỗi nhóm hiển thị bên cạnh pet. Ngày chưa ai hoàn thành thì không tăng ngày mới; pet vẫn giữ cấp, trang phục và điểm cũ. Không bắt một bạn làm hộ, chuyển điểm, mua vật phẩm cứu chuỗi hay gửi thông báo nêu tên người “làm đứt” chuỗi. Khi OS/backend gây lỗi cho cả nhóm, ngày được giữ theo `system_grace` nhưng không cộng ngày mới. Thông báo nhóm là opt-in, tối đa một lời mời trung tính theo khung giờ từng người cho phép.

Mỗi thành viên hoàn thành phiên hợp lệ vẫn nhận EXP cá nhân theo `study-time-v0.1`; `study_care` là sổ riêng và có trần, không nhân EXP. Có thể thêm vật phẩm trang trí từ nhiệm vụ nhóm tự nguyện sau pilot. Thành viên rời nhóm không xóa điểm đã góp; xóa tài khoản xử lý theo chính sách dữ liệu và ledger/audit. Mọi người có thể tắt animation pet trong phòng; `Học sâu` không phát hiệu ứng pet.

## 5a. Vai trò AI bên cạnh bạn thật

Bạn thật là nơi trò chuyện và giữ lời hẹn; AI không đóng giả bạn cùng lớp, không nhận vai “người hiểu bạn tuyệt đối”. Ở phòng `Học cùng MindClock`, AI là **trợ giảng gợi mở**: chào ngắn nếu người học đã chọn chế độ có đối thoại, nhận mục tiêu rồi im lặng khi học sâu; chỉ phản biện một bước khi được hỏi. Cuối phiên có thể tóm tắt việc người học tự đánh dấu. Trong nhóm người thật, AI chỉ tham gia theo đồng ý của tất cả thành viên và câu hỏi được gửi có chủ đích. Không tự bình luận chuyện đời tư, không nhớ lịch sử vô hạn; người học xem/xóa dữ liệu dùng để cá nhân hóa. Voice cần opt-in và không được bật vào chặng `Học sâu`. Không hứa AI sẵn sàng 24/7 hoặc chấm đúng mọi môn.

## 6. UI dọc và lời chữ

Tab `Không gian học`: hai nút chính, mục `Học với bạn` khi được mở, lời hẹn kế tiếp. Tab `Nhóm của tôi` cho thấy pet và ngày chăm chung; hành động đầu là `Mời bạn`, không bắt thiết lập lịch trước. Màn MultiCal là dải ngày/khung giờ, mỗi ô ghi `2/3 rảnh`, nút `Đề xuất giờ`; không có lịch cá nhân của bạn bè. Màn tìm phòng có hai bộ lọc lớn `Cùng môn`/`Cùng tập trung`, tối đa ba bộ lọc phụ, thẻ phòng gọn và nhãn `Chỉ mời`/`Có thể xin vào`. Phòng dọc ưu tiên timer, mục tiêu, trạng thái mic/cam, số người; ô video chỉ chiếm chỗ khi được bật. Pet nằm ở góc nhỏ của phòng chờ/tổng kết, không che bài và không rung trong Học sâu. Chữ gợi ý: `Hôm nay pet đã được chăm`, `3 người rảnh lúc 19:30`, `Chờ 1 người xác nhận`, `Bạn có thể học một mình ngay`.

## 7. Cổng mở và tiêu chí kiểm chứng

1. **Mời 1 bạn:** hai account test, block/report, room token/membership, reconnect, mic/cam tắt thật và không lộ dữ liệu A/B.
2. **MultiCal nhóm chỉ mời:** bốn tài khoản, đổi timezone/lịch/quiet hours, nhận đủ xác nhận, hủy/sửa lời hẹn, nhắc không trùng; không lộ TKB.
3. **Tìm phòng:** moderation trực và xử lý báo cáo, tuổi/consent đã duyệt, có empty state thật, giới hạn tạo/join, chống lộ phòng qua ID và thử với nhóm nhỏ; chỉ mở feature flag sau cổng.
4. **AI nhóm/pet:** consent từng người, quota và tắt AI ngay khi rút; ledger pet idempotent và cap, không thưởng vì để máy chạy, không phạt người nghỉ; kiểm thử người dùng xem pet có tạo áp lực xấu hay không.

Mọi KPI trong đồ án gửi kèm (ví dụ tỷ lệ 80% trong 21 ngày) là **giả thuyết thử nghiệm**, không phải điều kiện đạt hay số liệu đã đo. Không dùng camera/sensor để suy xao nhãng, metadata ảnh để tuyên bố chống gian lận, khóa app, pet bị bệnh hoặc “cứu chuộc” điểm của người khác. Kiến trúc và ca kiểm ở [ghép phòng](../02-engineering/12-lich-chung-va-ghep-phong.md) và [nghiệm thu](../03-quality/05-ca-nghiem-thu.md).
