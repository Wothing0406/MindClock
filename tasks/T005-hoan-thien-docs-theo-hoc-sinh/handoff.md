# Bàn giao T005

- **Trạng thái:** hoàn thành phần tài liệu; chưa có tính năng được triển khai hoặc kiểm chứng trên người dùng/thiết bị.
- **Đã làm:** thêm docs/41 nhu cầu học sinh U01–U10 và docs/42 ma trận giao việc; thống nhất PRD/UX/API/SQL/workflow/account/privacy/demo/QA, thay trang đấu trường cũ bằng ranh giới hiện hành; cập nhật AGENTS/index.
- **File thay đổi:** `AGENTS.md`; docs/02,04–10,12,15–19,21,23–29,31–32,35,39,41–42, README; task T005.
- **Kiểm tra:** local links 50 file/0 thiếu; `git diff --check` pass; task record checker pass sau khi tạo worklog/handoff; quét từ khóa mâu thuẫn và review thủ công. Không có test app/device/AI vì chưa có code tương ứng.
- **Tài liệu nguồn:** [docs/README.md](../../docs/README.md), [docs/41](../../docs/41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md), [docs/42](../../docs/42-ma-tran-yeu-cau-va-giao-viec.md), [docs/07](../../docs/07-hop-dong-api-va-ai.md), [docs/19](../../docs/19-kiem-toan-khoang-trong.md).
- **Rủi ro/cổng còn mở:** thể lệ DevFest, quyền dữ liệu câu hỏi, rà soát consent cho người chưa thành niên, chất lượng chấm trên bài thật, thiết bị Android/iOS thật và chi phí online; không được gọi là đã xác minh.
- **Việc bên khác cần làm:** product/UX thử 5–8 học sinh theo docs/41; nội dung/giáo viên duyệt câu/rubric; mobile mở task P0A; backend chuẩn bị P0C PostgreSQL/Auth; QA test quyền, alarm thiết bị thật và `uncertain`.
- **Điểm tiếp tục cụ thể:** khi đội bắt đầu code, tạo task ID kế tiếp sau T005 theo `tasks/README.md`; bắt đầu P0A trong docs/42 (khách local + alarm Android + Dừng khẩn cấp) và ghi AC U01/U03 ↔ A01–A07/A13 vào spec/tests. Nếu chưa có máy thật, chỉ ghi trạng thái prototype, không đánh dấu P0A done.
