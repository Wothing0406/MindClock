# MindClock

**MindClock** là ý tưởng ứng dụng học tập tiếng Việt kết hợp báo thức buổi sáng, ôn tập chủ động theo thời khóa biểu và sân đấu giải bài 1v1. Trọng tâm là giúp học sinh bắt đầu ngày học bằng một câu hỏi phù hợp, trình bày cách làm, rồi xem lại phần chưa chắc. Trò chơi là lớp động lực tùy chọn; báo thức và học tập vẫn phải dùng được độc lập.

> **Trạng thái repo (12/11/2026):** tài liệu sản phẩm và các bản xem thử web cục bộ. Chưa có APK Android, app iOS, backend, AI chấm thật, ghép trận online, điểm rank hay báo thức hệ thống đang chạy. Các số combat là giả thuyết để thử nghiệm.

## Vấn đề và hướng giải quyết

- Báo thức dễ bị tắt rồi ngủ tiếp. MindClock dự kiến đặt câu hỏi ngắn gắn với lịch học hôm đó; **Dừng khẩn cấp luôn dừng âm/rung ngay**, kể cả mất mạng. Không khóa điện thoại hay ngăn gỡ ứng dụng.
- Người học có thể thấy mình hiểu bài khi chỉ đọc lời giải AI. Sản phẩm yêu cầu người học tự trả lời và trình bày; Gemini dự kiến đọc/chấm/gợi ý sau khi nộp. Kết quả không chắc phải được xem lại, không phạt.
- Thời khóa biểu, mục tiêu môn học và lịch tự học được dùng để chọn nội dung đã duyệt, nhắc việc cần làm và xem tiến độ theo chuyên đề.
- Sân đấu 1v1 dự kiến cho hai học sinh cùng môn, lớp và chương trình, cùng một câu và rubric. Server chốt bài làm, hiệu ứng và rank; game không đổi độ khó bài của đối thủ.

Điểm cần kiểm chứng là liệu một câu khởi động sát lịch học có giúp người học tỉnh và nhớ bài hơn, và liệu hình thức nhập vai có tạo động lực mà không lấn mục tiêu học. [Nhu cầu và cách kiểm chứng](docs/41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md) ghi các giả thuyết và thước đo.

## Chức năng sản phẩm dự kiến

| Mảng | Người học có thể làm gì | Nguyên tắc |
| --- | --- | --- |
| **Đồng hồ & báo thức** | Đặt nhiều giờ, ngày lặp, âm/rung; chọn báo thức thường hoặc thử thách; thử chuông, xem lần reo kế tiếp, gợi ý giờ dậy từ lịch học và thời gian chuẩn bị/di chuyển | Chuông, Hoãn của chế độ thường và **Dừng khẩn cấp** chạy trên máy kể cả offline; thử thách không có Hoãn; người dùng xác nhận mọi giờ AI đề xuất. [Luồng chi tiết](docs/31-bao-thuc-thu-thach.md) |
| **Thời khóa biểu & việc hôm nay** | Nhập nhiều môn, tổ hợp/mục tiêu thi, tiết học, bài cần làm; nhận nhắc lịch vừa đủ; điều chỉnh ưu tiên cá nhân | Chỉ dùng dữ liệu người học đã xác nhận; AI đề xuất chia việc, không tự đặt báo thức hay gửi nhắc. [Hồ sơ học tập](docs/32-ho-so-hoc-tap-va-nhieu-mon.md) |
| **Câu hỏi buổi sáng** | Làm câu ngắn từ ngân hàng duyệt, nhập đáp án và một bước giải bằng chữ hoặc ảnh giấy; xem phản hồi, thử lại và ôn điểm yếu | AI có `correct/incorrect/uncertain`, không tự phạt hoặc gắn nhãn gian lận. Ảnh không lưu mặc định; có cách làm không cần camera. [Chấm bài](docs/39-bai-lam-co-trinh-bay-va-cham-cong-bang.md) |
| **Không gian học** | Chọn một việc, đặt phiên 10/25/45 phút hoặc tùy chỉnh, nghỉ/kết thúc, ghi một dòng đã làm; có mức tập trung tự chọn | Timer chạy cục bộ; rời app không bị phạt/khóa điện thoại. Camera/mic tắt mặc định. [Đặc tả](docs/45-khong-gian-hoc-va-che-do-tap-trung.md) |
| **Trợ lý MindClock** | Hỏi bài bằng chữ, nhận một gợi ý từng bước hoặc câu hỏi gợi mở; xem lại chỗ vướng | Trợ lý không đưa lời giải cuối trước khi người học tự làm trong luồng Socratic; không tự quyết điểm, rank hay lịch. Giọng nói/camera chỉ là tùy chọn có chi phí và quyền riêng. [Quy định AI](docs/14-vai-tro-va-quy-dinh-ai.md) |
| **Sân luyện & đấu trường** | Chọn tướng, xem chiêu, thử trận mẫu; sau này giao hữu cùng môn/chương trình, rồi mới mở ranked khi đạt cổng chất lượng | Cùng câu/rubric cho hai bên; server chốt kết quả; giờ dậy không ảnh hưởng rank. [Luật PvP](docs/46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) |
| **Hồ sơ** | Chọn avatar có sẵn hoặc ảnh tự tải lên, khung trang trí, xem huy hiệu hạng, lịch sử trận và lịch sử báo thức của mình | Badge khác khung; ảnh công khai cần duyệt; lịch sử giờ dậy riêng tư. [Hồ sơ](docs/52-ho-so-avatar-huy-hieu-va-lich-su.md), [ngôn từ](docs/53-quy-dinh-ten-avatar-va-noi-dung-nguoi-dung.md) |

**Điểm mới đang thử nghiệm:** nối lịch học đã xác nhận với một câu truy hồi ngắn ngay sau chuông, yêu cầu trình bày thay vì chỉ chọn đáp án, rồi dùng cùng nguồn câu/rubric cho đấu trường. Đây là giả thuyết thiết kế, chưa phải hiệu quả học tập đã được chứng minh.

## Xem thử miễn phí

1. Cài Python 3 nếu máy chưa có, mở terminal ở gốc repo và chạy `python -m http.server 8000`.
2. Mở `http://localhost:8000/demo/index.html` để xem các màn sản phẩm.
3. Trên máy tính, mở `http://localhost:8000/demo/arena.html`. Trên điện thoại cùng Wi-Fi, dùng địa chỉ IP nội bộ của máy tính thay `localhost` (ví dụ `http://192.168.x.x:8000/demo/arena.html`; cho phép truy cập qua tường lửa nếu được hỏi). Chọn một trong ba nhân vật, trả lời câu mẫu, viết một bước làm, rồi chọn Đánh thường hoặc chiêu có đủ khí. Nút trạng thái cho xem trúng đòn, choáng, hồi phục và thắng. Âm thanh mặc định tắt.

Sân luyện chạy cục bộ bằng câu mẫu và đối thủ theo kịch bản, **không phải PvP hay chấm trình bày thật**. Chủ dự án đã xác nhận quyền đăng công khai sprite nghiên cứu lên GitHub; quyền dùng thương mại cần rà trước phát hành ứng dụng. Không đưa ảnh học sinh thật vào demo AI.

## Ba nhân vật sân luyện

| Nhân vật | Vai | Cách chơi | Giới hạn |
| --- | --- | --- | --- |
| Hà Nhân | Đấu sĩ bền bỉ | Giữ chuỗi đúng để hồi giáp | Ít sát thương dồn |
| Hàn Bối Pháp | Hộ pháp phòng thủ | Chắn đòn và hồi giáp | Khó kết trận sớm |
| Tuyệt Đỉnh | Kiếm sĩ sát thương | Tích Kiếm Ý và chọn thời điểm ra chiêu | Ít hồi phục |

Mỗi tướng bắt đầu 100 HP, 50 giáp trong luật thử nghiệm. [Thông số và quy tắc PvP dự kiến](docs/46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) phân biệt luật server với mô phỏng cục bộ. [Bố cục sân dọc và asset](docs/51-san-dau-doc-mobile-va-hieu-ung.md) mô tả cách thể hiện trên điện thoại.

## Kiến trúc dự kiến

| Phần | Chọn lựa | Trạng thái |
| --- | --- | --- |
| Android | Flutter + phần báo thức native Kotlin | Đặc tả, chưa có app |
| iOS | Giai đoạn sau; tuân theo giới hạn hệ thống iOS | Đặc tả |
| Backend | FastAPI + PostgreSQL, xác thực Firebase ID token | Đặc tả SQL/API |
| AI | Gemini hỗ trợ đọc bài, gợi ý Socratic và đề xuất chấm theo rubric | Chưa tích hợp |
| Web demo | HTML/CSS/JS và asset 2D cục bộ | Có bản xem thử |

Không để client tự quyết XP, rank, chấm gian lận hoặc ghi ví. Không dùng bộ đề công khai khi chưa có quyền ở cấp nguồn và câu hỏi. [Kiến trúc và dữ liệu](docs/06-kien-truc-va-du-lieu.md), [API/AI](docs/07-hop-dong-api-va-ai.md), [SQL](docs/28-backend-sql.md) là nguồn triển khai.

## Tìm tài liệu và bắt đầu làm việc

- [Chỉ mục tài liệu](docs/README.md): nguồn chuẩn theo từng chức năng.
- [PRD](docs/04-prd-va-dac-ta-san-pham.md), [lộ trình](docs/08-ke-hoach-trien-khai.md), [30% chuẩn bị](docs/29-ke-hoach-chuan-bi-30-phan-tram.md).
- [Cấu trúc repo và quy trình asset](docs/50-cau-truc-du-an-va-asset-game.md), [hướng dẫn Android demo](docs/47-demo-android-va-moi-truong-kiem-thu.md).
- [Hướng dẫn agent](AGENTS.md), [quy trình task](tasks/README.md). Trước mọi thay đổi code/UI/cấu hình, tạo task có spec, plan và tests rồi mới sửa.

## Phạm vi an toàn và quyền dữ liệu

Người dùng có đường trả lời không cần camera, có quyền dừng báo thức khẩn cấp và xóa tài khoản theo [docs/24](docs/24-dang-ky-va-quan-ly-tai-khoan.md) và [docs/25](docs/25-bao-mat-va-du-lieu.md). Ảnh bài làm không lưu mặc định; câu trả lời AI `uncertain` phải có đường xem lại. Tài sản nhân vật được cho phép đăng công khai ở repo này, nhưng cần rà giấy phép thương mại/nhận diện trước khi phát hành ứng dụng.
