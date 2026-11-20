# Đặc tả

AC01: host chọn 2–8 chỗ tính cả host, mặc định 4. Server serialize join/leave bằng row lock PostgreSQL; hai người tranh chỗ cuối chỉ một vào được; retry người đã trong phòng không tạo member mới.
AC02: lời mời cancelled/declined không được accept lại, trả 409; chỉ actor đúng mới respond; retry accept đã accepted idempotent, chặn pair áp dụng.
AC03: UI nhập mã phòng, chọn capacity, phòng đầy không có nút vào hoạt động. Kết quả join từ tab Tôi được đưa vào phòng thay vì bỏ mất.
AC04: test backend SQLite/PostgreSQL concurrency và widget; ghi rõ chưa có audio/video nhóm thật, QR TTL hoặc nhóm pet.
