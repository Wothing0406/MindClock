# Hướng dẫn làm việc trong repo MindClock

## Đọc tài liệu theo việc đang làm

Đọc `docs/README.md` để tìm nguồn chuẩn, rồi chỉ đọc tài liệu liên quan đến task. Hành vi sản phẩm: `docs/04-prd-va-dac-ta-san-pham.md`; UI: `docs/05-ux-va-noi-dung-tieng-viet.md`, `docs/13-he-thiet-ke-ui.md`, `docs/23-hanh-trinh-san-pham.md`; dữ liệu/API: `docs/06-kien-truc-va-du-lieu.md`, `docs/07-hop-dong-api-va-ai.md`, `docs/17-workflow-va-vong-doi-du-lieu.md`, `docs/18-huong-dan-tich-hop-api.md`; iOS: `docs/20-ios-demo-va-phat-hanh.md`; đấu trường: `docs/21-dau-truong-xep-hang.md`; nhân vật: `docs/22-nhan-vat-rpg.md`; AI: `docs/14-vai-tro-va-quy-dinh-ai.md`; kiểm thử: `docs/09-ke-hoach-kiem-thu.md`; bàn giao: `docs/10-to-chuc-coding-agent.md`; skill: `docs/16-lua-chon-skills-cho-du-an.md`. Một sửa lỗi nhỏ không cần đọc toàn bộ bộ docs.

## Quy tắc không được phá

- Báo thức, hoãn và tắt khẩn cấp chạy trên thiết bị kể cả khi không có mạng/API/đăng nhập; không khóa người dùng trong thử thách.
- AI không được tự quyết XP, streak, rank hoặc gán nhãn gian lận. Chấm có `correct`, `incorrect`, `uncertain`; sai/không chắc không bị phạt.
- Câu hỏi MVP đến từ ngân hàng đã duyệt; Gemini hỗ trợ đọc/chấm/gợi ý. Không gửi API key tới client.
- Không lưu ảnh bài làm mặc định và không ghi ảnh, token, lời giải cá nhân vào log.
- Client không ghi điểm/tiến độ có thẩm quyền. Backend xác minh Firebase ID token, kiểm tra quyền, dùng idempotency cho phiên/attempt/XP.
- Giao diện tiếng Việt `vi-VN`, ngôn ngữ khích lệ, có đường nhập đáp án thay camera.
- Đấu trường tự nguyện; không dùng giờ dậy để xếp hạng; chỉ server chốt kết quả/rating. iOS AlarmKit không được mô tả là khóa nút Dừng của OS.
- Đăng ký/đăng nhập và xóa tài khoản theo `docs/24-dang-ky-va-quan-ly-tai-khoan.md`; dữ liệu/consent theo `docs/25-bao-mat-va-du-lieu.md`. Không dùng ảnh học sinh thật trong demo Gemini free tier khi chưa có đánh giá và đồng ý phù hợp.
- Không tuyên bố tính năng đã chạy nếu mới là mock, storyboard hoặc video dự phòng.

## Khi coding

- **Bắt buộc trước mọi thay đổi code/cấu hình/UI/dữ liệu:** đọc `tasks/README.md`; tạo hoặc tiếp tục một thư mục `tasks/TNNN-ten-ngan/` từ `tasks/_template/`. Điền `README.md`, `spec.md`, `plan.md`, `tests.md` trước khi sửa code. Chỉ task docs thuần túy/đọc-only mới không cần thư mục, trừ khi người dùng yêu cầu lưu tiến độ.
- Mỗi task gắn mục tài liệu nguồn và AC ↔ test. Khi docs mâu thuẫn, sửa docs chuẩn hoặc ghi quyết định rõ trước/cùng code; không tự đổi hành vi cho tiện triển khai.
- Sau mỗi lát cắt: cập nhật plan, chạy test phù hợp, ghi kết quả thực. Lỗi lặp theo chu trình tái hiện → nguyên nhân → sửa → test lại trong `worklog.md`; không lặp chỉnh mò quá 3 vòng cùng lỗi.
- Trước khi báo hoàn thành: cập nhật `handoff.md` và `README.md` của task với trạng thái, test, rủi ro và **điểm tiếp tục cụ thể**. Khi quay lại task, đọc handoff, vòng lỗi cuối và test chưa đạt trước khi sửa tiếp. Không gắn `done` nếu acceptance/test bắt buộc chưa đạt.
- Làm từng lát cắt dọc theo `docs/08-ke-hoach-trien-khai.md`, ưu tiên P0.
- Giữ hợp đồng API và trạng thái thống nhất. Khi thay đổi, sửa docs + contract tests cùng lần.
- Thêm test theo rủi ro thực tế, nhất là báo thức OS, quyền truy cập, AI chấm sai và XP trùng. Emulator không thay kiểm thử thiết bị thật.
- Bảo mật mặc định deny-all; chỉ mở quyền cần thiết, có test rules.
- Linh thú, ELO, dashboard và iOS đã có **đặc tả** nhưng chưa tự động thuộc MVP; chỉ code khi task/giai đoạn yêu cầu rõ. Giao hữu trước ELO.
- Kết thúc task bằng bản bàn giao theo `docs/10-to-chuc-coding-agent.md` §4.

## Trạng thái repo

Tại thời điểm tạo hướng dẫn, repo mới có tài liệu. Các đường dẫn code trong kế hoạch là dự kiến; không suy ra code đã tồn tại.

