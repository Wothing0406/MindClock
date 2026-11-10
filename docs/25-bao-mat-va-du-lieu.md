# Chính sách bảo mật và quản trị dữ liệu — bản đặc tả triển khai

**Trạng thái:** quy tắc kỹ thuật và bản nháp chính sách; chưa phải văn bản pháp lý đã duyệt hay chính sách công bố. Trước pilot với người chưa thành niên, đội phải xác định đơn vị kiểm soát dữ liệu, người liên hệ, nơi lưu và thời hạn theo thị trường áp dụng. Firebase nêu khách hàng thường là bên kiểm soát dữ liệu; Firebase Authentication xử lý tại [trung tâm dữ liệu Hoa Kỳ](https://firebase.google.com/support/privacy/), cần nói rõ khi công bố.

## 1. Danh mục và mục đích

| Dữ liệu | Mục đích | Nơi lưu đề xuất | Mặc định/hiển thị |
| --- | --- | --- | --- |
| Email, UID, trạng thái xác minh | Đăng nhập/khôi phục | Firebase Auth | Chỉ chủ tài khoản/quản trị được phân quyền |
| Khối, môn, thời khóa biểu, giờ báo thức | Chọn câu và lập lịch | Trên máy; đồng bộ mã hóa qua Firestore khi bật | Không có trên bảng/giáo viên |
| Đáp án, kết quả chấm, XP | Phản hồi và tiến bộ | Firestore theo UID | Riêng tư |
| Ảnh bài viết tay | Chấm phiên hiện tại | Bộ nhớ tạm backend/Gemini; không lưu mặc định | Không trên bảng/log |
| Biệt danh/avatar/điểm thi | Bảng tự nguyện | Firestore projection | Chỉ khi opt-in, theo môn/khối/tuần |
| Dữ liệu lỗi kỹ thuật | Vận hành | Log có giới hạn | Không chứa ảnh, token, đề, giờ ngủ |

**Không thu thập:** vị trí GPS, danh bạ, microphone ở MVP, tên thật/trường bắt buộc, dữ liệu sức khỏe, ảnh khuôn mặt, quảng cáo định danh. Ảnh bài làm có thể vô tình chứa tên/trường: UI nhắc che thông tin trước khi gửi, backend cắt/giới hạn vùng nhận diện khi khả thi. Dữ liệu dùng để chấm không dùng cho huấn luyện nội bộ hay tiếp thị.

## 2. Quy tắc truy cập và truyền dữ liệu

- HTTPS/TLS mọi API. Firebase ID token được backend xác minh server-side; không tin `uid`, `role`, điểm/rating từ client. Firestore Rules deny-all rồi mở đúng document; Admin SDK chỉ ở backend. Tách dự án local/staging/production.
- Secret trong môi trường server/secret manager, không commit `.env`, service account JSON, API key riêng hoặc ảnh thật. Key Firebase client không thay thế Security Rules; giới hạn API key theo dịch vụ/nền tảng khi phù hợp.
- Ảnh gửi khi người dùng bấm `Gửi bài`, có tối đa kích thước/MIME, magic bytes, giới hạn lượt, timeout và xóa tệp tạm trong `finally`. Không đưa ảnh vào error monitoring, analytics, prompt debug hoặc backup mặc định.
- Backend gọi Gemini với rubric tối thiểu; validate output/schema; không gửi tên/email/giờ dậy. **Gemini API free tier có thể dùng nội dung để cải thiện sản phẩm theo bảng giá Google**; do đó demo miễn phí chỉ dùng ảnh giả/được phép và không gửi bài thật của trẻ em qua free tier khi chưa có đánh giá quyền riêng tư và đồng ý phù hợp. Xem [bảng giá/chính sách tier](https://ai.google.dev/gemini-api/docs/pricing).
- Rate limit theo tài khoản + IP, chống nộp kép bằng idempotency, audit thay điểm/rank, rollback quyền khi rời nhóm. Phân quyền nhân sự theo tối thiểu; bật 2FA cho tài khoản vận hành.

## 3. Thời hạn lưu đề xuất cần chốt trước pilot

| Loại | Mặc định đề xuất | Xóa/giữ |
| --- | --- | --- |
| Ảnh bài làm | Chỉ trong request, mục tiêu xóa trong 15 phút kể cả lỗi | Không backup; nếu xin lưu để khiếu nại, consent riêng và TTL ≤7 ngày |
| Lịch học/tiến bộ | Đến khi người dùng xóa, hoặc 12 tháng không hoạt động | Cảnh báo và cho xuất trước khi xóa định kỳ |
| Submission/rating ledger | Trong mùa + 90 ngày để xử lý tranh chấp | Sau đó tổng hợp hoặc xóa; khi xóa account thì ẩn ngay |
| Log kỹ thuật tối thiểu | 30 ngày | Không chứa PII/nội dung bài |
| Export dữ liệu | Link tạm 24 giờ | Xóa tự động |

Đây là **ngưỡng thiết kế**, không tự cho rằng đã tuân luật. Mỗi job TTL có test, metric lỗi và quy trình dọn thủ công khi job thất bại. Xóa tài khoản: thu hồi quyền/ẩn bảng ngay, queue xóa các collection, Auth cuối cùng, trả trạng thái; xác nhận hoàn tất sau khi các bản sao do app quản lý đã được dọn. Không hứa xóa tức thời trên hệ thống nhà cung cấp vượt quyền đội.

## 4. Quyền của người dùng và thông báo minh bạch

Trong app: xem chính sách trước đăng ký; tải dữ liệu; sửa hồ sơ; rút khỏi bảng; tắt linh thú; thu hồi quyền ảnh/thông báo ở OS; xóa tài khoản. Trước ảnh AI hiển thị: `Ảnh bài làm sẽ được gửi đến dịch vụ AI để nhận phản hồi. Không chụp tên hoặc thông tin riêng. Bạn có thể nhập đáp án thay thế.` Trước bảng hiển thị: `Chỉ biệt danh, nhân vật và điểm được chia sẻ với người tham gia bảng này. Bạn có thể ẩn tên bất cứ lúc nào.`

Giáo viên/phụ huynh chỉ nhận dữ liệu theo quyền riêng, không mặc định có quyền vì cùng lớp/quan hệ khai báo. Bảng nhóm nhỏ không công khai nếu có thể suy ra cá nhân. Không bán dữ liệu, không quảng cáo cá nhân hóa nhắm vào học sinh.

## 5. Sự cố và kiểm thử

Phát hiện nghi lộ dữ liệu → thu hồi key/token, khóa endpoint/feature liên quan, giữ bằng chứng kỹ thuật tối thiểu, xác định đối tượng bị ảnh hưởng, thông báo theo nghĩa vụ áp dụng và ghi hậu kiểm. Test bắt buộc: user A/B, anonymous, expired token, Firestore rules, ảnh còn sót sau exception, log redaction, prompt injection trong ảnh, export/xóa, opt-out leaderboard, cache cũ, backup/restore, service account bị lộ giả lập. Review quyền riêng tư và bảo mật trước mọi pilot thật.

