# Nhật ký

20/11/2026: thêm settings patch host-only, row lock/count invariant; repo fetch/settings và VM room độc lập khỏi timer. Panel hiện cả trong phiên học. Poll5s không overlap, lifecycle/dispose epoch, lỗi mạng giữ snapshot, 403/404 bỏ room. Editor giữ initial snapshot để không crash nếu room đóng giữa lúc mở sheet; gửi chỉ field đổi. Mic/cam REST trước đây chỉ đổi flag và giả trạng thái bật, đã khóa UI chưa khả dụng, cập nhật test phản ánh đúng media chưa nối.

20/11/2026: room có GET detail nhưng Flutter chưa fetch/poll; chủ phòng không thể sửa capacity sau tạo. T068 đã dùng row lock join/leave; settings phải dùng cùng khóa. Giữ game WIP và các keys ngoài commit.

Kiểm sau đổi trạng thái done phát hiện dòng mô tả TC04 còn ghi Chưa chạy từ template dù đã có kết quả PASS bên dưới; đã cập nhật đúng kết quả và chạy lại task checker với Python UTF-8 (stdout Windows cp1252 không in được thông báo tiếng Việt). Không thay cổng hoặc che phần kiểm Android còn thiếu.
