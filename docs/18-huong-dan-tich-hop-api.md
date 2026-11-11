# Hướng dẫn tích hợp mobile, API, SQL và Gemini

Tài liệu này chỉ cách ghép các phần theo [hợp đồng `/v1`](07-hop-dong-api-va-ai.md); endpoint/payload chuẩn nằm ở đó. Đây là hướng dẫn triển khai, **repo chưa có backend/mobile hoạt động**. [Kiến trúc](06-kien-truc-va-du-lieu.md), [workflow](17-workflow-va-vong-doi-du-lieu.md) và [SQL](28-backend-sql.md) là nguồn liên quan.

## 1. Môi trường

| Môi trường | Auth | Dữ liệu | AI | Phạm vi |
| --- | --- | --- | --- | --- |
| Demo một máy | Khách local hoặc tài khoản demo giả lập **chỉ local** | SQLite/fixture | Gemini mock hoặc ảnh đội tự viết có kiểm soát | Không gọi là online thật |
| Dev/staging | Firebase Authentication hoặc emulator | PostgreSQL, migration | Gemini mock trước; key server khi kiểm thử thật | Hai máy, quyền A/B, concurrency |
| Production/pilot | Firebase Authentication, token verifier | PostgreSQL, backup/restore | Gemini server side sau rà soát dữ liệu | Chỉ mở sau cổng test và đồng ý phù hợp |

Không cần Firebase Firestore/Realtime Database cho nghiệp vụ. Firebase SDK ở mobile chỉ phục vụ đăng nhập online; API key Gemini và DB credential ở backend secret store, không trong APK/Git/chat. Khi lập môi trường thật, pin SDK/model/version, kiểm tra điều khoản free tier và không gửi ảnh học sinh thật lên tier này khi chưa đánh giá/đồng ý phù hợp.

## 2. Mobile gọi API theo tình huống

| Tình huống | Bước tích hợp |
| --- | --- |
| Khách local | Không gọi `/v1/me`; lưu alarm/lịch và prompt fallback local, không hiện XP server |
| Đăng nhập/đổi máy | Firebase SDK lấy ID token; `GET /v1/me`; hỏi trước nhập dữ liệu local; `401` refresh một lần; không log token |
| Lưu alarm | Lưu local và lập lịch OS; nếu đã đăng nhập đồng bộ `POST/PATCH /v1/alarms` có revision; UI dựa vào kết quả OS |
| Lịch/giờ | `PUT /v1/timetable`; `POST /v1/alarms/wake-suggestions` chỉ preview, người dùng xác nhận mới đổi giờ |
| Tải đề | `GET /v1/challenges/next?date=...`, cache prompt/revision/validForDate; **không** cache answerSpec/rubric |
| Chuông reo | Phát/dừng local trước; `POST /v1/sessions` và `/events` có thể đồng bộ sau; không đợi API |
| Gửi bài chữ | `POST /v1/sessions/{id}/answers` với `answerValue`, `reasoningText`, `clientAttemptId` sau nút Gửi; bản nháp offline cần xác nhận riêng |
| Gửi ảnh | `POST /v1/sessions/{id}/attempts` multipart với ảnh + `answerValue`; chỉ sau đồng ý; tối đa 5 MB theo contract; không retry ngầm vô hạn |
| Tiến độ/xóa | `GET /v1/progress/summary`; export/delete theo `/v1/me`; không tự tính điểm trên client |

Mỗi POST tạo phiên/nộp bài dùng `Idempotency-Key` UUID ổn định giữa các lần retry. Timeout client chấm ảnh 15 giây theo [07](07-hop-dong-api-va-ai.md); backend đặt deadline AI ngắn hơn. `409` tải revision/state mới; `413/415` hướng dẫn ảnh khác/nhập chữ; `429/503/504` cho kết thúc không chấm; không chặn `Dừng khẩn cấp`. Event offline tối đa 7 ngày chỉ là metadata, không thành bằng chứng cấp XP. Ảnh không tự xếp hàng gửi; bài chữ local tự chọn lưu tối đa 24 giờ, hỏi lại trước upload.

## 3. Backend chấm và lưu

1. Dependency xác minh Firebase ID token, lấy `uid` từ token, map `users.auth_subject`; mọi truy vấn owner scope. Không tin `userId`, `xp`, `result`, `rank` hoặc `reasoning_present` từ body.
2. Repository lấy `questions(id, revision, status, answer_spec_json, rubric_json)` từ PostgreSQL; câu phải `published`/đủ rubric và trong phạm vi lớp/môn. Contract GET trước khi làm không lộ đáp án.
3. Kiểm MIME + magic bytes + size, giới hạn rate/quota, loại ảnh ngoài phạm vi. Gemini chỉ đọc bước/đề xuất nhận xét theo schema; validator/backend quyết `correct|incorrect|uncertain`; AI không cấp XP, nhận diện gian lận hay tự viết bảng SQL. Bài chữ có thể dùng validator trực tiếp khi đủ bằng chứng.
4. Không giữ transaction trong lúc gọi Gemini. Attempt pending có unique ID; transaction cuối ghi quyết định, feedback và `xp_ledger` với unique source; retry cùng key không nhân điểm. Bất đồng/timeout trả `uncertain` và không có một job chấm muộn tự cấp điểm.
5. Xóa ảnh tạm trong nhánh thành công và lỗi, không log payload nhạy cảm. Người dùng báo chấm sai qua `/feedback`; chỉnh kết quả bằng audit/ledger mới, không ghi đè lịch sử không dấu vết.

## 4. Hợp đồng test tối thiểu để hai bên làm song song

Fixture có: một câu Toán/lớp 9 đã duyệt và rubric trình bày, một câu khác môn, một ảnh đội tự viết đúng, một ảnh sai bước, một ảnh mờ, một bài chữ có đáp án nhưng lập luận sai, một trường hợp AI timeout, và một câu retired. Mỗi fixture ghi revision và kết quả kỳ vọng; không dùng ảnh học sinh thật. Mobile mock theo đúng ba trạng thái `correct/incorrect/uncertain`, không đặt nhãn “AI thật” lên mock.

Contract tests: owner A/B và token thiếu/hết hạn; idempotency cùng/khác payload; không lộ đáp án trước reveal; `uncertain` không phạt/không cấp điểm đúng; mode thử thách không Hoãn/gợi ý trước sai rõ lần 3; upload ảnh chỉ sau đồng ý; offline event không cấp XP; xóa tài khoản 202/status; bản nháp không lộ khi đổi tài khoản. Integration tests cho PostgreSQL transaction/concurrent ledger và migration; SQLite không thay cho các test này.

## 5. Quan sát lỗi và bàn giao

Log `requestId`, route, mã lỗi, thời gian, model/rubric revision và trạng thái đã ẩn danh; không log ảnh, token, lời giải hoặc SQL params có dữ liệu cá nhân. Metric tối thiểu: alarm lập lịch thành công trên thiết bị, AI timeout/uncertain, chấm bị người dùng báo sai, XP retry/trùng, lỗi quyền và chi phí mỗi attempt. Từng task code cập nhật [plan/test/handoff](../tasks/README.md) và docs07 khi đổi hợp đồng.
