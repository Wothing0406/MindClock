# Không gian học: một mình, cùng AI, cùng bạn

**Mục tiêu sản phẩm:** giúp người học bắt đầu và duy trì một phiên có mục tiêu rõ. Màn vào có hai lựa chọn chính: `Học một mình` và `Học cùng MindClock`. `Mời bạn học` là nhánh riêng sau feature flag, không chen vào lựa chọn đầu. Không giả AI là người thật, không mắng người học hoặc khóa họ trong phòng. [PRD](01-prd.md), [quyền riêng tư](04-tai-khoan-quyen-rieng-tu.md).

## Trước khi vào phòng

Luồng: **chọn chế độ → xem gợi ý phiên cá nhân hóa → xác nhận/sửa mục tiêu và thời lượng → chọn `Học sâu` hoặc `Học ngắt quãng` → tùy chọn âm → xem lại → `Bắt đầu`**. Gợi ý lấy từ kế hoạch đã xác nhận, TKB hôm nay và việc chưa xong, kèm lý do ngắn. Không bắt chọn môn lần nữa; người học có `Đổi mục tiêu` hoặc `Học tự do`, và chỉ đổi môn khi họ chủ động mở phần sửa. Nếu thiếu lịch/kế hoạch hoặc offline, cho nhập mục tiêu tự do mà không chặn phiên. Preset 15/25/45 phút hoặc tùy chỉnh.

`Học sâu` mặc định **im lặng hoàn toàn**: không nhạc nền, tiếng đếm giờ, chuông hết chặng, lời nhắc, tự phát giọng AI hay âm báo trong app. Cả hai chế độ đều theo quy tắc này; AI chỉ hiện chữ khi người học chủ động hỏi. Trong `Học ngắt quãng`, âm báo chuyển chặng và âm nền đều tắt mặc định, người học tự bật từng loại nếu muốn. Báo thức Android do người học đã đặt là luồng riêng và vẫn hoạt động. Mic/camera **tắt mặc định**, bật độc lập đúng lúc dùng; không yêu cầu quyền để dùng timer hoặc hỏi bằng chữ. Chỉ tính thời gian khi bấm `Bắt đầu`.

Thẻ xem lại trước khi bắt đầu ghi chế độ, mục tiêu, thời lượng, nhịp, âm thanh và trạng thái mic/cam; cho sửa từng mục. Khi chọn `Học một mình`, không hiện AI/avatar/nút hỏi trong phiên. Khi chọn `Học cùng MindClock`, AI chỉ phản hồi yêu cầu chủ động; text trước, voice là tùy chọn riêng ở nhịp cho phép. Không tự chuyển từ một mình sang AI.

## Bố cục phòng dọc

Trong `Học một mình`, ưu tiên timer lớn, mục tiêu, ghi nhanh chỗ đang vướng, `Tạm dừng` và `Kết thúc`; không có ô video hay avatar AI. Trong `Học cùng MindClock`, thêm vùng AI gắn nhãn rõ và nút `Xin một gợi ý`; mic/cam chỉ hiện khi tính năng được bật và đã có quyền. Nửa trên không chiếm chỗ của mục tiêu học nếu camera tắt. Trạng thái đang truyền âm/ảnh và nút tắt phải luôn thấy. Không có animation giả AI đang quan sát. Khi mạng yếu, giữ timer và ghi chú local, chuyển về text nếu AI đang bật.

## AI đồng hành và lời nhắc

AI nhận mục tiêu đã xác nhận; không hỏi lại trước khi bắt đầu. Trong phiên, mặc định **không gửi camera liên tục** và không tự phát giọng. Ở `Học sâu`, AI im lặng cho tới khi người dùng bấm hỏi và chỉ trả chữ; không có nhắc theo mốc. Ở `Học ngắt quãng`, người dùng có thể bật nhắc nhẹ theo chặng. Không suy “lười” từ mặt, tư thế, im lặng hay ứng dụng background. Khi quay lại app, hiện lựa chọn tiếp tục bằng chữ; không trừ điểm vì rời.

Nếu người dùng chọn mức nhắc ở `Học ngắt quãng`, lời nhắc ngắn và trung tính. Có thể có đùa nhẹ sau phiên, không trong phiên sâu. Không dùng xúc phạm, đe dọa, gây xấu hổ hay nhân cách “giận dỗi”. Người học luôn có nút tắt AI/âm và kết thúc; nếu họ bày tỏ mệt mỏi, giảm nhắc và gợi nghỉ.

## Tổng kết và EXP thời gian

Kết thúc phiên hiển thị thời gian học được tính, mục tiêu tự đánh dấu đã làm/chưa xong, ghi chú còn vướng, EXP **đã xác nhận** hoặc `Đang chờ đồng bộ`, cùng nút lên lịch tiếp. AI chỉ tóm tắt khi người học đã chọn `Học cùng MindClock` hoặc chủ động hỏi sau phiên; phần tổng kết của `Học một mình` không tự gọi AI.

Quy tắc thử nghiệm `study-time-v0.1`: mỗi **5 phút trọn vẹn** ở trạng thái `running` nhận 1 EXP; tối đa 12 EXP/phiên và 30 EXP/ngày theo ngày local đã chốt với timezone. Thời gian `paused`, nghỉ, trước `Bắt đầu` và sau `Kết thúc` không tính. Phiên dưới 5 phút, hủy trước khi kết thúc hoặc dữ liệu thời gian không chắc: 0 EXP. Một `clientSessionId` chỉ được ghi EXP một lần; server kiểm khoảng thời gian, giới hạn, owner và ghi ledger trong transaction. Offline chỉ hiện `EXP dự kiến`, đồng bộ thành công mới đổi thành đã xác nhận; retry không nhân đôi. Không trừ EXP đã có khi rời app hoặc không đạt mục tiêu. EXP thời gian là thưởng duy trì thói quen, **không chứng nhận đã học hay hiểu bài**, không cộng RP PvP và không dùng để đánh giá giáo viên/phụ huynh. Các mốc số sẽ được chốt lại bằng pilot trước phát hành rộng.

## Hỏi bằng giọng nói và hình ảnh AI

P1 text/voice theo lượt: bấm để nói, STT → câu hỏi gợi mở → TTS, phát xong tự ngừng; tiết kiệm token, hoạt động cả khi camera tắt. P2 Gemini Live full-duplex khi đã đạt cổng ngân sách/quyền: mic opt-in, audio streaming, ngắt lời, reconnect/session renewal, transcript tối thiểu theo policy, token ephemeral từ server. Camera nếu bật chỉ dùng cho cuộc gọi hoặc gửi **khung hình có chủ đích** để hỏi về trang bài; không gửi video liên tục để giám sát. Avatar 2D nói theo audio, có ảnh tĩnh khi reduce motion/máy yếu. Live API có giới hạn phiên và chi phí theo token; mô hình/giá/quota phải xác nhận lúc triển khai. [Google Live API capabilities](https://ai.google.dev/gemini-api/docs/live-api/capabilities), [session management](https://ai.google.dev/gemini-api/docs/live-api/session-management), [pricing](https://ai.google.dev/gemini-api/docs/pricing/).

Trợ lý Socratic nhận môn/lớp/mục tiêu/câu hỏi và lịch sử đủ dùng, trả **một bước gợi mở**, hỏi người học thử tiếp; không giải trọn bài trước nỗ lực. Không thể bảo đảm người học chỉ nói về môn học; AI chuyển nhẹ về mục tiêu, vẫn trả lời yêu cầu nghỉ, trợ giúp an toàn hoặc dừng phiên. Có nút `Báo câu trả lời sai` và đường xem nguồn/rubric khi phù hợp.

## Mời bạn vào học

User tạo phòng `Chỉ mời`, mã/link ngắn hạn, tối đa 2 người ở giai đoạn đầu; bạn chấp nhận mới vào. Không tự bật cam/mic khi join. Mỗi người có timer local đồng bộ mốc phòng, việc riêng có thể ẩn; chủ phòng không xem bài/TKB/điểm riêng. Người tham gia có `Rời`, `Chặn`, `Báo cáo`; chủ phòng có `Kết thúc phòng` nhưng không tắt timer local của người kia. Kết bạn bằng lời mời hai chiều, có danh sách chặn; không mở tìm kiếm công khai/nhắn tin tự do ở giai đoạn đầu. Phòng AI và phòng bạn cùng dùng shell UI nhưng networking khác nhau; khi AI quota hết, phòng bạn/timer vẫn chạy.

Lịch rảnh chung, nhóm 2–4 người, tìm phòng theo môn hoặc chỉ cùng giờ tập trung, AI nhóm và pet là các lát **sau** phòng mời 2 người, có feature flag và cổng riêng. [Thiết kế MultiCal và nhóm](12-lich-chung-ghep-phong-va-pet-nhom.md).

## Acceptance

| ID | Khi | Phải xảy ra |
| --- | --- | --- |
| ROOM-01 | Chọn một mình hoặc cùng AI, xem gợi ý, xác nhận/sửa mục tiêu và recap | Không bắt chọn môn lại; đúng chế độ/nhịp; mic/cam/âm tắt khi vào. |
| ROOM-07 | Chọn Học sâu ở một trong hai chế độ | Không phát âm nền, tiếng chuyển chặng, nhắc hay giọng AI; AI chỉ trả chữ sau thao tác hỏi. |
| ROOM-08 | Hoàn thành phiên, tạm dừng/nghỉ/offline/retry finish | EXP theo phút running trọn vẹn, đúng trần; chưa sync chỉ hiện dự kiến; ledger ghi một lần; phiên ngắn/hủy không thưởng. |
| ROOM-02 | Từ chối mic/camera hoặc tắt giữa phiên | Timer/text tiếp tục; indicator và đường bật quyền đúng. |
| ROOM-03 | AI lỗi/quota/Live rớt mạng | Hạ cấp về text/timer, không mất phiên hoặc phát audio giả. |
| ROOM-04 | Rời app/tạm nghỉ/rời phòng | Không chửi/phạt/giữ app; có nhắc chỉ nếu đã opt-in. |
| ROOM-05 | Mời bạn/đổi account/block | Người lạ không vào, không lộ việc riêng; kick/report có audit. |
| ROOM-06 | Hỏi ngoài chủ đề hoặc yêu cầu lời giải | AI chuyển về mục tiêu bằng lời trung tính, gợi một bước, không lộ đáp án trước nỗ lực. |

Học cùng bạn và Live voice/video là feature flags độc lập; không xuất hiện như phòng hoạt động thật trước khi có backend, moderation, thiết bị thật và ngân sách. [Kỹ thuật realtime](../02-engineering/09-phong-hoc-realtime.md).
