# MindClock

MindClock là ứng dụng học tập tiếng Việt cho Android: đặt báo thức, bắt đầu buổi sáng bằng câu hỏi phù hợp thời khóa biểu, tự trình bày cách làm và xem lại phần chưa chắc. Không gian học có đồng hồ tập trung và trợ lý gợi mở. Đấu trường nhân vật là nhánh phát triển sau, không quyết định tính năng báo thức.

## Trạng thái hiện tại — 15/11/2026

Repo **đã có mã Flutter/Android native và FastAPI/Alembic**. Backend có API `/v1`, SQLAlchemy và tích hợp Gemini từ server; app có luồng khách, lịch học, báo thức local, luyện tập và không gian học. Điều này **chưa đồng nghĩa sản phẩm sẵn sàng phát hành**: các task T014–T021 còn thiếu bằng chứng build Flutter trên máy hiện tại, vòng báo thức trên Android thật, PostgreSQL/Firebase production, kiểm định chấm AI và thử nghiệm người dùng. Đọc [baseline và cổng release](docs/56-baseline-san-pham-android.md) trước khi giao task coding.

Hai thư mục web tĩnh `demo/` và `demo_video/` đã được loại bỏ. Mã web thử nghiệm `/demo` và `/product` còn trong FastAPI do T022/T023 đang làm dở; đó **không phải client sản phẩm**. Các màn mới phải được xây trong Flutter `app/`. Tài sản game nghiên cứu được giữ ở `assets/game/`, chưa đóng gói vào APK.

## Chức năng và thứ tự triển khai

| Phần | Hành vi cần đạt | Tình trạng |
| --- | --- | --- |
| Đồng hồ & báo thức | Đặt nhiều giờ/ngày lặp/âm/rung; chế độ thường hoặc thử thách; Dừng khẩn cấp một chạm kể cả offline; không Hoãn trong thử thách | Có mã Flutter/Kotlin; cần kiểm AD01–AD09 trên máy Android thật |
| Thời khóa biểu & câu sáng | Chọn lớp, môn/tổ hợp, lịch học; câu từ ngân hàng duyệt; nhập đáp án và trình bày chữ, camera tùy chọn | Có mã luồng cá nhân/API; cần xác nhận end-to-end và chất lượng nội dung |
| Chấm & trợ lý AI | Đọc bài/gợi ý theo Socratic; `correct`, `incorrect`, `uncertain`; backend chốt XP | Có gateway/API; cần bộ đánh giá chấm, consent, timeout và kiểm bảo mật |
| Không gian học | Timer local, việc đang học, hỏi gợi ý; rời app không bị phạt hoặc khóa điện thoại | Có mã Flutter/API; cần test lifecycle và máy thật |
| Hồ sơ & tài khoản | Khách dùng offline; đăng nhập để đồng bộ và xem tiến độ; quyền xóa dữ liệu | Có mã; cần Firebase/PostgreSQL thực và test truy cập chéo |
| Sân đấu/rank | Giao hữu hai máy cùng câu/rubric trước; rank sau khi chất lượng/cân bằng đạt | Chỉ có luật/asset nghiên cứu, chưa có PvP online |

Sản phẩm không khóa điện thoại hoặc ngăn gỡ app. AI không tự cấp điểm, trừ uy tín vì sai, hay kết luận gian lận. Bài không chắc được xem lại; ảnh bài làm không lưu mặc định. [PRD](docs/04-prd-va-dac-ta-san-pham.md) và [quy định dữ liệu](docs/25-bao-mat-va-du-lieu.md) là nguồn chi tiết.

## Cấu trúc và bắt đầu phát triển

- [`app/`](app/): Flutter Android; phần báo thức native ở `app/android/`.
- [`services/api/`](services/api/): FastAPI, auth, SQLAlchemy, Alembic và test.
- [`assets/game/`](assets/game/): art/FX/audio/map nghiên cứu, chưa vào app release.
- [`docs/`](docs/README.md): tài liệu chuẩn và lịch sử thiết kế; [cấu trúc repo](docs/57-cau-truc-repo-production.md) giải thích chỗ đặt file.
- [`tasks/`](tasks/README.md): task có spec, plan, test, worklog, handoff trước/sau code.

Để chạy phát triển, cần Flutter/Android SDK hợp lệ và Python 3.11+; cấu hình từ `app/.env.example` và `services/api/.env.example`, giữ `.env` local ngoài Git. Chạy `flutter pub get`, `flutter analyze`, `flutter test` trong `app/`; chạy `python -m pytest` trong `services/api/` với virtualenv/requirements. PostgreSQL dùng cho staging/production, SQLite chỉ cho local một máy. Các lệnh là **cách kiểm**, không phải bằng chứng đã pass trên máy của bạn. Xem [runbook Android](docs/47-demo-android-va-moi-truong-kiem-thu.md) và [baseline](docs/56-baseline-san-pham-android.md) để biết cổng thiết bị thật.

AI coding phải đọc [AGENTS.md](AGENTS.md), [chỉ mục docs](docs/README.md) và task liên quan; tạo hoặc tiếp tục `tasks/TNNN-*` trước mọi sửa code/UI/config. Không biến yêu cầu app Android thành một trang web mô phỏng. Thứ tự ưu tiên hiện tại: build/test lặp lại được → báo thức an toàn trên máy thật → câu hỏi và chấm có kiểm định → tài khoản/đồng bộ → không gian học → giao hữu/rank.
