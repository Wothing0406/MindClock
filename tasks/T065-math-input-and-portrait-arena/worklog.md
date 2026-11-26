# Nhật ký

20/11/2026: hoàn tất sửa formatter, hàng ký hiệu cuộn ngang/xem trước và trường trình bày solo/PvP. Sân compact trước đây loại bỏ ArenaSpriteActor; đã giữ lại. Chuyển nút chiêu thành bộ thẻ luôn có trong cây màn trận, khóa bằng engine; PvP cần snapshot correct và action_window. 18 test hồi quy + 2 test mới đạt, analyze sạch. E2E lần đầu lỗi thư mục output Gradle ReadOnly/rỗng; chỉ làm sạch đúng thư mục sinh ra và thử lại. Không lấy log “đang chạy” do user gửi làm bằng chứng hoàn thành.

20/11/2026: Đọc bàn giao; T064 có WIP. Bàn ký hiệu hiện chỉ nối đáp án trong Arena; formatter chưa xử lý escaped percent, đơn vị LaTeX và chỉ số dưới. Không suy ra E2E thành công từ chuỗi thông báo chạy lại.
