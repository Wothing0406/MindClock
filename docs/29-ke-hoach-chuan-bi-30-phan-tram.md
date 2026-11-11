# Làm trước 30% sản phẩm MindClock

**Cách hiểu:** 30% là một **lát cắt sản phẩm chạy được**, không phải 30% số màn hình hoặc 30% bộ docs. Làm trước những phần có thể kiểm tra và tái dùng trong ngày thi. Chưa thấy quy chế chính thức nêu rõ được mang bao nhiêu code làm trước trên [trang sự kiện GDG Miền Trung](https://gdg.community.dev/events/details/google-gdg-mientrung-presents-hackathon_gdg-devfest-mientrung-2026/); đội phải xác nhận với ban tổ chức. Nếu quy chế yêu cầu code được tạo trong thời gian thi, phần chạy sẵn chỉ dùng nội bộ để tập, không trình bày như tác phẩm làm tại cuộc thi.

## 1. 30% nên bao gồm gì?

| Phần sản phẩm | Làm trước đến mức nào | Bằng chứng hoàn thành |
| --- | --- | --- |
| Khung app mobile | Flutter mở được trên một máy Android; 4 tab `Hôm nay`, `Luyện tập`, `Đấu trường`, `Tôi`; icon SVG/vector, không emoji | APK/debug build hoặc chạy trên thiết bị; tab chuyển đúng |
| Luồng học cốt lõi | Một câu Toán lớp 9 đã duyệt, nhập đáp án, xem gợi ý và phản hồi **theo fixture** | Từ trang chủ đến kết quả trong ≤2 phút, ghi rõ dữ liệu mẫu |
| Báo thức demo | Chọn giờ và hiển thị giờ kế tiếp; mô phỏng sự kiện reo để diễn tập; nút `Dừng chuông` hoạt động trong luồng demo | Không gọi đó là báo thức OS nếu chưa test native trên máy thật |
| Backend SQL tối thiểu | FastAPI local + SQLite: `questions`, `users` demo (nếu cần), `alarm_sessions`, `attempts`; endpoint health, câu tiếp theo, nộp đáp án văn bản | Chạy local, có migration/seed và request mẫu; không cần hosting |
| Thiết kế và asset | Token UI, một bộ icon nhất quán, avatar SVG placeholder gốc; chưa cần 3D render | Figma/prototype hoặc app có màn thật; asset có licence |
| Kiểm thử/demo | 3 trường hợp đúng, sai, chưa rõ; lỗi mạng/mock; video dự phòng | Test ghi kết quả và kịch bản demo 3 phút |

**Phần lõi cần chạy thật:** mở app, điều hướng, hiển thị câu, nhập đáp án, phản hồi theo dữ liệu mẫu, API/SQLite local nếu đội đủ người. **Phần phải gắn nhãn mô phỏng:** chuông hệ thống chưa tích hợp, AI chưa gọi thật, bảng xếp hạng/thi đấu chưa nối server. Đây vẫn là sản phẩm dở dang có lát cắt hoạt động, không phải chỉ một bộ slide.

## 2. Để lại 70% cho các task sau

1. Native Android alarm chạy khi app đóng/màn khóa/offline và kiểm thử thiết bị thật.
2. Chụp ảnh bài viết tay, upload tạm, Gemini chấm `correct/incorrect/uncertain` với bộ ảnh kiểm chứng.
3. Auth thật, consent, đồng bộ SQLite demo sang PostgreSQL, XP ledger/idempotency hoàn chỉnh.
4. Giao hữu online hai máy, bảng tuần, nhóm; ELO chỉ sau cân bằng câu và chống nộp trùng.
5. Nhân vật 3D render thành asset nhẹ, khung rank, iOS AlarmKit, dashboard giáo viên/phụ huynh.

Lý do để lại: các phần này cần máy thật, kiểm thử quyền/dữ liệu hoặc backend ổn định. Không gom tất cả vào demo một buổi sáng rồi tuyên bố đã hoàn thiện.

## 3. Thứ tự giao AI để xây 30%

Tạo một task folder cho từng lát cắt theo [quy trình tasks](../tasks/README.md). Ưu tiên: `T003` khung Flutter và design tokens → `T004` câu Toán/fixture và luồng nhập đáp án → `T005` FastAPI + SQLite local → `T006` nối app/API và demo lỗi. ID chỉ là gợi ý; lấy ID kế tiếp thực tế trong repo. Mỗi task có spec, plan, tests, worklog, handoff; không báo xong nếu mới có ảnh chụp màn hình.

### Prompt giao AI chuẩn bị 30% sản phẩm

```text
Bạn là coding agent của MindClock. Mục tiêu là tạo lát cắt sản phẩm chạy được khoảng 30% để chuẩn bị DevFest, không phải chỉ viết tài liệu.

Đọc AGENTS.md, tasks/README.md, docs/README.md và các docs liên quan: 04 (PRD), 05/13/27/30 (UI và ngôn ngữ), 07 (API), 09 (test), 28 (backend SQL), 29 (phạm vi 30%). Kiểm tra repo thực tế trước khi sửa. Với mỗi lát cắt coding, tạo/tiếp tục task folder và điền spec.md, plan.md, tests.md trước khi code.

Xây theo thứ tự: (1) app Flutter Android mở được với 4 tab và icon vector không emoji; (2) luồng một câu Toán 9 đã duyệt, nhập đáp án, gợi ý và ba trạng thái phản hồi bằng fixture; (3) FastAPI + SQLite local có migration, seed câu mẫu, endpoint health/câu hỏi/nộp đáp án; (4) nối app tới API local nếu khả thi và giữ chế độ fixture khi API mất. UI tiếng Việt ngắn, rõ chức năng; không dùng khẩu hiệu trong màn. Không thêm ELO, chat, dashboard, 3D realtime, iOS hoặc thu dữ liệu học sinh thật.

Mỗi bước phải chạy app/test phù hợp, ghi lệnh và kết quả thật trong task/tests.md. Kiểm tra trên Android thật nếu có; nếu không có, nói rõ giới hạn emulator. Phần chuông/AI/thi online chưa chạy phải có nhãn mô phỏng ngay trong demo. Khi gặp lỗi, ghi vòng tái hiện → nguyên nhân → sửa → test lại; bàn giao điểm tiếp tục chính xác. Không tự đẩy code hoặc tuyên bố đã triển khai tính năng chưa kiểm chứng.
```

**Khi dùng prompt:** đội phải chốt trước quy chế cuộc thi về code làm sẵn. Nếu không được mang code trước, dùng prompt này để luyện tập nội bộ và tạo một kế hoạch tái tạo hợp lệ trong buổi thi; không dùng code làm trước để nộp trái quy chế.

## 4. Định nghĩa xong 30%

- Người khác clone repo, làm theo README và chạy được lát cắt trên máy/giả lập hỗ trợ.
- Có một hành trình từ trang chủ đến kết quả, nội dung Toán được duyệt, không có emoji hệ thống.
- API local và SQLite có migration/seed nếu đội chọn phần backend trong 30%; test nộp trùng và quyền ở mức demo.
- Mọi trạng thái mô phỏng được dán nhãn; không có API key hay dữ liệu thật trong repo.
- Có task records và video dự phòng; đội thuyết trình phân biệt rõ đã chạy/chưa chạy.

