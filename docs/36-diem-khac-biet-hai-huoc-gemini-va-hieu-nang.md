# Điểm khác biệt, giọng vui, Gemini và ngân sách tốc độ

**Trạng thái:** quyết định sản phẩm/kiến trúc để lập task; chưa đo hiệu năng trên sản phẩm thật. Luật Solo ở [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md), chấm bài giải ở [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), kỹ năng/FX ở [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md), bảo mật ở [docs/25](25-bao-mat-va-du-lieu.md). Mốc tham khảo: 11/11/2026; kiểm tra model/quota trong AI Studio trước khi code hoặc demo.

## 1. Ý tưởng đã có gì và khác ở đâu?

Không tuyên bố MindClock phát minh báo thức giải toán hoặc game quiz. [Alarmy](https://alar.my/en) đã có nhiệm vụ giải toán/chụp ảnh để tắt chuông; [Wayground/Quizizz](https://help.wayground.com/support/solutions/articles/158000404930) đã có meme sau câu hỏi. Đấu RPG có máu cũng không phải cơ chế mới tự thân. **Giả thuyết khác biệt cần kiểm chứng** là một hồ sơ học tập dùng xuyên suốt: lịch học được xác nhận → câu khởi động theo môn hôm nay → giải thích điểm yếu → giao hữu cùng môn/lớp/bộ nội dung, có nhân vật giấy/bút riêng. Giá trị thực chỉ có nếu người học hiểu luật nhanh, dùng lại hằng tuần và thấy phần ôn đúng nhu cầu. Không dùng từ “độc nhất”, “chống ngủ nướng tuyệt đối” hoặc “AI hiểu hoàn toàn lời giải”.

**Một câu giới thiệu:** `MindClock giúp bạn bắt đầu ngày học bằng một câu ôn ngắn, rồi luyện cùng bạn học đúng môn.` Phần đấu trường là lựa chọn; sản phẩm vẫn có ích khi một mình và offline.

## 2. Humor có chủ đích, không biến thành áp lực

Humor nằm ở **vật liệu và phản ứng nhân vật**: Cú Mực hơi xoay đầu khi chờ, Cáo Nắng kéo trang vở thành mái che, Rồng Giấy gấp góc giấy làm khiên. Mỗi nhân vật có một kỹ năng riêng được cân bằng theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md); một trận chỉ có một chi tiết vui ở phòng chờ hoặc reveal, không spam thoại trên màn câu/báo thức. Sau sai/thua, lời phản hồi trung tính: `Câu này cần xem lại.` hoặc `Bạn đã hoàn thành trận. Xem phần cần ôn.` Không dùng meme nhạo năng lực, nhân vật bị thương, tiếng ồn đột ngột, emoji hệ thống hay GIF tải từ Internet.

Asset: sprite 2D vẽ gốc có quyền dùng, WebP/PNG trong suốt, bundle local cho màn cốt lõi; không có mô hình 3D. Một hiệu ứng reveal 300–500 ms, có bản tĩnh và nhãn chữ. Không tải asset khi chuông reo hay đang nhận câu. Hỗ trợ `Reduce motion`, cỡ chữ lớn và tắt âm. Ngôn ngữ tiếng Việt ngắn theo [docs/30](30-ngon-ngu-va-tai-san-giao-dien.md).

## 3. Gemini làm việc gì?

| Luồng | Vai trò Gemini | Đường chạy không phụ thuộc Gemini |
| --- | --- | --- |
| Chuẩn bị ngân hàng câu | Gợi ý **bản nháp** biến thể, phương án nhiễu, giải thích; người dạy kiểm tra/publish revision | Đọc câu đã duyệt từ SQL/cache |
| Thời khóa biểu | Trích xuất **bản nháp** từ ảnh nếu người dùng chủ động gửi; người dùng xác nhận | Nhập/sửa lịch bằng tay |
| Bài viết tay buổi sáng | Hỗ trợ đọc bước làm khi có consent và kết nối; trả `correct/incorrect/uncertain` theo rubric; không quyết định XP | Đáp án nhập tay/câu offline; Dừng khẩn cấp luôn hoạt động |
| Gợi ý học | Đề xuất bước Socratic hoặc chia task; người dùng duyệt | Gợi ý mẫu đã biên tập |
| Solo giao hữu/ranked | Không sinh đề lúc phát câu; sau khi hai người nộp, AI chỉ đề xuất đọc/chấm bài giải theo rubric đã khóa, server xác minh; ranked chỉ bật khi đã kiểm định | Nếu AI lỗi/không chắc: void vòng/trận, không đổi RP; giao hữu có thể dùng fixture có nhãn |

Model mặc định đề xuất cho thử nghiệm backend: `gemini-3.5-flash-lite` cho việc thường xuyên, đầu ra ngắn/có schema; `gemini-3.8-flash` chỉ cho ca ảnh/lời giải khó hoặc rà soát bản nháp khi model nhanh trả `uncertain`. Đây là **cấu hình thử**, chưa có benchmark độ chính xác tiếng Việt/chữ viết tay cho MindClock. Cả hai là model ổn định trong [danh sách chính thức](https://ai.google.dev/gemini-api/docs/models); [Gemini 3.8 Flash](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash) hỗ trợ structured outputs. Đặt model ID ở cấu hình server, có mock/fixture cho demo, không nhúng key vào app. Dùng [structured output](https://ai.google.dev/gemini-api/docs/structured-output) với schema, nhưng vẫn validate server và human review; JSON hợp lệ không bảo đảm đáp án đúng.

**Chi phí/quota:** [trang giá Gemini](https://ai.google.dev/gemini-api/docs/pricing) có free tier cho một số model, nhưng hạn mức thực tế theo project/model và có thể đổi; kiểm tra [AI Studio rate limits](https://ai.google.dev/gemini-api/docs/rate-limits) trước demo. Không thiết kế trận phụ thuộc quota miễn phí. Nội dung free tier có điều kiện sử dụng dữ liệu; không gửi ảnh học sinh thật/đáp án cá nhân lên free tier trước khi có đánh giá, consent và cấu hình phù hợp theo docs/25. Demo dùng ảnh giả/ảnh đội tự tạo có quyền sử dụng, hoặc mock.

## 4. Ngân sách tốc độ và tải đồng thời

Mốc dưới đây là **mục tiêu cần đo**, không phải hiệu năng đã đạt. Đường nhận câu có hai người/trận; không fanout Gemini theo số người chơi. Server chọn/khóa ba revision từ SQL **trước** khi hai bên ready; giữ metadata câu ở bộ nhớ/cache server ngắn hạn, answer spec ở server. Khi bắt đầu vòng, chỉ phát payload đề và timestamp; không OCR, không gọi model, không tạo asset hoặc truy vấn bảng xếp hạng trên đường nóng.

| Điểm đo | Mục tiêu pilot | Cách đo/quyết định |
| --- | --- | --- |
| Vào phòng chờ sau ghép | P95 < 2 giây trên mạng thử | Timestamp server `matched` → hai client render; nếu chậm, kiểm tra DB/connection |
| Phát câu sau khóa kỹ năng | P95 server xử lý < 300 ms, **không tính truyền mạng** | Trace `skill_locked` → `question_sent`; đo riêng client receive/render |
| Độ lệch hai máy nhận câu | P95 < 1 giây trong mạng pilot; ngưỡng thực chỉnh sau đo | Server send/ack + clock sync; lệch lớn void nếu lộ không công bằng; không có thưởng nhanh mode viết |
| Chốt vòng sau khi **cả hai grade rõ** | P95 < 500 ms cho transaction tính HP/status, **không gồm thời gian AI** | `both_grades_final` → `round_result_committed`; đo AI/queue riêng, timeout → void |
| Màn trận trên máy Android yếu | Giữ tương tác mượt, ưu tiên 60 fps, không block input | Profiling frame time; dùng asset tĩnh nếu animation rớt khung |
| Truy vấn bảng top 20 | P95 < 1 giây pilot | Index/projection, không scan mọi submission |

Mỗi match có event sequence; push qua WebSocket, snapshot/polling để reconnect. Fanout giới hạn 2 participant/trận; dùng worker/queue **chấm sau nộp** với timeout và backoff 429/503, cùng model/prompt/rubric version cho hai bên. Hết timeout → void, không “chấm tạm đúng”. Cache câu đã duyệt theo revision. Đặt rate limit per user/endpoint, giới hạn match concurrent theo khả năng server, đo CPU/DB connections/queue lag; tăng tải bằng test 2 → 20 → 100 trận giả lập, không tuyên bố “chịu mọi số user”. Khi vượt tải: ngừng nhận trận mới và hiện chờ/luyện; trận đang chạy được ưu tiên theo deadline chấm, không tự chuyển sang model khác giữa trận. Không cache bài giải cá nhân trong CDN hoặc log.

## 5. Cổng quyết định trước demo/pilot

1. Xác nhận model ID, project free-tier quota, một request structured output và một request ảnh giả trong AI Studio/backend; ghi thời gian/429/503. Nếu không ổn, dùng fixture và nói rõ.
2. Chạy hai máy Android với một bộ câu đã duyệt, đo mốc `sent/received/rendered/submitted/settled`; quay video dự phòng **có nhãn** nếu mạng cuộc thi không bảo đảm.
3. Cho ít nhất 5 học sinh xem màn chọn kỹ năng 30 giây, hỏi họ hiểu tác dụng gì; giảm kỹ năng nếu rối. Cho xem câu giải thích sau trận, hỏi họ nhớ phần cần ôn hay chỉ nhớ hiệu ứng.
4. Soát 100% asset/thoại về bản quyền, cỡ chữ, giảm chuyển động, âm thanh, và nhãn mock/online thật.

Khi lập task coding, lấy AC/tốc độ phù hợp vào `tasks/TNNN-*/spec.md` và `tests.md`; ghi số đo thật thay cho mục tiêu trên.
