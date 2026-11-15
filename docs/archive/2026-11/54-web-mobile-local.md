# Web mobile local

Đường `/product` là giao diện web hai tính năng báo thức và Không gian học, được làm ở T023. Đây không thay thế Flutter Android hoặc chứng minh báo thức OS hoạt động.

## Chạy

- Tại gốc repo chạy `START-MINDCLOCK.cmd`; mở `http://127.0.0.1:8010/product`.
- Sau khi cập nhật route, khởi động lại server cũ. HTML/CSS/JS mới dùng `Cache-Control: no-store`.
- Trên desktop rộng có khung điện thoại tối đa 480px; trên màn hẹp dùng toàn chiều rộng. Không phải ứng dụng Windows/native.
- Server mặc định bind loopback vì đang dùng chế độ tài khoản demo local; không tự mở ra Internet/LAN.

## Phạm vi

Điều hướng web gồm Hôm nay, Báo thức, Học, Tôi. Đây là lát cắt web riêng theo yêu cầu hai tính năng, không thay điều hướng Flutter và không tự mở đấu trường/rank.

- Hôm nay: giờ chuông, mở phiên học, câu ôn ngân hàng đã duyệt.
- Báo thức: giờ/ngày/âm/chế độ, lưu local trước API; cập nhật cấu hình server đã có; retry tạo giữ idempotency key khi chưa nhận kết quả.
- Học: Đồng hồ và Hỏi trợ lý tách màn. Timer tính bằng deadline, khôi phục local, tạm nghỉ/kết thúc. Chat chỉ gửi theo thao tác và không lưu mặc định.
- Tôi: trạng thái kết nối, số phiên chưa đồng bộ, chủ động gửi lại metadata phiên kết thúc. Không gửi ảnh/chat ngầm.

## Giới hạn và kiểm chứng

Báo thức web cần tab và máy hoạt động; không bảo đảm khi ngủ/đóng tab/background bị OS dừng. Dừng khẩn cấp không chờ API. HTTP không có Web Crypto randomUUID vẫn dùng getRandomValues cho mã phiên.

API đang dùng database theo cấu hình backend hiện hữu (bản demo local là SQLite); không tuyên bố PostgreSQL đã deploy. Các quyền/auth không được mở rộng trong task UI.

Kiểm API và logic ở `tasks/T023-web-product-local/tests.md`; browser thật, 320/360/390/600px, chữ 200%, âm thanh và bàn phím phải ghi bằng chứng riêng. Không dùng Node VM để kết luận layout đã QA.
