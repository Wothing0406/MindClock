# Tài khoản, quyền và dữ liệu người học

**Phạm vi:** đặc tả sản phẩm để coding và review; không thay tư vấn pháp lý. Trước pilot với người chưa thành niên, đội phải xác nhận ngưỡng tuổi, người đồng ý, chính sách nhà cung cấp AI/Auth và thông báo tại thị trường phát hành. [Kiến trúc dữ liệu](../02-engineering/03-du-lieu-sql.md), [test](../03-quality/01-ke-hoach-kiem-thu.md).

## 1. Đăng ký và vòng đời

1. Happy path là `Đăng ký`/`Đăng nhập` sau màn giới thiệu quyền. Form đăng ký có email (không giới hạn Gmail), biệt danh, mật khẩu và xác nhận; không yêu cầu số điện thoại/tên pháp lý/trường/địa chỉ/ngày sinh đầy đủ. Báo thức và Dừng khẩn cấp vẫn dùng local nếu Auth/mạng lỗi.
2. Email + mật khẩu qua Firebase Authentication; backend chỉ nhận và xác minh Firebase ID token, ánh xạ `auth_subject` sang user SQL. Không lưu mật khẩu trong PostgreSQL/log. Form có gửi lại email xác minh, quên/đổi mật khẩu và lỗi tiếng Việt. [Chi tiết onboarding](07-dang-ky-va-khoi-tao-lo-trinh.md).
3. Email verification trước tính năng công khai; alias 3–20 ký tự, Unicode tiếng Việt, không chứa liên hệ/nhạy cảm/mạo danh. Avatar mặc định nếu không upload. Xác nhận nhóm tuổi/consent theo chính sách đã được duyệt; thiếu điều kiện thì chỉ local/riêng tư. Không tự bật AI Live/phòng bạn sau khi tạo account.
4. `Tôi → Tài khoản & dữ liệu`: xem/sửa hồ sơ, đăng xuất, rút consent, yêu cầu xuất/xóa. Xóa tài khoản: xác thực lại, ẩn nội dung công khai ngay, tạo job xóa idempotent, trả tiến độ, dọn dữ liệu app quản lý rồi xử lý Auth. Không hứa xóa tức thời khỏi bên thứ ba ngoài quyền kiểm soát.
5. Máy dùng chung: đổi tài khoản/đăng xuất không lộ lịch, bản nháp, câu trả lời của người trước; báo thức local còn lại được hiển thị trung tính để chủ máy sửa/xóa, không tiết lộ chi tiết học trên màn khóa.

## 2. Quyền và consent riêng

| Quyền/dữ liệu | Khi hỏi | Mặc định/thu hồi |
| --- | --- | --- |
| Exact alarm/notification/full-screen Android | Giải thích ở onboarding, xin quyền khi lưu/kiểm báo thức | Theo OS; hiển thị trạng thái thật, fallback, hướng mở cài đặt. |
| DND/chế độ ngủ | Khi người dùng bật lịch ngủ/Không làm phiền | Opt-in; Android có thể từ chối hoặc chỉ cho rule riêng của app. Không báo đã bật toàn máy nếu chưa xác nhận OS. |
| Camera ảnh bài làm | Khi bấm `Chụp bài` | Tắt; có nhập chữ. Xem lại/xác nhận trước upload, không lưu ảnh mặc định. |
| Mic/AI Live | Khi bấm dùng giọng nói | Tắt; nêu giới hạn phút/chi phí, indicator và nút dừng. Quyền cho Live khác quyền cho push-to-talk nếu dữ liệu/retention khác. |
| Camera/video phòng bạn | Khi vào phòng và bấm bật cam | Tắt; xem preview, không ghi/lưu mặc định, người kia không ép bật. |
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
| Âm/ảnh phòng học và AI | Chỉ khi user bật mic/cam/Live | Không lưu mặc định; frame gửi AI phải được user chọn/xem lại; telemetry chỉ kỹ thuật | Dừng streaming khi tắt/rời; delete/export theo chính sách tính năng trước mở. |
| Chat/ảnh phòng bạn và QR mời | Khi user gửi tin/ảnh hoặc tạo lời mời | Chat chỉ cho thành viên; AI chỉ nhận tin/ảnh được tag và consent; QR chứa token có hạn, không chứa dữ liệu học | Thu hồi link, rời/chặn, xóa ảnh tạm/TTL chat; lịch sử dài hạn cần consent riêng. |
| Khung rảnh MultiCal/nhóm | Khi user bật chia sẻ khung rảnh hoặc tham gia nhóm | Chỉ free/busy và số người rảnh; TKB, giờ ngủ/báo và nguyên nhân bận vẫn riêng | Rút chia sẻ/hủy nhóm dừng projection/nhắc; retention proposal phải chốt trước mở. |

Thời hạn retention cụ thể, nơi lưu trữ, quyền nhà cung cấp và văn bản chính sách phải được owner chốt **trước pilot**; docs không tự đặt con số tùy tiện để coi đã tuân thủ.

## 4. Moderation và bảo vệ học sinh

Tên, avatar upload và phát ngôn công khai phải lọc/duyệt theo rủi ro: thông tin liên hệ, khiêu dâm, bắt nạt, thù ghét, mạo danh, lộ trường/lớp/địa chỉ. Có báo cáo, tạm ẩn, kiểm tra bởi người, kháng nghị và giới hạn rate. Phòng bạn chỉ bằng lời mời, block/report, không có tìm kiếm công khai hoặc chat tự do trong bản đầu. Không bán dữ liệu hoặc quảng cáo cá nhân hóa nhắm vào học sinh. Biệt danh và ảnh công khai không làm lộ lịch thức dậy hay điểm yếu học tập. Trước khi phát hành cho người chưa thành niên, người phụ trách phải rà điều kiện tuổi, đồng ý, nhà cung cấp và chính sách dữ liệu áp dụng.

Tìm phòng theo sở thích là lát sau của [R7b](../00-start/02-lo-trinh.md), chỉ mở khi có review tuổi/consent, moderation trực, giới hạn tạo/join, block/report và test chống lộ lịch. Không dùng guest ẩn danh vào phòng người lạ; pet nhóm không phạt hoặc công khai giờ dậy của thành viên.

## 5. Test bắt buộc

Happy path đăng ký, nhưng local alarm không bị ép đăng nhập khi mạng/Auth lỗi; token sai/hết hạn 401; A không đọc/ghi B; email chưa xác minh không vào bảng; consent rút chặn gửi ảnh/Live; camera từ chối vẫn nhập chữ; không log ảnh/key; logout máy chung không lộ cache; export/xóa có tiến độ và idempotency; opt-out ẩn bảng; album/backup/queue không giữ ảnh ngoài chính sách. Xem [ma trận](../03-quality/01-ke-hoach-kiem-thu.md). AI không được tự kết luận pháp lý hoặc thay review chính sách trước mở người dùng thật.
