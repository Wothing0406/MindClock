# Hướng dẫn làm việc trong repo MindClock

## Đọc tài liệu theo việc đang làm

Đọc `docs/README.md` để tìm nguồn chuẩn, rồi chỉ đọc tài liệu liên quan đến task. Hành vi sản phẩm: `docs/04-prd-va-dac-ta-san-pham.md`, nhu cầu học sinh `docs/41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md`; UI: `docs/05-ux-va-noi-dung-tieng-viet.md`, `docs/13-he-thiet-ke-ui.md`, `docs/23-hanh-trinh-san-pham.md`, `docs/27-quy-chuan-giao-dien-va-figma.md`; dữ liệu/API: `docs/06-kien-truc-va-du-lieu.md`, `docs/07-hop-dong-api-va-ai.md`, `docs/17-workflow-va-vong-doi-du-lieu.md`, `docs/18-huong-dan-tich-hop-api.md`, `docs/28-backend-sql.md`; iOS: `docs/20-ios-demo-va-phat-hanh.md`; đấu trường: `docs/21-dau-truong-xep-hang.md`, luật ở `docs/35–40`; nhân vật: `docs/22-nhan-vat-rpg.md`; AI: `docs/14-vai-tro-va-quy-dinh-ai.md`; kiểm thử: `docs/09-ke-hoach-kiem-thu.md`, ma trận giao việc `docs/42-ma-tran-yeu-cau-va-giao-viec.md`; bàn giao: `docs/10-to-chuc-coding-agent.md`; skill: `docs/16-lua-chon-skills-cho-du-an.md`. Một sửa lỗi nhỏ không cần đọc toàn bộ bộ docs.

**Tài liệu ưu tiên khi bắt đầu coding:** [docs/06](docs/06-kien-truc-va-du-lieu.md) và [docs/28](docs/28-backend-sql.md) chốt PostgreSQL cho nghiệp vụ; [docs/29](docs/29-ke-hoach-chuan-bi-30-phan-tram.md) định nghĩa lát cắt 30%; [docs/30](docs/30-ngon-ngu-va-tai-san-giao-dien.md) chốt ngôn ngữ và asset không emoji. Không xây nghiệp vụ Firestore.

**Luồng báo thức/học tập:** [docs/31](docs/31-bao-thuc-thu-thach.md) quy định chế độ thử thách không Hoãn, chỉ gợi ý từ sai rõ lần 3 và luôn Dừng khẩn cấp; [docs/32](docs/32-ho-so-hoc-tap-va-nhieu-mon.md) quy định cá nhân hóa nhiều môn/mục tiêu thi. Hoãn chỉ áp dụng chế độ thường; Dừng khẩn cấp một chạm dừng âm/rung ngay.

**Solo 1v1:** [docs/46](docs/46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) là nguồn chuẩn luật combat/UI/networking **v0.1 thử nghiệm**; [docs/35](docs/35-solo-rpg-dong-bo-va-ky-nang.md) giữ ghép cùng nội dung và nguyên tắc đồng bộ không mâu thuẫn docs/46; [docs/37](docs/37-kinh-te-rank-va-nhan-vat-2d.md) là nguồn chuẩn kinh tế/RP, nhưng kit/HP cũ đã hủy; [docs/36](docs/36-diem-khac-biet-hai-huoc-gemini-va-hieu-nang.md) là nguồn chuẩn model thử nghiệm/humor/tốc độ; [docs/34](docs/34-ngan-hang-cau-hoi-da-mon.md) và [docs/38](docs/38-nguon-du-lieu-va-duong-nhap-cau-hoi.md) là nguồn chuẩn câu/nguồn dữ liệu. Docs/33 và combat docs/40 là phương án cũ; docs/21 chỉ chốt hành trình xã hội và bảng.

**Nhân vật/khung/bảng khi mở M3:** [docs/43](docs/43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md) là nguồn thiết kế từng nhân vật, avatar, 6 tier khung và màn bảng; [docs/44](docs/44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md) là hợp đồng backend/test. `rank_ledger` là tên duy nhất cho RP/MMR; không tạo thêm `rating_ledger`. Đây là đặc tả giai đoạn sau, chưa có màn/API chạy thật.
**Cập nhật roster 12/11/2026:** nhân vật/kit cũ ở docs/22, 35, 37, 40, 43 đã bị hủy; không dùng ID, tên, artwork hoặc số combat cũ để code. Docs/43 giữ khung rank/bảng và ô chọn concept mới; docs/44 là bản thiết kế backend có phần catalog **chưa mở**. Luật 100 HP/50 giáp ở docs/46 là bản v0.1 để prototype/playtest, chưa chứng minh cân bằng. Không gian học ở [docs/45](docs/45-khong-gian-hoc-va-che-do-tap-trung.md) là nguồn chuẩn timer, nhắc khi rời app và AI học tập. App thường không được hứa khóa app khác.
**Cập nhật PvP:** [docs/46](docs/46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) là nguồn chuẩn **v0.1 thử nghiệm** cho ba working names, 100 HP/50 giáp, 6 round, khí lực, kit, action UI, asset và networking. Nó thay toàn bộ số combat/thẻ cũ trong docs/35/37/40; docs/35 chỉ còn nguồn ghép cùng nội dung và nguyên tắc đồng bộ. Không code ranked/cửa hàng khi chưa qua cổng chấm/balance/quyền ở docs/39,46. Tên/hình phải là bản gốc, không sao chép phim.

**Skill Android/Flutter:** khi code Kotlin/Manifest/MethodChannel hoặc quyền, báo thức, vòng đời Android, đọc `.agents/skills/mindclock-android-native/SKILL.md`; khi thiết lập test module Kotlin native có thể dùng `testing-setup`, còn UI/hành trình Flutter dùng `flutter-add-widget-test`/`flutter-add-integration-test`. Xem [docs/16](docs/16-lua-chon-skills-cho-du-an.md). Không để skill chung tự thêm Hilt/Compose hoặc Flutter Driver extension vào app Flutter khi chưa có lý do và đối chiếu tài liệu hiện hành.

**Demo nền tảng:** [docs/47](docs/47-demo-android-va-moi-truong-kiem-thu.md) là runbook Android duy nhất cho cuộc thi; [docs/20](docs/20-ios-demo-va-phat-hanh.md) là lộ trình iOS tương lai, không thuộc demo. Repo chưa có Flutter app/APK; không nói `flutter run`, alarm, Gemini hoặc PvP đã chạy chỉ vì docs có lệnh/kịch bản.
**Kiểm toán docs:** [docs/48](docs/48-kiem-toan-docs-va-dieu-kien-bat-dau-code.md) ghi rõ vùng đủ để mở task Android P0 và các cổng chưa đạt. Không gắn `done` sản phẩm từ checklist tài liệu.

## Quy tắc không được phá

- Báo thức và Dừng khẩn cấp chạy trên thiết bị kể cả khi không có mạng/API/đăng nhập; không khóa người dùng trong thử thách. Chế độ thử thách không có Hoãn; nếu còn chế độ thường thì Hoãn của chế độ đó cũng chạy cục bộ.
- AI không được tự quyết XP, streak, rank hoặc gán nhãn gian lận. Chấm có `correct`, `incorrect`, `uncertain`; sai/không chắc không bị phạt.
- Câu hỏi MVP đến từ ngân hàng đã duyệt; Gemini hỗ trợ đọc/chấm/gợi ý. Không gửi API key tới client.
- Không nạp/công bố corpus ngoài khi chưa có quyền từng nguồn/item và người duyệt. `data/sources/registry.json` chỉ là metadata, không có câu hỏi đã tích hợp. Không tự coi repo công khai/MIT của mã là quyền dùng mọi đề/ảnh.
- Không lưu ảnh bài làm mặc định và không ghi ảnh, token, lời giải cá nhân vào log.
- Client không ghi điểm/tiến độ có thẩm quyền. Backend xác minh Firebase ID token, kiểm tra quyền, dùng idempotency cho phiên/attempt/XP.
- Giao diện tiếng Việt `vi-VN`, ngôn ngữ khích lệ, có đường nhập đáp án thay camera.
- UI và prototype không dùng emoji hệ thống, câu quảng cáo/phóng đại hoặc khẩu hiệu trong màn dùng hằng ngày; dùng icon vector và câu ngắn theo docs/30.
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
- Bảo mật mặc định deny-all; chỉ mở quyền API/SQL cần thiết, có test truy cập chéo tài khoản.
- Linh thú, ví/coin/RP, dashboard và iOS đã có **đặc tả** nhưng chưa tự động thuộc MVP; chỉ code khi task/giai đoạn yêu cầu rõ. Giao hữu trước ranked. Không bán sức mạnh/coin bằng tiền thật hoặc để client tự ghi ví/RP.
- Kết thúc task bằng bản bàn giao theo `docs/10-to-chuc-coding-agent.md` §4.

## Trạng thái repo

Tại thời điểm tạo hướng dẫn, repo mới có tài liệu. Các đường dẫn code trong kế hoạch là dự kiến; không suy ra code đã tồn tại.

