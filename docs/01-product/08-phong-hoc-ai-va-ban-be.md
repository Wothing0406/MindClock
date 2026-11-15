# Không gian học: một mình, cùng AI, cùng bạn

**Mục tiêu sản phẩm:** tạo cảm giác có bạn đồng hành để người học bắt đầu và duy trì một phiên học có việc cụ thể. Không giả AI là người thật, không “chửi”/làm nhục học sinh, không khóa họ trong phòng. Có ba lựa chọn rõ: `Học một mình`, `Học cùng MindClock`, `Mời bạn học`. [PRD](01-prd.md), [quyền riêng tư](04-tai-khoan-quyen-rieng-tu.md).

## Trước khi vào phòng

Chọn môn từ hồ sơ, việc cần làm từ lịch hoặc nhập tay, thời lượng 10/25/45 phút/tùy chỉnh, nhịp `Học sâu` (một khoảng tập trung dài) hoặc `Học ngắt quãng` (vòng tập trung/nghỉ). Chọn mức nhắc `Yên tĩnh / Nhắc nhẹ / Nghiêm túc`, mặc định `Nhắc nhẹ`; xem trước kiểu lời nói. Mic/camera **tắt mặc định**, bật độc lập; có kiểm âm/cam, trạng thái quyền và preview trước kết nối. Không yêu cầu camera để dùng timer hoặc hỏi bằng chữ. Chỉ bắt đầu tính thời gian khi người học bấm `Bắt đầu`.

## Bố cục phòng dọc

Nửa trên: ô video của người học nếu bật, hoặc avatar tĩnh; ô MindClock **gắn nhãn AI** là avatar 2D có miệng theo âm lượng/viseme nếu có audio thật, hoặc ô bạn được mời. Nửa dưới: timer lớn, việc đang làm, môn, tiến độ các đoạn, các nút `Mic`, `Cam`, `Hỏi`, `Tạm dừng`, `Nghỉ`, `Rời phòng`. Trạng thái đang truyền âm/ảnh và nút tắt phải luôn thấy. Không có animation giả AI đang nhìn/chấm mức tập trung khi camera tắt. Khi mạng yếu, chuyển video → audio → text/timer local, giữ nút kết thúc.

## AI đồng hành và lời nhắc

Mở phiên: hỏi `Hôm nay bạn muốn xong việc gì?`; sau khi user xác nhận, AI nhắc mục tiêu một câu. Trong phiên, mặc định **không gửi camera liên tục** và không phát lời nói tự động mỗi phút. Timer local có thể nhắc ở mốc user chọn; phát hiện im lặng/ứng dụng background chỉ khi có tín hiệu kỹ thuật đã xin phép, không suy “lười” từ mặt, tư thế hay cuộc nói chuyện ngoài. Rời app: khi quay lại hỏi `Bạn muốn tiếp tục từ phút 12 không?`; nếu người dùng đã chọn thông báo, có tối đa một nhắc local sau khoảng họ đặt. Nút `Tạm nghỉ`/`Rời phòng` luôn có; không trừ điểm vì rời hoặc không báo trước.

Mức `Nghiêm túc` nói ngắn, dứt khoát: `Mình còn 8 phút. Quay lại bài đang làm nhé.` Có thể có đùa nhẹ tự trào ở avatar sau phiên, ví dụ `Tớ vừa giữ chỗ cho trang vở này.` Không dùng xúc phạm, chửi, đe dọa, gây xấu hổ trước bạn bè hoặc nhân cách “giận dỗi” kéo dài. Người học có nút `Ít nhắc hơn`, `Im lặng 10 phút`, `Tắt AI`; nếu họ bày tỏ mệt mỏi/khó chịu, giảm nhắc và gợi nghỉ.

## Hỏi bằng giọng nói và hình ảnh AI

P1 text/voice theo lượt: bấm để nói, STT → câu hỏi gợi mở → TTS, phát xong tự ngừng; tiết kiệm token, hoạt động cả khi camera tắt. P2 Gemini Live full-duplex khi đã đạt cổng ngân sách/quyền: mic opt-in, audio streaming, ngắt lời, reconnect/session renewal, transcript tối thiểu theo policy, token ephemeral từ server. Camera nếu bật chỉ dùng cho cuộc gọi hoặc gửi **khung hình có chủ đích** để hỏi về trang bài; không gửi video liên tục để giám sát. Avatar 2D nói theo audio, có ảnh tĩnh khi reduce motion/máy yếu. Live API có giới hạn phiên và chi phí theo token; mô hình/giá/quota phải xác nhận lúc triển khai. [Google Live API capabilities](https://ai.google.dev/gemini-api/docs/live-api/capabilities), [session management](https://ai.google.dev/gemini-api/docs/live-api/session-management), [pricing](https://ai.google.dev/gemini-api/docs/pricing/).

Trợ lý Socratic nhận môn/lớp/mục tiêu/câu hỏi và lịch sử đủ dùng, trả **một bước gợi mở**, hỏi người học thử tiếp; không giải trọn bài trước nỗ lực. Không thể bảo đảm người học chỉ nói về môn học; AI chuyển nhẹ về mục tiêu, vẫn trả lời yêu cầu nghỉ, trợ giúp an toàn hoặc dừng phiên. Có nút `Báo câu trả lời sai` và đường xem nguồn/rubric khi phù hợp.

## Mời bạn vào học

User tạo phòng `Chỉ mời`, mã/link ngắn hạn, tối đa 2 người ở giai đoạn đầu; bạn chấp nhận mới vào. Không tự bật cam/mic khi join. Mỗi người có timer local đồng bộ mốc phòng, việc riêng có thể ẩn; chủ phòng không xem bài/TKB/điểm riêng. Người tham gia có `Rời`, `Chặn`, `Báo cáo`; chủ phòng có `Kết thúc phòng` nhưng không tắt timer local của người kia. Kết bạn bằng lời mời hai chiều, có danh sách chặn; không mở tìm kiếm công khai/nhắn tin tự do ở giai đoạn đầu. Phòng AI và phòng bạn cùng dùng shell UI nhưng networking khác nhau; khi AI quota hết, phòng bạn/timer vẫn chạy.

## Acceptance

| ID | Khi | Phải xảy ra |
| --- | --- | --- |
| ROOM-01 | Chọn 3 loại phòng, hai nhịp và mức nhắc | Timer/việc đúng lựa chọn; mic/cam tắt khi vào. |
| ROOM-02 | Từ chối mic/camera hoặc tắt giữa phiên | Timer/text tiếp tục; indicator và đường bật quyền đúng. |
| ROOM-03 | AI lỗi/quota/Live rớt mạng | Hạ cấp về text/timer, không mất phiên hoặc phát audio giả. |
| ROOM-04 | Rời app/tạm nghỉ/rời phòng | Không chửi/phạt/giữ app; có nhắc chỉ nếu đã opt-in. |
| ROOM-05 | Mời bạn/đổi account/block | Người lạ không vào, không lộ việc riêng; kick/report có audit. |
| ROOM-06 | Hỏi ngoài chủ đề hoặc yêu cầu lời giải | AI chuyển về mục tiêu bằng lời trung tính, gợi một bước, không lộ đáp án trước nỗ lực. |

Học cùng bạn và Live voice/video là feature flags độc lập; không xuất hiện như phòng hoạt động thật trước khi có backend, moderation, thiết bị thật và ngân sách. [Kỹ thuật realtime](../02-engineering/09-phong-hoc-realtime.md).
