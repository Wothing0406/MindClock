# Đặc tả T010

## Vấn đề

Khung avatar hạng đang bị hiểu là huy hiệu hạng. Chưa có asset badge để đặt ở kết quả trận/profile; chưa có luồng thay avatar hoặc upload, lịch sử đấu/giờ dậy, uy tín, quyền xem và quy tắc tên/ảnh/nội dung. README còn bỏ sót Clock, không gian học và chatbot.

## Phạm vi

Thiết kế sản phẩm/API/SQL ở docs, badge SVG riêng, web demo tải ảnh **chỉ preview local** (không lưu/upload), README. Không triển khai backend, bảng xếp hạng hoặc kiểm duyệt thật. Trẻ em mặc định riêng tư, giờ dậy không lên bảng.

| ID | Điều kiện | Hành vi | Test |
| --- | --- | --- | --- |
| AC-01 | Xem hạng | badge độc lập khung avatar, 6 tier có hình và nhãn, xuất hiện ở kết quả và profile spec | TC-01 |
| AC-02 | Sửa avatar | chọn mặc định hoặc upload ảnh hợp lệ; preview local, hủy/xóa được, không tự gửi mạng; API tương lai có quyền/kiểm duyệt | TC-02 |
| AC-03 | Xem hồ sơ | chủ/khách thấy trường và lịch sử đúng phạm vi; wake history riêng tư mặc định, battle history có opt-in | TC-03 |
| AC-04 | Xem uy tín | định nghĩa nguồn và phạm vi, không phạt sai/AI uncertain/dừng khẩn cấp, không thành bảng công khai | TC-04 |
| AC-05 | Tên/ảnh/nội dung | quy tắc viết/duyệt/báo cáo/kháng nghị, bảo vệ trẻ em, không giả kiểm duyệt AI hoàn hảo | TC-05 |
| AC-06 | Mở README | toàn bộ trục Clock, lịch, học nhiều môn, không gian học, chatbot, PvP, giới hạn triển khai | TC-06 |
| AC-07 | Push | test và tài liệu task đầy đủ, commit remote xác nhận | TC-07 |

## Quyết định

`avatar` của tài khoản khác `character` thi đấu. Khung hạng là viền quanh avatar, badge là biểu trưng hạng độc lập. `reputation` nếu giữ là chỉ số nội bộ chống lạm dụng cộng đồng, không phải điểm tỉnh táo/học lực; không hiện công khai ở MVP. Lịch sử báo thức chỉ người dùng xem, có xóa/xuất; không suy ra giờ ngủ/sức khỏe. Nội dung user upload có pipeline pending/approved/rejected và đường dùng avatar mặc định trong khi chờ.
