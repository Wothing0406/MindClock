# MindClock

MindClock là sản phẩm Android tiếng Việt dành trước hết cho học sinh THPT: tạo hồ sơ học, lên lịch ngủ/học, đặt báo thức, làm một câu ôn có trình bày sau khi thức và học trong phòng một mình, cùng AI hoặc bạn bè. Đấu trường RPG 2D là nhánh tự nguyện sau khi luồng học tập và chấm bài đủ tin cậy. Dự án không còn được định nghĩa theo một cuộc thi hay bản demo.

## Trạng thái trung thực

Repo đã có mã **Flutter/Android Kotlin** trong [`app/`](app/), **FastAPI/SQLAlchemy/Alembic** trong [`services/api/`](services/api/) và art nghiên cứu ở [`assets/game/`](assets/game/). Chưa có bằng chứng hoàn tất build/release Android trên máy thật, PostgreSQL/Firebase production, đánh giá AI đa môn hoặc PvP online. Một số task còn `blocked`/`verifying`; web `/demo`, `/product` trong API là WIP nội bộ, không là client sản phẩm. Xem [hiện trạng có bằng chứng](docs/00-start/01-hien-trang.md).

## Chức năng theo sản phẩm đích

| Phần | Người dùng làm gì | Trạng thái |
| --- | --- | --- |
| Tài khoản/hồ sơ học | Đăng ký email, lớp 10–12, môn theo catalog, mức tự đánh giá, avatar, xem/sửa plan nháp | Có phần mã Auth/hồ sơ; flow mới cần triển khai/kiểm dọc |
| Đồng hồ và báo thức | Nhiều chuông, âm, vòng lịch ngủ, mode thường/thử thách, Dừng khẩn cấp offline; DND theo quyền OS | Có mã alarm, cần kiểm máy thật; sleep UI/DND còn đặc tả |
| Lịch học cá nhân | Nhập/upload TKB, xem việc hôm nay, nhắc opt-in và gợi giờ/câu/việc có xác nhận | Có phần mã, cần test dọc và mở rộng |
| Ôn tập và AI | Tự viết đáp án/bước làm; ảnh tùy chọn; chấm đúng/sai/chưa chắc và gợi mở | Có API/luồng, cần content và AI eval |
| Không gian học | Chọn solo/AI/bạn, môn/việc/nhịp, timer; giọng nói/avatar AI và phòng bạn theo cổng | Timer/API có phần mã; Live và phòng bạn chưa có production |
| Hồ sơ và dữ liệu | Xem tiến độ/lịch sử/rank/tiểu sử, kết bạn/mời học, quyền chia sẻ và xóa | Có phần mã; public profile/bạn bè cần task sau |
| Đấu trường RPG | Giao hữu cùng câu, tướng 2D, ranked theo môn/mùa khi đủ điều kiện | Đặc tả/art nghiên cứu; chưa có PvP live |

**Điểm sản phẩm cần kiểm chứng:** một câu ngắn theo môn hôm nay nối báo thức với học chủ động, người học trình bày cách làm trước khi nhận phản hồi, và phòng học tạo đủ động lực để họ quay lại. Chuông vẫn dừng được trong mọi trường hợp. Đây là giả thuyết cần thử người dùng, không phải tuyên bố hiệu quả đã chứng minh.

## Tài liệu để bắt đầu coding

1. [Chỉ mục nguồn chuẩn](docs/README.md): đọc theo task, không đọc archive để tự chọn luật.
2. [PRD](docs/01-product/01-prd.md), [onboarding](docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md), [phòng học](docs/01-product/08-phong-hoc-ai-va-ban-be.md), [lịch ngủ](docs/01-product/09-giac-ngu-va-bao-thuc.md): hành vi người dùng và ranh giới từng giai đoạn.
3. [Lộ trình](docs/00-start/02-lo-trinh.md) và [gói task đầu tiên](docs/00-start/05-goi-task-dau-tien.md): build/test → báo thức thật → câu/AI → đồng bộ → pilot → giao hữu.
4. [Quy trình vibe coding](docs/00-start/03-quy-trinh-vibe-code.md), [quy tắc skill](docs/00-start/07-quy-tac-skills-va-ai-agent.md) và [AGENTS.md](AGENTS.md): task có spec, plan, test, worklog, handoff trước/sau sửa mã.
5. [Kiến trúc](docs/02-engineering/01-kien-truc.md), [API](docs/02-engineering/04-hop-dong-api.md), [SQL](docs/02-engineering/03-du-lieu-sql.md), [test/release](docs/03-quality/01-ke-hoach-kiem-thu.md).

Tài liệu đánh số cũ được giữ ở [archive](docs/archive/README.md) để truy nguồn, **không là hướng dẫn coding hiện hành**.

## Cấu trúc và chạy phát triển

```text
app/              Flutter Android + Kotlin alarm/camera bridge
services/api/     FastAPI /v1 + PostgreSQL target + Alembic + tests
assets/game/      sprite/FX/audio/map nghiên cứu, chưa đóng gói release
docs/             nguồn chuẩn theo product/engineering/quality/game
tasks/            AC ↔ test và bàn giao từng thay đổi
```

Trên máy có Flutter/Android SDK hợp lệ: từ `app/` chạy `flutter pub get`, `flutter analyze`, `flutter test`; chạy trên thiết bị bằng `flutter run -d <deviceId>` sau khi cấu hình URL/Auth theo `app/.env.example`. Backend: tạo venv trong `services/api/`, cài `requirements.txt`, cấu hình từ `.env.example` (không commit `.env`), chạy `python -m pytest` và Alembic trên PostgreSQL test. Các lệnh là **cách kiểm**, không phải kết quả pass; ghi môi trường/lỗi thực vào task. [Runbook môi trường](docs/03-quality/04-moi-truong-chay-thu.md) và [cổng release](docs/03-quality/02-van-hanh-phat-hanh.md).

## Quy tắc quan trọng

Dừng khẩn cấp dừng âm/rung cục bộ dù mất mạng; thử thách không có Hoãn. AI không tự cấp XP/rank hoặc gán gian lận; `uncertain` không phạt. Câu hỏi scored phải được duyệt và có quyền. Ảnh bài làm không lưu mặc định; người dùng có đường nhập chữ không cần camera. PvP/ranked không dùng giờ dậy xếp hạng. Không gọi web prototype, storyboard hoặc art là app đã chạy. Chi tiết ở [PRD](docs/01-product/01-prd.md), [quyền riêng tư](docs/01-product/04-tai-khoan-quyen-rieng-tu.md) và [AGENTS.md](AGENTS.md).
