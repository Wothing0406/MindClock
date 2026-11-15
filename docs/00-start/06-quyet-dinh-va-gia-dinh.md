# Quyết định, giả định và cổng còn mở

Đây là sổ quyết định cho người giao task. `Đã chốt` là yêu cầu sản phẩm hiện tại; `cần xác nhận` không được AI tự coi là dữ kiện. Mỗi quyết định mới ghi ngày, người chốt, lý do, file contract/test bị ảnh hưởng. [Hiện trạng](01-hien-trang.md) nói phần nào đã có bằng chứng chạy.

| ID | Trạng thái | Quyết định hoặc câu hỏi | Điều kiện mở tiếp |
| --- | --- | --- | --- |
| D-01 | Đã chốt | Android là nền tảng đầu tiên; Flutter UI + Kotlin cho báo thức OS; backend FastAPI/PostgreSQL. Web nội bộ không là sản phẩm. | Build Android và PostgreSQL test thật trước tuyên bố MVP. |
| D-02 | Đã chốt | Báo thức/Dừng khẩn cấp cục bộ, không mạng, không đăng nhập; thử thách không Hoãn; không khóa máy/app khác. | AD01–AD09 trên máy thật. |
| D-03 | Đã chốt | Câu MVP từ ngân hàng đã duyệt; AI chỉ hỗ trợ đọc/chấm/gợi mở; `uncertain` không phạt. | Content reviewer, rubric và eval set. |
| D-04 | Đã chốt | Đấu trường tự nguyện, sau báo thức/học; giao hữu trước ranked. Server chốt trận/điểm. | Playtest hai máy, chống lặp, quyền asset/content. |
| D-05 | Cần xác nhận | Độ tuổi tối thiểu/đồng ý của phụ huynh, phạm vi khu vực và mẫu thông báo dữ liệu trước pilot học sinh. | Người phụ trách pháp lý/sản phẩm duyệt flow theo thị trường phát hành. |
| D-06 | Cần xác nhận | Bộ câu nào được quyền nhập và quyền dùng ảnh/sprite/âm thanh khi phát hành công khai. Repo mở không tự cấp quyền nội dung đề. | Registry từng nguồn/item và bằng chứng quyền; reviewer ký duyệt. |
| D-07 | Cần xác nhận | Ngưỡng false-correct/false-incorrect, độ trễ và chi phí AI tối đa. | Chốt trước pilot trên tập đánh giá độc lập; fallback được kiểm. |
| D-08 | Cần xác nhận | Thiết bị/API level/OEM mục tiêu, kênh phân phối APK/store, mức hỗ trợ và ngân sách hạ tầng. | Kiểm máy thực, bảo mật, vận hành, rollback. |
| D-09 | Cần xác nhận | Canonical ID/tên Hàn Bối Pháp (`han_boi_thap` là ID cũ), số combat v0.1, hình/phần thưởng/rank. | Catalog migration + playtest; không dùng số v0.1 như luật cố định. |
| D-10 | Cần xác nhận | Chính sách giữ nháp chữ, metadata phiên học, ảnh upload avatar và thời hạn xóa ở môi trường phát hành. | Đồng bộ privacy notice, SQL purge job, test rút consent/xóa. |
| D-11 | Đã chốt | Đây là sản phẩm lâu dài, không scope DevFest; cohort đầu THPT 10–12, happy path đăng ký email → lớp/môn/avatar → plan xác nhận → dashboard. | ON-01–06, catalog/reviewer; báo thức local là fallback khi Auth lỗi. |
| D-12 | Đã chốt | Quyền giải thích lúc mở app nhưng OS prompt đúng lúc dùng. Màn khóa mặc định ẩn môn/TKB, DND chỉ khi quyền/OS cho phép. | SLEEP-01–05/AD, máy thật nhiều API level. |
| D-13 | Đã chốt | Phòng học có solo/AI/bạn; avatar 2D có nhãn AI; mức nhắc nghiêm không xúc phạm/phạt; mic/cam tắt mặc định. | ROOM-01–06, privacy/abuse/Live quota gates. |
| D-14 | Cần xác nhận | Catalog THPT theo phiên bản chương trình hiện hành, trường hợp môn địa phương/chuyên đề, reviewer và số câu tối thiểu từng môn. | Review nguồn Bộ GD&ĐT, seed có provenance, không mở scored nếu thiếu. |
| D-15 | Cần xác nhận | Nhà cung cấp media phòng bạn, Live model/quota/giá, giới hạn phút miễn phí và quy trình tuổi/consent. | Spike hai máy, đo chi phí/độ trễ, review chính sách nhà cung cấp trước mở flag. |
| D-16 | Đã chốt | Lượt sáng vào mở màn gắn câu ngay, không màn hỏi bắt đầu; câu có lý do bắt buộc để tính hoàn thành/EXP/chuỗi. Hook bỏ qua được, câu không. | MORNING-01–03; asset/reviewer/rights, Android offline/Reduce Motion. |
| D-17 | Đã chốt | Hint sau sai rõ lần 3, Bỏ lượt từ lần 5 không thưởng; Dừng âm khẩn cấp bất kỳ lúc nào; uncertain/lỗi hệ thống không bị tính sai/đứt chuỗi oan. | Backend đếm attempt idempotent, streak policy/SQL migration và test thời gian/ngày. |
| D-18 | Đã chốt | EduSkills-VN là nguồn quy tắc sư phạm/authoring/grading guidance theo môn; không là model hay ngân hàng câu tự publish. | Adapter versioned, reviewer, prompt modes, eval đa môn; [hợp đồng](../02-engineering/11-eduskills-vn-tich-hop.md). |

Khi task phụ thuộc một dòng `cần xác nhận`, vẫn triển khai phần độc lập. Ghi rõ blocker trong `tasks/TNNN-.../handoff.md`; không lấp bằng mock rồi đánh dấu xong. [Quy trình](03-quy-trinh-vibe-code.md).
