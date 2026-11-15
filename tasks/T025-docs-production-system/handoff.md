# Bàn giao T025

- **Trạng thái:** `done` cho hệ tài liệu; chưa chứng minh app production.
- **Đã làm:** 29 tài liệu canonical trong 6 nhóm và `docs/README.md` mới, 58 docs lịch sử vào archive, AGENTS/README và skill Android nội bộ cập nhật, link checker đệ quy; truy vết PRD↔TC được sửa. Không sửa app/API WIP.
- **Kiểm chứng:** TC-01–04 trong `tests.md`; link checker 338 file pass, nested link regression pass, task records pass, Python compile pass. `git diff --check` toàn repo vướng trailing whitespace ở API WIP ngoài scope; staged docs check pass.
- **Giới hạn:** Android máy thật, PostgreSQL/Firebase runtime, Gemini eval, PvP live và quyền phát hành nội dung/art chưa đạt từ việc viết docs. Xem [hiện trạng](../../docs/00-start/01-hien-trang.md) và [quyết định](../../docs/00-start/06-quyet-dinh-va-gia-dinh.md).
- **Điểm tiếp tục:** tạo task B01a để tái hiện/sửa backend test health đang treo; B01b Flutter/Android build, B01c PostgreSQL migration độc lập. Sau đó B02 alarm hai máy. [Gói giao việc](../../docs/00-start/05-goi-task-dau-tien.md).
