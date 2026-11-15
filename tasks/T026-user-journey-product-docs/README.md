# T026 — Hành trình sản phẩm MindClock

- **Trạng thái:** `done` — tài liệu đã kiểm, chưa hàm ý tính năng runtime đã hoàn tất.
- **Mục tiêu:** cập nhật toàn bộ nguồn chuẩn theo hành trình người dùng từ đăng ký đến học, báo thức, phòng học và cộng đồng; bỏ định hướng cuộc thi khỏi tài liệu hiện hành.
- **Nguồn:** yêu cầu người dùng ngày 15/11/2026 cùng ảnh tham chiếu vòng ngủ/thức.
- **Phạm vi:** docs canonical, AGENTS.md, README.md và skill Android nội bộ; không sửa runtime app/API hay WIP T022/T023.
- **Điểm tiếp tục:** mở B01a/B01b/B01c từ [backlog](../../docs/00-start/05-goi-task-dau-tien.md), kiểm môi trường thật trước coding thêm; giữ nguyên WIP T022/T023.

## Cổng trước thay đổi

- [x] Đọc docs index, PRD/UX/account/alarm/study, task workflow và trạng thái Git.
- [x] Đối chiếu nguồn chính thức Android, Gemini Live, Firebase Auth, chương trình GDPT, thông tin giấc ngủ.
- [x] Có spec/plan/tests cho task docs này.

## Cổng kết thúc

- [x] Mỗi bước hành trình có trạng thái lỗi/quyền/ngoại tuyến và AC.
- [x] Docs kỹ thuật, AI, privacy, quality và AGENTS đồng bộ.
- [x] Link/truy vết/task checker đạt; không sửa WIP runtime.
- [x] Handoff ghi các quyết định còn mở và task coding đầu.
