# MindClock — bộ tài liệu triển khai

**Trạng thái:** đặc tả để bắt đầu coding, chưa có sản phẩm chạy. **Ngôn ngữ giao diện:** tiếng Việt. **Nền tảng đầu tiên:** Android; iOS và đấu trường có kế hoạch triển khai riêng. **Mốc tài liệu:** 12/11/2026.

**Quy trình khi bắt đầu coding:** đọc [AGENTS.md](../AGENTS.md) và [tasks/README.md](../tasks/README.md); mỗi yêu cầu code có thư mục task riêng với spec, plan, test và điểm tiếp tục.

## Thứ tự đọc

1. [01 — Tầm nhìn và ý tưởng ban đầu](01-dinh-huong-san-pham.md): bối cảnh DevFest, giả thuyết và phạm vi demo.
2. [04 — PRD và đặc tả sản phẩm](04-prd-va-dac-ta-san-pham.md): mục tiêu, persona, user stories, quy tắc nghiệp vụ, MVP và lộ trình đầy đủ.
3. [05 — UX và nội dung tiếng Việt](05-ux-va-noi-dung-tieng-viet.md): bản đồ màn hình, hành trình, nhãn, thông báo, trạng thái lỗi.
4. [06 — Kiến trúc và dữ liệu](06-kien-truc-va-du-lieu.md): nền tảng, báo thức local, PostgreSQL, trạng thái và quyền truy cập.
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
16. [18 — Hướng dẫn tích hợp API](18-huong-dan-tich-hop-api.md): cách mobile gọi backend, backend dùng SQL/Gemini, lỗi và fixture.
17. [02 — Kế hoạch thi và demo](02-ke-hoach-thi-va-demo.md), [03 — Nghiên cứu và kiểm chứng](03-nghien-cuu-va-kiem-chung.md): tài liệu cuộc thi và nguồn tham khảo; không thay thế PRD/API mới.
18. [19 — Kiểm toán khoảng trống](19-kiem-toan-khoang-trong.md): việc chưa thể giải quyết bằng docs, người phụ trách và cổng quyết định.
19. [20 — iOS và demo](20-ios-demo-va-phat-hanh.md): AlarmKit, ba mức demo, checklist Mac/Xcode/TestFlight và tiêu chí máy thật.
20. [21 — Đấu trường và bảng xếp hạng](21-dau-truong-xep-hang.md): hành trình xã hội, opt-in, bảng/nhóm và cổng mở; luật trận hiện hành ở docs/35–40.
21. [22 — Linh thú RPG](22-nhan-vat-rpg.md): phong cách nhân vật, trạng thái, asset spec và brief họa sĩ.
22. [23 — Hành trình sản phẩm](23-hanh-trinh-san-pham.md): chọn app/tab, onboarding, rank, trận và các trạng thái UI tiếng Việt.
23. [24 — Đăng ký và tài khoản](24-dang-ky-va-quan-ly-tai-khoan.md): khách dùng thử, email/mật khẩu, xác minh, đồng ý thi đấu, xóa tài khoản.
24. [25 — Bảo mật và dữ liệu](25-bao-mat-va-du-lieu.md): mục đích thu thập, quyền, thời hạn, ảnh AI, rút đồng ý, sự cố.
25. [26 — Công cụ miễn phí và demo](26-bo-cong-cu-mien-phi-va-kich-ban-demo.md): mỗi vai cần cài gì, phương án 0 đồng và kịch bản giám khảo.
26. [27 — Quy chuẩn giao diện và Figma](27-quy-chuan-giao-dien-va-figma.md): phong cách tối giản, icon, thao tác, sprite 2D, khung rank, animation và bàn giao thiết kế.
27. [28 — Backend SQL](28-backend-sql.md): PostgreSQL đích, SQLite demo, bảng, ràng buộc và transaction.
28. [29 — Làm trước 30% sản phẩm](29-ke-hoach-chuan-bi-30-phan-tram.md): lát cắt app/API chạy được, phần để lại và prompt giao AI coding.
29. [30 — Ngôn ngữ và asset](30-ngon-ngu-va-tai-san-giao-dien.md): chữ ngắn, không quảng cáo, không emoji, lựa chọn icon/animation.
30. [31 — Báo thức thử thách](31-bao-thuc-thu-thach.md): chế độ không Hoãn, gợi ý sau nhiều lần sai, Dừng khẩn cấp, giới hạn chống giải hộ.
31. [32 — Hồ sơ nhiều môn](32-ho-so-hoc-tap-va-nhieu-mon.md): môn/tổ hợp người dùng chọn, chọn câu theo lịch, dạng chấm theo môn, nhắc lịch/task và dữ liệu SQL.
32. [33 — Solo 1v1 v1 (lưu trữ)](33-dau-truong-solo-ranked-gdd.md): luật đếm câu đúng cũ; không dùng để coding trận mới.
33. [34 — Ngân hàng câu đa môn](34-ngan-hang-cau-hoi-da-mon.md): taxonomy, dạng câu theo môn, tiếng Việt/đáp án/gợi ý, quy trình duyệt và schema revision.
34. [35 — Solo RPG v2](35-solo-rpg-dong-bo-va-ky-nang.md): **nguồn chuẩn luật trận hiện hành** — HP, kỹ năng, ghép cùng nội dung, đồng bộ, API/SQL và test.
35. [36 — Khác biệt, humor, Gemini, tốc độ](36-diem-khac-biet-hai-huoc-gemini-va-hieu-nang.md): đối chiếu ý tưởng, giọng vui/asset, chọn model thử nghiệm và ngân sách hiệu năng.
36. [37 — Đồng Mực, bậc hạng và nhân vật 2D](37-kinh-te-rank-va-nhan-vat-2d.md): **nguồn chuẩn kinh tế game**, ba kit kỹ năng, RP Đồng 1–Tinh Anh 5, ví/ledger và sprite asset.
37. [38 — Nguồn dữ liệu và nhập câu](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md): VNHSGE/mirror VMLU đã tải nghiên cứu local, ViMMRC chưa tải, quyền sử dụng và pipeline duyệt. [Registry](../data/sources/registry.json) và [manifest](../data/research/research-manifest.json) chỉ chứa metadata.
38. [39 — Bài làm có trình bày và chấm công bằng](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md): yêu cầu giải thích ngắn mọi môn, ba kết quả, rubric/AI/validator, cổng ranked và độ khó ngày đầu.
39. [40 — PvP, nhân vật và bản đồ](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md): hồi/hút/choáng, bốn nhân vật người/động vật, map/FX 2D, công thức HP và nội dung vui chuẩn mực.
40. [41 — Nhu cầu học sinh](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md): tình huống thật, yêu cầu U01–U10, hành trình ngày đầu/offline/ngày nghỉ và cách thử với người học.
41. [42 — Ma trận giao việc](42-ma-tran-yeu-cau-va-giao-viec.md): nối nhu cầu → đặc tả → test → giai đoạn/chủ trì để mở task coding.
42. [43 — Thiết kế nhân vật, avatar, khung và bảng](43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md): bốn character brief cụ thể, sáu khung RP, bốn màn đấu trường và trạng thái Figma/Flutter.
43. [44 — Backend nhân vật, rank và bảng](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md): bảng SQL, workflow starter/mua/settle/opt-out, API dự kiến và test BR01–BR14.

## Quyết định đã chốt để coding

| Chủ đề | Quyết định |
| --- | --- |
| Bản đầu | Flutter cho Android, FastAPI backend, SQLite chỉ cho demo một máy/PostgreSQL đích; Firebase Authentication cho tài khoản online; Gemini chỉ được gọi từ backend. Xem docs/06 và 28 |
| Báo thức | Lập lịch/phát/dừng tại thiết bị; khách không cần đăng nhập; có câu dự phòng offline nhưng bài tự do offline không tự chấm; không phụ thuộc API lúc chuông reo |
| Câu hỏi | Ngân hàng câu đã duyệt cho MVP; mọi câu có chấm cần đáp án + cách làm ngắn/rubric; AI hỗ trợ đọc/chấm/gợi ý, xem docs/39 |
| Ảnh | Gửi qua backend, xử lý tạm thời, không lưu ảnh mặc định |
| Chấm | `correct`, `incorrect`, `uncertain`; AI không kết luận gian lận |
| Điểm | XP ghi ở server theo attempt/sự kiện đủ điều kiện; metadata offline riêng không tự cấp XP; không trừ điểm vì sai bài, hoãn hoặc tắt khẩn cấp |
| Quyền riêng tư | Hồ sơ học tập cá nhân mặc định; giáo viên/phụ huynh là giai đoạn sau và phải cấp quyền rõ |
| iOS | AlarmKit iOS 26+ qua native Swift; OS vẫn có nút Dừng; bản iOS cũ chỉ được gọi là nhắc ôn nếu dùng notification; xem docs/20 |
| Đấu trường | Opt-in, giao hữu trước; ranked/RP/bảng là giai đoạn sau khi đạt cổng chất lượng; xem docs/35 và 37 |
| Nhân vật | Sprite 2D, chọn một trong bốn nhân vật miễn phí, nhân vật còn lại mở bằng Đồng Mực; kỹ năng riêng phải cân bằng trước ranked, không phạt hình ảnh khi nghỉ/sai; xem docs/22,37,40,43–44 |
| Báo thức thử thách | Tự chọn; không Hoãn, chỉ gợi ý sau sai rõ lần 3, luôn Dừng khẩn cấp; xem docs/31 |
| Cá nhân hóa môn | Chọn nhiều môn và mục tiêu thi, câu từ bộ đã duyệt phù hợp từng môn; xem docs/32 |
| Solo RPG | Giao hữu trước; 60 HP/3 vòng, chọn 2/4 thẻ chung + thẻ nhân vật, hồi/hút/choáng; Gemini chỉ đề xuất chấm **sau nộp**, không sinh đề trực tiếp; ranked tắt đến khi chấm/cân bằng đạt cổng. Xem docs/35, 39, 40 |
| Dữ liệu câu ngoài | VNHSGE và mirror VMLU đã tải **chỉ ở khu nghiên cứu local gitignored**, không có câu nào vào app; ViMMRC chỉ metadata. Câu demo do đội biên soạn/duyệt; xem docs/38 và [manifest](../data/research/research-manifest.json) |

## Các điểm còn mở phải quyết định trước khi triển khai rộng

- Quy chế DevFest về phần được chuẩn bị trước và hạn nộp, xem [kế hoạch thi](02-ke-hoach-thi-va-demo.md).
- Độ tuổi tối thiểu và quy trình đồng ý của phụ huynh theo thị trường phát hành; cần rà soát trước pilot với người chưa thành niên.
- Thiết bị Android/API level tối thiểu, mục tiêu phát hành Google Play và ngân sách Gemini/Cloud Run.
- Bộ câu hỏi có bản quyền hợp lệ, người duyệt chuyên môn và phạm vi chương trình học.

## Nguyên tắc quản lý thay đổi

PRD là nguồn chuẩn cho **hành vi sản phẩm**, hợp đồng API là nguồn chuẩn cho **giao tiếp**, mô hình dữ liệu là nguồn chuẩn cho **lưu trữ**, kế hoạch kiểm thử là nguồn chuẩn cho **điều kiện phát hành**. Khi thay đổi một quy tắc, cập nhật các tài liệu liên quan trong cùng lần sửa. Không ghi một tính năng “đã có” chỉ vì nó xuất hiện trong tài liệu.

