# Lộ trình từ repo hiện tại đến sản phẩm

**Sản phẩm đầu tiên:** Android dùng cá nhân, có báo thức đáng tin cậy, lịch học, một câu truy hồi đã duyệt và cách dừng an toàn. Không đặt PvP/rank làm điều kiện hoàn thành báo thức. Mỗi mốc là **cổng có bằng chứng**, không phải số phần trăm code hay thời gian hứa trước. [PRD](../01-product/01-prd.md) định nghĩa hành vi, [ma trận test](../03-quality/01-ke-hoach-kiem-thu.md) định nghĩa pass.

| Mốc | Kết quả người dùng | Phụ thuộc | Cổng ra |
| --- | --- | --- | --- |
| R0 — nền tảng | Cài được APK dev, API và DB chạy từ README trên máy đội/CI | Flutter/Android SDK được phép chạy, Python/PostgreSQL, cấu hình mẫu | Flutter analyze/test, Kotlin unit, pytest, Alembic upgrade/downgrade PostgreSQL, secret scan, test route web không mount trong production. |
| R1 — báo thức local | Đặt/sửa/hủy chuông, chọn âm, tắt ngay khi cần; hoạt động offline | R0, quyền OS, thiết bị thật | AD01–AD07 trên ít nhất hai máy/phiên bản Android; 0 lỗi không dừng được chuông; trạng thái quyền trung thực. |
| R2 — ôn sáng nhiều môn | TKB/môn/tổ hợp, câu đã duyệt, nhập đáp án + bước giải bằng chữ, camera tùy chọn | R1, content review, cache offline | Android E2E chuông→câu→hoàn thành; offline không giả chấm; `uncertain` và nhập chữ khi từ chối camera. |
| R3 — tài khoản/đồng bộ | Dùng khách local hoặc đăng nhập, đồng bộ lịch, phiên/XP, xóa tài khoản | PostgreSQL/Firebase test, API contract | Hai máy A/B, idempotency, xung đột revision, quyền riêng tư/xóa, backup/restore. |
| R4 — AI có kiểm định | Hỗ trợ gợi mở và chấm sau nộp, phản hồi đúng/sai/chưa chắc | R2–R3, corpus được phép, consent | Bộ đánh giá độc lập, ngưỡng false-correct/false-incorrect được chủ dự án chốt trước pilot, timeout/quota fallback, không log ảnh/token. |
| R5 — không gian học | Timer local, việc hôm nay, gợi ý theo lượt | R1, UX và quyền dữ liệu | Test lifecycle/offline/camera-mic opt-in, giới hạn lượt/tokens, không khóa app khác. |
| R6 — pilot 7 ngày | Một nhóm học sinh tự nguyện dùng app, báo lỗi và đánh giá giá trị | R1–R5, đồng ý độ tuổi phù hợp | Theo dõi độ tin cậy chuông, tỷ lệ hoàn thành, lỗi chấm, khó chịu, quyền rút/xóa; quyết định tiếp tục/đổi hướng. |
| R7 — giao hữu | Hai người cùng môn/lớp/chương trình giải cùng câu, đấu tướng 2D | R4/R6, câu đủ và chấm đáng tin | Server chốt kết quả, hai máy thật, reconnect, cân bằng/anti-abuse. Ranked/rank/coin mở sau cổng riêng. |
| R8 — phát hành rộng/iOS | Hỗ trợ, bảo mật, pháp lý, store release; iOS chỉ sau Android | Pilot đạt, tài nguyên vận hành, Mac/iPhone cho iOS | Checklist [release](../03-quality/02-van-hanh-phat-hanh.md), build ký, giám sát/rollback, chính sách dữ liệu và quyền asset. |

## Backlog bắt đầu ngay

| ID | Task dọc | AC tối thiểu | Bằng chứng |
| --- | --- | --- | --- |
| B01 | Toolchain/CI và API test đang treo | Một lệnh trên CI chạy Flutter/Gradle/Python test; pytest health kết thúc | Log CI, build hash và test count; không đổi tính năng. |
| B02 | Android alarm thật | Chuông reo/dừng khi khóa màn, offline, app bị kill; đúng quyền và fallback | AD01–AD07 với video/log hai máy. |
| B03 | Câu sáng và nhập chữ | Lịch chọn môn, câu đã duyệt, nộp bước giải; offline an toàn | Contract + widget + Android E2E. |
| B04 | PostgreSQL/Auth đồng bộ | Token A/B, migration, session/attempt/XP idempotent | API integration PostgreSQL và hai tài khoản test. |
| B05 | AI grading được kiểm | 3 trạng thái, rubric, báo chấm sai, không lộ ảnh/key | Eval set + security/latency test. |

Không gộp B01–B05 thành một task “làm app hoàn chỉnh”. Mỗi task theo [quy trình](03-quy-trinh-vibe-code.md), chốt acceptance/test trước code và giữ trạng thái thật. Sau mỗi cổng, cập nhật [hiện trạng](01-hien-trang.md) và [ma trận truy vết](../03-quality/03-truy-vet-yeu-cau.md).
