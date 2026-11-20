# Không gian học: một mình, cùng AI, cùng bạn

**Mục tiêu sản phẩm:** giúp người học bắt đầu và duy trì một phiên có mục tiêu rõ. Màn vào có hai lựa chọn chính: `Học một mình` và `Học cùng MindClock`. `Mời bạn học` là nhánh riêng sau feature flag, không chen vào lựa chọn đầu. Không giả AI là người thật, không mắng người học hoặc khóa họ trong phòng. [PRD](01-prd.md), [quyền riêng tư](04-tai-khoan-quyen-rieng-tu.md).

## Trước khi vào phòng

Luồng: **chọn chế độ (`Học một mình` / `Học cùng MindClock` / `Phòng học cộng đồng`) → xem gợi ý phiên cá nhân hóa từ các môn trong Profile & TKB → chọn chế độ thời gian (`Đếm ngược 15/25/45/90/180+ phút` hoặc `Đốt nến · Đếm giờ tự do không giới hạn`) → chọn `Học sâu` hoặc `Học ngắt quãng` → tùy chọn âm → xem lại → `Bắt đầu`**. Danh sách môn trong không gian học **phải lọc đúng theo các môn người học đã chọn trong `StudyProfile`** (chỉ fallback toàn bộ khi hồ sơ chưa có môn). Chế độ `Đốt nến · Đếm giờ tự do` cho phép đồng hồ đếm tiến (`00:00 → ∞`) kèm nến cháy trực quan theo thời gian thực để người dùng học dài hơn 120 phút nếu muốn; vẫn giữ cảnh báo nghỉ ngơi trung tính khi quá dài. Khi thiếu lịch/kế hoạch hoặc offline, cho nhập mục tiêu tự do mà không chặn phiên.

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

## Cộng đồng, Hồ sơ công khai, Kết bạn & Phòng học kiểu Google Meet (Gói B — T058)

User đã xác thực (không dùng guest ẩn danh) có **Hồ sơ học sinh công khai (Public Profile)** hiển thị opt-in cho bạn học xem: `avatarId/avatarUrl`, `alias`, `gradeLevel`, `selectedSubjectCodes`, `goalLabel`, cấp bậc/chuỗi học tóm tắt, trạng thái kết bạn và nút `Kết bạn` / `Hủy lời mời` / `Chặn`. **Tuyệt đối không lộ** giờ dậy, TKB chi tiết, email, điểm yếu hoặc ảnh bài làm. Hệ thống hỗ trợ:
1. **Tìm bạn & Kết bạn hai chiều:** tìm theo biệt danh/tổ hợp môn, gửi/nhận/chấp nhận/từ chối lời mời kết bạn, chặn và báo cáo người dùng vi phạm.
2. **Quét phòng học công khai & Phòng riêng tư:** chủ phòng chọn chế độ `Công khai (Ai cũng có thể tìm & xin vào)` hoặc `Chỉ mời (Mã/link/QR)`. Màn `Quét phòng` hiển thị danh sách phòng công khai đang học (tên phòng, môn/tổ hợp, trình độ mục tiêu, số thành viên hiện tại/tối đa, chủ phòng) để tham gia nhanh.
3. **AI ghép nhóm theo trình độ:** dựa trên `gradeLevel`, `selectedSubjectCodes`, mức tự đánh giá (`beginner/basic/exam_prep/challenge`) và mục tiêu, backend/AI gợi ý phòng công khai hoặc bạn học phù hợp trình độ nhất kèm lý do ngắn (`Cùng khối 11 · Ôn Toán nâng cao`).
4. **Giao diện phòng học nhiều người kiểu Google Meet:** hiển thị **lưới thẻ thành viên trực quan** (mỗi ô là avatar/khung camera của thành viên, nhãn tên, môn đang học, chỉ báo mic bật/tắt, cam bật/tắt; người dùng tự bật/tắt mic & cam của mình, mặc định tắt). Khi **MindClock AI** được mời vào phòng, xuất hiện một ô riêng trong lưới với **avatar 2D cử động liên tục** (chớp mắt, gật đầu, trạng thái suy nghĩ/trả lời) và nhãn `MindClock AI`.

User tạo phòng `Chỉ mời` hoặc `Công khai`, mã/link ngắn hạn; bạn chấp nhận mới vào. Không tự bật cam/mic khi join. Mỗi người có timer local đồng bộ mốc phòng, việc riêng có thể ẩn; chủ phòng không xem bài/TKB/điểm riêng. Người tham gia có `Rời`, `Chặn`, `Báo cáo`; chủ phòng có `Kết thúc phòng` nhưng không tắt timer local của người kia. Phòng AI và phòng bạn cùng dùng shell UI nhưng networking khác nhau; khi AI quota hết, phòng bạn/timer vẫn chạy.

### Vào phòng bằng QR hoặc link

Chủ phòng chọn `Mời bạn` → app tạo **cùng một lời mời** dưới dạng link HTTPS, mã ngắn và QR để quét trực tiếp hoặc chia sẻ qua app khác. QR chỉ chứa link có token mời ngẫu nhiên, không có email, TKB, giờ báo thức, ID tuần tự hay mật khẩu. Trên màn mời có `Sao chép`, `Chia sẻ`, `Hiện QR`, `Thu hồi`; cho đặt hạn và số lượt dùng theo loại phòng. Người nhận mở link/quét QR → đăng nhập nếu cần → xem tên phòng, loại phòng, số người, chủ phòng đã duyệt, quyền mic/cam và quy tắc → bấm `Xin vào` hoặc `Tham gia` nếu đã được mời đích danh. Link không tự bật mic/cam và không tự đưa người lạ vào phòng. Phòng chỉ mời khác với phòng có thể xin vào; chủ phòng có danh sách chờ và nút duyệt/từ chối. Khi đủ chỗ, hết hạn, bị thu hồi, bị chặn hoặc sai điều kiện tuổi/consent, UI báo lý do phù hợp và cho quay lại học một mình.

### Chat, ảnh bài học và gọi AI

Phòng bạn có hai ngữ cảnh rõ: `Trò chuyện nhóm` chỉ thành viên thấy và `Hỏi MindClock` chỉ hoạt động sau khi AI được mọi thành viên đồng ý mời vào. Tin nhắn nhóm **không tự chuyển cho AI**. Người gửi chọn `Gửi cho nhóm` hoặc `Hỏi AI`; nếu hỏi AI về tin nhắn/ảnh trong chat nhóm, phải chọn lại đúng nội dung được chia sẻ và thấy bản xem trước. Bấm `+ Ảnh` chọn ảnh hoặc chụp mới, crop/che thông tin riêng, xem trước rồi xác nhận người nhận; ảnh không tự lưu vào hồ sơ hay gửi vào Gemini chỉ vì đã xuất hiện trong chat. Ảnh bài có thể hỏi **sau phiên** từ recap/ghi chú bằng luồng `Hỏi AI`, không buộc giữ phòng hoặc timer chạy. AI trả gợi ý bằng chữ; giọng nói chỉ khi người học bật `Trả lời bằng giọng nói` và chạm `Nghe` hoặc ở nhịp thảo luận đã đồng ý. Trong `Học sâu`, phản hồi mặc định là chữ, không tự phát tiếng; nút nghe là thao tác chủ động. Có `Tắt giọng` ngay trên câu trả lời, phụ đề luôn có, lỗi voice vẫn đọc được chữ.

Lưu chat nhóm là lựa chọn của phòng với thời hạn công khai trước khi gửi; mặc định P2 đầu chỉ giữ trong phiên, ảnh xử lý tạm và xóa sau phiên/timeout. Nếu mở lịch sử sau này phải có consent/retention/export/delete và thử quyền khi thành viên rời nhóm. AI chỉ nhận nội dung được tag/gửi, không nghe mic nền hoặc đọc toàn bộ chat. Không cho thành viên khác ép AI đọc ảnh hay phát tiếng trên máy của người chưa đồng ý.

### Gương mặt MindClock AI

Trong phòng AI, nhân vật 2D gốc có **mắt, miệng, chân mày và hướng đầu chuyển động** theo trạng thái thật: nhìn/chớp mắt khi chờ, nét suy nghĩ khi đang xử lý, miệng khớp nhịp audio khi phát lời, dừng miệng ngay khi ngừng tiếng. Nét mặt chỉ biểu đạt trạng thái của **AI**, không giả AI đang nhìn hoặc đo cảm xúc người dùng. Nhãn `MindClock AI` luôn thấy; không dùng mặt người thật giả lập bạn cùng lớp. Khi mất audio, avatar không nói mấp máy; khi Reduce Motion/máy yếu, dùng ảnh tĩnh và chỉ báo `Đang trả lời`. Ở phòng nhóm, AI xuất hiện trong một ô riêng sau khi được mời, không thay ô của bạn thật và có nút `Mời AI ra`.

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
| ROOM-09 | Chia sẻ link/mã/QR và thu hồi; người chưa đăng nhập hoặc không được mời mở link | Xem trước phòng, xác thực/quyền rồi mới xin vào; hết hạn/chặn/đủ chỗ không join; QR không lộ dữ liệu riêng. |
| ROOM-10 | Nhắn nhóm, gửi ảnh, tag hỏi AI trong/sau phiên | Chọn rõ người nhận/xem trước; chat nhóm không tự vào AI; ảnh tạm không lưu mặc định; text vẫn có khi voice lỗi. |
| ROOM-11 | Bật AI voice/avatar, chuyển Học sâu/Reduce Motion/mạng yếu | Avatar chuyển động theo audio thật, dừng khi audio dừng; Học sâu không tự phát tiếng, luôn có chữ và nút tắt. |

Học cùng bạn và Live voice/video là feature flags độc lập; không xuất hiện như phòng hoạt động thật trước khi có backend, moderation, thiết bị thật và ngân sách. [Kỹ thuật realtime](../02-engineering/09-phong-hoc-realtime.md).

## Đọc câu trả lời AI trên Android — T071

Sau khi hỏi bằng chữ trong phiên AI nhịp ngắt quãng, người dùng có thể bấm **Nghe câu trả lời** hoặc **Dừng giọng đọc**. Mặc định im lặng, không tự đọc câu mới. Dùng giọng tiếng Việt ngoại tuyến đã cài trên thiết bị; thiếu giọng thì báo chưa khả dụng, vẫn đọc chữ và tiếp tục timer. Học sâu, một mình, phiên chưa bắt đầu/đã kết thúc hoặc đã đăng xuất không phát giọng. Rời màn/app, đổi phiên/tài khoản hoặc âm thanh khác được ưu tiên thì dừng, quay lại không tự phát tiếp. Avatar chỉ chuyển khẩu hình trong khoảng callback phát của engine; Reduce Motion giữ ảnh tĩnh. Đây là đọc text theo lượt, chưa phải nói chuyện hai chiều/Gemini Live.
