# Tài khoản, quyền và dữ liệu người học

**Phạm vi:** đặc tả sản phẩm để coding và review; không thay tư vấn pháp lý. Trước pilot với người chưa thành niên, đội phải xác nhận ngưỡng tuổi, người đồng ý, chính sách nhà cung cấp AI/Auth và thông báo tại thị trường phát hành. [Kiến trúc dữ liệu](../02-engineering/03-du-lieu-sql.md), [test](../03-quality/01-ke-hoach-kiem-thu.md).

## 1. Đăng ký và vòng đời

1. Báo thức, TKB và câu mẫu local dùng được ở chế độ **khách**. Không yêu cầu số điện thoại/tên thật/trường/địa chỉ/ngày sinh đầy đủ.
2. Khi chọn đồng bộ hoặc PvP, app giải thích dữ liệu nào lên server. Email + mật khẩu qua Firebase Authentication; backend chỉ nhận và xác minh Firebase ID token, ánh xạ `auth_subject` sang user SQL. Không lưu mật khẩu trong PostgreSQL/log.
3. Email verification trước tính năng công khai; alias 3–20 ký tự, Unicode tiếng Việt, không chứa liên hệ/nhạy cảm/mạo danh. Avatar mặc định nếu không upload. Xác nhận nhóm tuổi/consent theo chính sách đã được duyệt; thiếu điều kiện thì chỉ local/riêng tư.
4. `Tôi → Tài khoản & dữ liệu`: xem/sửa hồ sơ, đăng xuất, rút consent, yêu cầu xuất/xóa. Xóa tài khoản: xác thực lại, ẩn nội dung công khai ngay, tạo job xóa idempotent, trả tiến độ, dọn dữ liệu app quản lý rồi xử lý Auth. Không hứa xóa tức thời khỏi bên thứ ba ngoài quyền kiểm soát.
5. Máy dùng chung: đổi tài khoản/đăng xuất không lộ lịch, bản nháp, câu trả lời của người trước; báo thức local còn lại được hiển thị trung tính để chủ máy sửa/xóa, không tiết lộ chi tiết học trên màn khóa.

## 2. Quyền và consent riêng

| Quyền/dữ liệu | Khi hỏi | Mặc định/thu hồi |
| --- | --- | --- |
| Exact alarm/notification/full-screen Android | Khi người dùng lưu/kiểm báo thức và cần giải thích OS | Theo OS; hiển thị trạng thái thật, fallback, hướng mở cài đặt. |
| Camera ảnh bài làm | Khi bấm `Chụp bài` | Tắt; có nhập chữ. Xem lại/xác nhận trước upload, không lưu ảnh mặc định. |
| Mic/AI Live | Khi bấm dùng giọng nói | Tắt; không ghi liên tục, nêu chi phí/giới hạn và cách dừng. |
| Nhắc lịch | Khi bật loại nhắc cụ thể | Tắt hoặc cấu hình ít làm phiền; không tiết lộ môn/điểm trên màn khóa nếu người dùng chọn ẩn. |
| Bảng/PvP | Khi bật thi đấu/chia sẻ | Opt-in; chỉ alias/avatar/rank trong phạm vi đã chọn, rút dễ dàng, không hiển thị giờ dậy. |
| Giáo viên/phụ huynh | Giai đoạn sau, theo quan hệ đã xác minh | Không có quyền mặc định vì cùng lớp hoặc khai báo quan hệ. |

## 3. Dữ liệu, lưu trữ và xóa

| Loại | Nguồn | Mặc định | Cổng xóa |
| --- | --- | --- | --- |
| Alarm/local TKB | Thiết bị | Local trước khi đăng nhập; server chỉ khi đồng bộ rõ | Người dùng xóa/sửa; khi đổi tài khoản không tự gán cho người khác. |
| Email/Auth token | Firebase | Chỉ phần cần xác thực; token không log | Luồng xóa tài khoản/Auth; TTL theo provider và chính sách duyệt. |
| Câu hỏi/rubric | PostgreSQL | Nội dung do đội duyệt, đáp án/rubric không gửi trước hoàn thành | Retire revision, giữ vết nội bộ phù hợp. |
| Bài chữ/attempt/XP | PostgreSQL khi online; nháp local tùy chọn | Nháp chữ local tối đa 24h nếu người dùng chọn; server theo chính sách thời hạn trước pilot | Export/xóa tài khoản, TTL job và backup policy. |
| Ảnh bài làm | Bộ nhớ xử lý tạm thời | **Không lưu mặc định**, không log; xóa cả khi exception | Test temp-file/queue/backup không sót. |
| Video/frame/cảm xúc tập trung | Không thu ở P0 | Không quay liên tục, không suy đoán tập trung từ mặt hoặc app khác | Bất kỳ thử nghiệm mới cần PRD, consent, retention riêng. |

Thời hạn retention cụ thể, nơi lưu trữ, quyền nhà cung cấp và văn bản chính sách phải được owner chốt **trước pilot**; docs không tự đặt con số tùy tiện để coi đã tuân thủ.

## 4. Moderation và bảo vệ học sinh

Tên, avatar upload và phát ngôn công khai phải lọc/duyệt theo rủi ro: thông tin liên hệ, khiêu dâm, bắt nạt, thù ghét, mạo danh, lộ trường/lớp/địa chỉ. Có báo cáo, tạm ẩn, kiểm tra bởi người, kháng nghị và giới hạn rate. Không có chat tự do trong MVP/PvP đầu. Không bán dữ liệu hoặc quảng cáo cá nhân hóa nhắm vào học sinh. Biệt danh và ảnh công khai không làm lộ lịch thức dậy hay điểm yếu học tập.

## 5. Test bắt buộc

Guest không bị ép đăng nhập; token sai/hết hạn 401; A không đọc/ghi B; email chưa xác minh không vào bảng; consent rút chặn gửi ảnh/Live; camera từ chối vẫn nhập chữ; không log ảnh/key; logout máy chung không lộ cache; export/xóa có tiến độ và idempotency; opt-out ẩn bảng; album/backup/queue không giữ ảnh ngoài chính sách. Xem [ma trận](../03-quality/01-ke-hoach-kiem-thu.md). AI không được tự kết luận pháp lý hoặc thay review chính sách trước pilot.
