# Lộ trình từ repo hiện tại đến sản phẩm

**Sản phẩm đầu tiên:** Android cho học sinh THPT, có đường đăng ký/hồ sơ học/dashboard, báo thức đáng tin cậy, lịch học, một câu truy hồi đã duyệt và cách dừng an toàn. Nếu Auth chưa có, báo thức local vẫn dùng được. Mỗi mốc là **cổng có bằng chứng**, không phải cuộc thi, số phần trăm code hay thời gian hứa trước. [PRD](../01-product/01-prd.md) định nghĩa hành vi, [ma trận test](../03-quality/01-ke-hoach-kiem-thu.md) định nghĩa pass.

| Mốc | Kết quả người dùng | Phụ thuộc | Cổng ra |
| --- | --- | --- | --- |
| R0 — nền tảng | Cài được APK dev, API và DB chạy từ README trên máy đội/CI | Flutter/Android SDK được phép chạy, Python/PostgreSQL, cấu hình mẫu | Flutter analyze/test, Kotlin unit, pytest, Alembic upgrade/downgrade PostgreSQL, secret scan, test route web không mount trong production. |
| R1 — alarm local an toàn | Đặt nhiều chuông, âm, lịch ngủ, Dừng kể cả offline; DND có trạng thái thật | R0, quyền OS, máy thật | AD01–AD09 + SLEEP-01–05 trên ít nhất hai máy; 0 lỗi không dừng được chuông. |
| R2 — tài khoản/onboarding | Email Auth, lớp 10–12/môn theo catalog, mức tự đánh giá, avatar mặc định, dashboard plan cơ bản | R0, Firebase test, catalog được duyệt, consent | ON-01–06, A/B, draft/resume, xóa account; local alarm vẫn chạy khi Auth lỗi. |
| R3 — lịch và câu ôn | TKB nhập tay/upload duyệt, việc hôm nay, câu tự luận ngắn đã duyệt, nhập chữ | R1–R2, content review/cache | PLAN-01–05, chuông→câu→phản hồi, offline/không câu an toàn. |
| R4 — chấm/AI có kiểm định | Chấm ba trạng thái, camera tùy chọn, AI gợi mở và plan có xác nhận | R3, corpus có quyền, consent | Eval độc lập/ngưỡng chốt trước, timeout/quota fallback, ảnh không lưu. |
| R5 — phòng học cơ bản | Hai lựa chọn một mình/cùng AI, gợi mục tiêu, recap; học sâu im lặng, timer local, AI text theo yêu cầu; EXP thời gian sau server ledger | R2–R4, UX/quota, PostgreSQL/idempotency cho EXP | FOCUS-01–10/ROOM-01–08 phù hợp, lifecycle/offline/audio, cap EXP A/B; không mắng/khóa app. |
| R6 — thử người dùng thật | Cohort THPT tự nguyện dùng luồng lõi, đo giá trị/khó chịu/độ tin cậy | R1–R5, chính sách tuổi/quyền dữ liệu | Dừng an toàn, retention/opt-out, lỗi chấm, hỗ trợ; quyết định tiếp tục/đổi hướng. |
| R7 — phòng AI Live và bạn bè | Avatar 2D có giọng, media opt-in, phòng mời 2 người, bạn bè/block/report | R5/R6, cost, privacy, realtime/moderation | Hai máy/mạng yếu/reconnect/quota, âm/cam tắt thật, abuse handling. |
| R8 — giao hữu/ranked sau cổng | Hai người cùng câu/lý do, tướng 2D; sau playtest mới rank/mùa | R4/R6, content/rubric đủ, hai máy | Server chốt trận/void/ledger, anti-abuse/balance, không phạt do AI uncertain. |
| R9 — phát hành rộng/iOS | Hỗ trợ, bảo mật, store release; iOS task riêng sau Android | Release gates, ngân sách/hỗ trợ, Mac/iPhone cho iOS | Checklist [release](../03-quality/02-van-hanh-phat-hanh.md), build ký, giám sát/rollback, quyền nội dung/art. |

## Backlog bắt đầu ngay

| ID | Task dọc | AC tối thiểu | Bằng chứng |
| --- | --- | --- | --- |
| B01 | Toolchain/CI và API test đang treo | Một lệnh trên CI chạy Flutter/Gradle/Python test; pytest health kết thúc | Log CI, build hash và test count; không đổi tính năng. |
| B02 | Android alarm thật | Chuông reo/dừng khi khóa màn, offline, app bị kill; đúng quyền và fallback | AD01–AD07 với video/log hai máy. |
| B03 | Câu sáng và nhập chữ | Lịch chọn môn, câu đã duyệt, nộp bước giải; offline an toàn | Contract + widget + Android E2E. |
| B04 | PostgreSQL/Auth đồng bộ | Token A/B, migration, session/attempt/XP idempotent | API integration PostgreSQL và hai tài khoản test. |
| B05 | AI grading được kiểm | 3 trạng thái, rubric, báo chấm sai, không lộ ảnh/key | Eval set + security/latency test. |
| B06 | Auth/onboarding THPT | Email/verify, catalog lớp/môn, avatar, plan nháp xác nhận, dashboard | ON-01–06, Firebase test, PostgreSQL A/B. |
| B07 | Lịch ngủ và nhắc DND | Vòng ngủ/thức + nhập số, nhiều alarm, quiet hours; DND báo đúng OS | SLEEP-01–05 trên máy thật. |
| B08 | Không gian học | Phòng solo trước, AI text/push-to-talk sau; Live/bạn bè feature flags | FOCUS/ROOM, quota/privacy/reconnect. |

Không gộp backlog thành một task “làm app hoàn chỉnh”. B01a/b/c vẫn là nền tảng đầu tiên; B06 có thể chuẩn bị catalog/Auth song song về thiết kế nhưng không tuyên bố flow hoạt động cho tới khi test dọc. Mỗi task theo [quy trình](03-quy-trinh-vibe-code.md), chốt acceptance/test trước code và giữ trạng thái thật. Sau mỗi cổng, cập nhật [hiện trạng](01-hien-trang.md) và [ma trận truy vết](../03-quality/03-truy-vet-yeu-cau.md).
