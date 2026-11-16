# Hiện trạng có bằng chứng

**Cập nhật 16/11/2026.** Tài liệu này phân biệt **có mã**, **đã kiểm trên môi trường phát triển** và **đủ điều kiện cho người dùng thật**. Chỉ cột cuối quyết định có thể gọi là sản phẩm đang chạy. Nguồn hiện hành: [code Flutter](../../app/lib/app.dart), [Android native](../../app/android/app/src/main/AndroidManifest.xml), [FastAPI](../../services/api/app/main.py), [task history](../../tasks/README.md).

| Phần | Hiện có trong repo | Bằng chứng còn thiếu trước pilot |
| --- | --- | --- |
| Android | Flutter UI, domain/data, Kotlin báo thức, camera/focus bridge; `flutter analyze` (`No issues found!`), Gradle `testDebugUnitTest` (6/6 pass) và build `app-debug.apk` đã xác nhận ở [T030](../../tasks/T030-b01b-flutter-android-build/handoff.md) | Chạy `flutter test` trên CI (do Windows WDAC chặn `flutter_tester.exe` local), kiểm màn khóa/app đóng/reboot/offline/quyền/Dừng khẩn cấp trên hai máy Android thật. |
| Backend | FastAPI `/v1`, auth gateway, SQLAlchemy, Alembic (`0002_align_question_indexes`), backup/restore JSON SHA-256; `pytest` local (`19 passed, 1 skipped`, gồm test khóa `/demo`, `/product` ở `production`, migration empty/existing data/downgrade, atomic rollback và backup/restore) đã xác nhận ở [T029](../../tasks/T029-b01a-on-dinh-backend-test/handoff.md) và [T031](../../tasks/T031-b01c-postgresql-migration/handoff.md) | Chạy suite trên PostgreSQL container thật (CI `.github/workflows/ci.yml` đã cấu hình `postgres:16-alpine`; máy local cần bật Docker Desktop), Firebase project test thật. |
| Nội dung học | Schema, một số câu đội viết/seed, tài liệu quy trình | Số câu theo môn/chủ đề, người duyệt, rubric, giấy phép từng item, benchmark chấm câu viết tay/chữ nhập. |
| AI | Code gọi Gemini server-side, nhánh `uncertain`, Socratic/Live token | Test với model/config thực tế, độ chính xác, latency, quota/chi phí, quyền dữ liệu trẻ em và fallback. Không có bằng chứng AI có thể chấm mọi môn công tâm. |
| Không gian học | Flutter timer/bridge/API học tập | Lifecycle, pin, offline, accessibility và camera/mic trên máy thật; camera/Live vẫn là tùy chọn có rủi ro quyền/chi phí. |
| Onboarding THPT/planner | Auth/profile và màn cơ bản có phần mã | Chưa có bằng chứng flow email→catalog lớp 10–12→avatar→plan xác nhận→dashboard; catalog/reviewer/AI plan cần task. |
| Phòng AI và bạn bè | Timer/API help/Live token có phần mã | Chưa có phòng media bạn bè hay avatar AI realtime được chứng minh; cần quota, consent, moderation, hai máy và chi phí. |
| Lịch ngủ/DND | Báo thức native/âm có phần mã | Vòng ngủ/thức theo ảnh tham chiếu, nhiều chuông, DND theo OS và màn khóa riêng tư chưa có bằng chứng test dọc. |
| Game | Art nghiên cứu ở [`assets/game/`](../../assets/game), luật v0.1 | Chưa có Flutter arena/PvP server, hai máy đồng bộ, cân bằng hoặc quyền phát hành thương mại. |
| iOS | Tài liệu ý tưởng | Chưa có Xcode/iPhone/build/test; không thuộc Android P0. |

**Web HTML trong API:** `/demo` và `/product` thuộc T022/T023 đang làm dở. Chúng không là client phát hành; phải tắt hoặc bỏ ở môi trường production, có test xác nhận. Không mở thêm web UI thay một màn Flutter. [Cấu trúc repo](04-cau-truc-repo.md) và [cổng release](../03-quality/02-van-hanh-phat-hanh.md) nêu việc cần làm.

## Cách cập nhật trạng thái

- Mỗi dòng ở trên chỉ được đổi khi task có test thực, môi trường, ngày, commit/build, người xác nhận và giới hạn. Ưu tiên trạng thái trong task mới nhất có bằng chứng hơn câu cũ ở archive.
- `coded` ≠ `tested` ≠ `released`. Với báo thức Android, emulator không thay máy thật. Với API, SQLite local không thay PostgreSQL. Với AI, một phản hồi mẫu không thay bộ đánh giá.
- Không tự động chuyển các task `blocked` thành `done` khi docs được viết lại. Mở task mới cho lỗi/điểm thiếu hoặc tiếp tục task chưa bàn giao theo [quy trình](03-quy-trinh-vibe-code.md).
