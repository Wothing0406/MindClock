# Bàn giao nhiệm vụ

## Kiểm cứu demo 14/11/2026
- Nguồn demo_ui.py đang được cập nhật đồng thời, đã đổi từ _DEMO_HTML sang _PRODUCT_HTML; tránh ghi đè bản đang làm.
- JavaScript trích từ _PRODUCT_HTML qua AST đã qua node --check (exit 0); chưa kiểm tương tác UI.
- Phát hiện bản trung gian đọc message thay message_vi và trả câu mẫu khi API lỗi; đã sửa bản trung gian nhưng cần xác minh lại sendMeetSocraticMessage trong bản mới vì file được thay đồng thời.
- Server phụ cổng 8001 báo startup thành công nhưng HTTP timeout; đã gửi lệnh dừng PID 21748. Không có bằng chứng demo chạy đúng trên browser.
- Tiếp tục: khởi động lại một server ở services/api bằng .venv/Scripts/python.exe run_demo.py, mở /demo, kiểm đúng trang sản phẩm; thử chuông/dừng và chat API thật trước khi bàn giao. Task chưa done.

- **Trạng thái cuối:** ...
- **Đã làm:** hành vi cụ thể, không nói chung “xong”.
- **File/code/docs thay đổi:** ...
- **Test đã chạy:** lệnh/kịch bản, kết quả, máy/OS nếu liên quan; liên kết `tests.md`.
- **Test chưa chạy/giới hạn:** lý do và điều kiện chạy.
- **Rủi ro còn lại:** ...
- **Điểm tiếp tục chính xác:** mở file nào, bước nào trong `plan.md`, test nào chạy lại, ai/điều kiện nào cần.
- **Quyết định phải xin người phụ trách:** chỉ nếu còn mâu thuẫn sản phẩm/quyền/chi phí không thể tự xử lý.

