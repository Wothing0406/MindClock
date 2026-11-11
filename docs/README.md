# MindClock — bộ tài liệu triển khai

**Trạng thái:** đặc tả để bắt đầu coding, chưa có sản phẩm chạy. **Ngôn ngữ giao diện:** tiếng Việt. **Nền tảng đầu tiên:** Android; iOS và đấu trường có kế hoạch triển khai riêng. **Mốc tài liệu:** 10/11/2026.

**Quy trình khi bắt đầu coding:** đọc [AGENTS.md](../AGENTS.md) và [tasks/README.md](../tasks/README.md); mỗi yêu cầu code có thư mục task riêng với spec, plan, test và điểm tiếp tục.

## Thứ tự đọc

1. [01 — Tầm nhìn và ý tưởng ban đầu](01-dinh-huong-san-pham.md): bối cảnh DevFest, giả thuyết và phạm vi demo.
2. [04 — PRD và đặc tả sản phẩm](04-prd-va-dac-ta-san-pham.md): mục tiêu, persona, user stories, quy tắc nghiệp vụ, MVP và lộ trình đầy đủ.
3. [05 — UX và nội dung tiếng Việt](05-ux-va-noi-dung-tieng-viet.md): bản đồ màn hình, hành trình, nhãn, thông báo, trạng thái lỗi.
4. [06 — Kiến trúc và dữ liệu](06-kien-truc-va-du-lieu.md): nền tảng, luồng báo thức offline, trạng thái, mô hình Firestore, quyền truy cập.
5. [07 — Hợp đồng API và AI](07-hop-dong-api-va-ai.md): endpoint, payload, kết quả chấm ảnh, chính sách gợi ý và lỗi.
6. [08 — Kế hoạch triển khai](08-ke-hoach-trien-khai.md): thứ tự coding, đầu ra mỗi giai đoạn, backlog và điều kiện hoàn thành.
7. [09 — Kế hoạch kiểm thử](09-ke-hoach-kiem-thu.md): kiểm thử nghiệp vụ, thiết bị, AI, bảo mật, tiêu chí phát hành.
8. [10 — Tổ chức coding agent](10-to-chuc-coding-agent.md): nhiệm vụ, ranh giới, đầu ra và cách bàn giao của từng agent. [AGENTS.md](../AGENTS.md) là chỉ dẫn gốc cho agent làm trong repo.
9. [11 — Đặc tả mở rộng](11-dac-ta-mo-rong-san-pham.md): thích ứng độ khó, linh thú, nhóm lớp, giáo viên, phụ huynh, đấu trường, nhiều môn và chi phí.
10. [12 — Vận hành và phát hành](12-van-hanh-va-phat-hanh.md): môi trường, CI, staging, pilot, rollback và ứng phó sự cố.
11. [13 — Hệ thiết kế UI](13-he-thiet-ke-ui.md): phong cách, màu, chữ, component, từng màn và accessibility.
12. [14 — Vai trò và quy định AI](14-vai-tro-va-quy-dinh-ai.md): các vai logic, prompt boundary, quyền hạn, dữ liệu trẻ em và đánh giá.
13. [15 — Phân tích tính khả thi](15-phan-tich-tinh-kha-thi.md): cạnh tranh, khả dụng, rủi ro, chi phí và thí nghiệm quyết định.
14. [16 — Skills của dự án](16-lua-chon-skills-cho-du-an.md): đã cài, đã xem nhưng hoãn, lý do và cách dùng.
15. [17 — Workflow và dữ liệu](17-workflow-va-vong-doi-du-lieu.md): sơ đồ tuần tự, đọc/ghi CSDL, lỗi và vòng đời dữ liệu.
16. [18 — Hướng dẫn tích hợp API](18-huong-dan-tich-hop-api.md): cách mobile gọi backend, backend gọi Gemini/Firestore, lỗi và fixture.
17. [02 — Kế hoạch thi và demo](02-ke-hoach-thi-va-demo.md), [03 — Nghiên cứu và kiểm chứng](03-nghien-cuu-va-kiem-chung.md): tài liệu cuộc thi và nguồn tham khảo; không thay thế PRD/API mới.
18. [19 — Kiểm toán khoảng trống](19-kiem-toan-khoang-trong.md): phần còn thiếu, ranh giới demo và các cổng quyết định.
19. [20 — iOS và demo](20-ios-demo-va-phat-hanh.md): AlarmKit, ba mức demo, checklist Mac/Xcode/TestFlight và tiêu chí máy thật.
20. [21 — Đấu trường và bảng xếp hạng](21-dau-truong-xep-hang.md): chế độ online, luật trận, điểm/rank, dữ liệu, API và kiểm thử.
21. [22 — Linh thú RPG](22-nhan-vat-rpg.md): phong cách nhân vật, trạng thái, asset spec và brief họa sĩ.
22. [23 — Hành trình sản phẩm](23-hanh-trinh-san-pham.md): chọn app/tab, onboarding, rank, trận và các trạng thái UI tiếng Việt.
23. [24 — Đăng ký và tài khoản](24-dang-ky-va-quan-ly-tai-khoan.md): khách dùng thử, email/mật khẩu, xác minh, đồng ý thi đấu, xóa tài khoản.
24. [25 — Bảo mật và dữ liệu](25-bao-mat-va-du-lieu.md): mục đích thu thập, quyền, thời hạn, ảnh AI, rút đồng ý, sự cố.
25. [26 — Công cụ miễn phí và demo](26-bo-cong-cu-mien-phi-va-kich-ban-demo.md): mỗi vai cần cài gì, phương án 0 đồng và kịch bản giám khảo.
26. [27 — Quy chuẩn giao diện và Figma](27-quy-chuan-giao-dien-va-figma.md): phong cách tối giản, icon, thao tác, nhân vật 3D nhẹ, khung rank, animation và bàn giao thiết kế.

## Quyết định đã chốt để coding

| Chủ đề | Quyết định |
| --- | --- |
| Bản đầu | Flutter cho Android, FastAPI backend, Firebase Authentication + Cloud Firestore; Gemini chỉ được gọi từ backend |
| Báo thức | Lập lịch tại thiết bị, có câu hỏi dự phòng offline; không phụ thuộc API lúc chuông reo |
| Câu hỏi | Ngân hàng câu đã duyệt cho MVP; AI hỗ trợ đọc/chấm bài và gợi ý |
| Ảnh | Gửi qua backend, xử lý tạm thời, không lưu ảnh mặc định |
| Chấm | `correct`, `incorrect`, `uncertain`; AI không kết luận gian lận |
| Điểm | XP ghi ở server theo sự kiện; không trừ điểm vì sai bài, hoãn hoặc tắt khẩn cấp |
| Quyền riêng tư | Hồ sơ học tập cá nhân mặc định; giáo viên/phụ huynh là giai đoạn sau và phải cấp quyền rõ |
| iOS | AlarmKit iOS 26+ qua native Swift; OS vẫn có nút Dừng; bản iOS cũ chỉ được gọi là nhắc ôn nếu dùng notification; xem docs/20 |
| Đấu trường | Opt-in, giao hữu trước; bảng tuần và ELO là giai đoạn sau khi đạt cổng chất lượng; xem docs/21 |
| Linh thú | Cosmetic, có thể tắt, không phạt hình ảnh khi nghỉ/sai; xem docs/22 |

## Các điểm còn mở phải quyết định trước khi triển khai rộng

- Quy chế DevFest về phần được chuẩn bị trước và hạn nộp, xem [kế hoạch thi](02-ke-hoach-thi-va-demo.md).
- Độ tuổi tối thiểu và quy trình đồng ý của phụ huynh theo thị trường phát hành; cần rà soát trước pilot với người chưa thành niên.
- Thiết bị Android/API level tối thiểu, mục tiêu phát hành Google Play và ngân sách Gemini/Cloud Run.
- Bộ câu hỏi có bản quyền hợp lệ, người duyệt chuyên môn và phạm vi chương trình học.

## Nguyên tắc quản lý thay đổi

PRD là nguồn chuẩn cho **hành vi sản phẩm**, hợp đồng API là nguồn chuẩn cho **giao tiếp**, mô hình dữ liệu là nguồn chuẩn cho **lưu trữ**, kế hoạch kiểm thử là nguồn chuẩn cho **điều kiện phát hành**. Khi thay đổi một quy tắc, cập nhật các tài liệu liên quan trong cùng lần sửa. Không ghi một tính năng “đã có” chỉ vì nó xuất hiện trong tài liệu.

