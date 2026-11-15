# Hồ sơ, tiến độ học và cộng đồng

**Mục tiêu:** cho người học thấy việc mình đã làm và kiểm soát thông tin người khác nhìn thấy. Hành vi này mở từng phần sau [PRD](01-prd.md); bảng rank/PvP chỉ mở qua [GDD](../04-game/01-pvp-gdd.md). Không dùng giờ dậy làm thước đo giá trị con người.

## Hồ sơ của chính mình

Các khối: avatar/biệt danh, môn/tổ hợp đã chọn, chuỗi ngày ôn đủ điều kiện, tổng bài đã nộp, chuyên đề cần xem lại, lịch sử phiên học, lịch sử báo thức **riêng tư**, lịch sử trận và xếp hạng **nếu đã tham gia**. Mỗi chỉ số ghi định nghĩa và nguồn: ví dụ `ngày ôn` là ngày có attempt `correct` hoặc hoàn thành không chấm được người dùng đánh dấu, còn `streak XP` chỉ từ server ledger đủ điều kiện. Không ghi “thức dậy thành công” chỉ vì điện thoại phát chuông; metadata dismiss không chứng minh người dùng tỉnh.

Lịch sử có khoảng ngày, trạng thái và chi tiết tối thiểu; ảnh bài làm không lưu mặc định. Có lọc theo môn/chuyên đề, cách sửa báo chấm sai và hành động xuất/xóa dữ liệu. Màn đầu rỗng nói `Chưa có bài ôn nào` và hướng dẫn chọn môn, không dùng xếp hạng giả.

## Avatar, tên và nội dung người dùng

Khởi đầu có tối thiểu sáu avatar minh họa gốc; upload ảnh tự nguyện sau quyền/consent, crop/xem lại trước gửi; kiểm MIME/magic bytes/EXIF/kích thước, tạo ảnh nhỏ, moderation trước công khai. Avatar profile tách nhân vật chiến đấu, khung mỹ thuật tách badge rank server. Tên dài 2–24 ký tự hiển thị, Unicode tiếng Việt hợp lệ; chuẩn hóa khoảng trắng/case để kiểm trùng/lạm dụng nhưng giữ tên hiển thị người dùng chọn. Không cho tên giả mạo ban tổ chức/giáo viên, thông tin liên hệ/địa chỉ, đe dọa, xúc phạm, kỳ thị, tình dục hóa trẻ em hoặc quảng cáo. Tên/ảnh vi phạm ở trạng thái chờ hoặc ẩn, có lý do và quyền kháng nghị. Không đưa nội dung người dùng lên Gemini nếu chưa có cơ sở dữ liệu/consent phù hợp.

## Hồ sơ công khai có opt-in

Mặc định ẩn. Nếu tự bật chia sẻ: chỉ avatar đã duyệt, biệt danh, môn thi đấu tự chọn, badge rank mùa, số trận và thành tích tổng hợp. Không công khai email, trường/lớp cụ thể, TKB, giờ báo/thức dậy, bài làm/ảnh, uy tín nội bộ, lịch học, địa chỉ, ngày sinh. Cho tắt chia sẻ có hiệu lực ngay trong API/projection/cache; xóa tài khoản ẩn khỏi bảng ngay, sau đó xóa vật lý theo policy. Người dùng chưa đủ tuổi chỉ mở xã hội nếu flow đồng ý phù hợp đã được duyệt.

## Dashboard học tập

Hiển thị theo môn/chuyên đề: số câu đã làm, `correct/incorrect/uncertain`, biểu đồ 7/30 ngày, gợi ôn lại các câu sai rõ. Mẫu số nhỏ thì nói `Chưa đủ dữ liệu`; không gọi “điểm mù” là kết luận năng lực. Số liệu có nguồn/revision, không thay đổi sau khi AI regrade mà không có event audit. Dashboard giáo viên/phụ huynh là release riêng, cần vai trò, đồng ý, scope, policy tuổi, test truy cập chéo; không mặc định trong API học sinh.

## Acceptance

Hồ sơ mới trống đúng, lịch sử theo owner, rút chia sẻ ẩn ngay, avatar pending không lộ, báo vi phạm/kháng nghị có trạng thái, đổi account trên máy dùng chung xóa cache hiển thị cũ. Khi `uncertain`/appeal, tiến độ không tính như đúng. Bảng xếp hạng không kéo giờ dậy từ lịch sử báo thức. [Privacy](04-tai-khoan-quyen-rieng-tu.md), [SQL](../02-engineering/03-du-lieu-sql.md), [test](../03-quality/01-ke-hoach-kiem-thu.md).
