# Hợp đồng HTTP `/v1` và tích hợp Flutter

**Mục tiêu:** một contract duy nhất cho Android và FastAPI. **Trạng thái:** các route nêu ở bảng A có mã trong [`routes/v1.py`](../../services/api/app/routes/v1.py); payload/permission vẫn phải khóa bằng OpenAPI + contract test trước khi mở người dùng thật. Bảng B là **đề xuất chưa triển khai**. Không coi danh sách docs là bằng chứng API đang chạy. [Dữ liệu](03-du-lieu-sql.md), [AI](06-ai-va-cham-bai.md), [auth](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 1. Quy ước chung

- Base `/v1`, JSON UTF-8; ảnh `multipart/form-data`; production HTTPS. `Authorization: Bearer <Firebase ID token>` cho dữ liệu cá nhân; server xác minh token và lấy owner từ token, không nhận `userId` client. `GET /v1/health` không auth và không lộ key/config nhạy cảm. Dev bearer fallback phải **tắt production**.
- POST tạo phiên/attempt/XP/consent dùng `Idempotency-Key`; cùng key + cùng payload trả cùng kết quả, khác payload `409 IDEMPOTENCY_CONFLICT`. Mobile tạo `localSessionId`/`clientAttemptId` ổn định khi retry. Server version câu/rubric/record và `requestId` để tra lỗi.
- Lỗi chuẩn: `{"error":{"code":"...","message":"...","requestId":"...","retryable":false}}`. Mã: 400 validation, 401 token, 403 owner/consent, 404 không thấy, 409 revision/idempotency, 413 ảnh lớn, 415 MIME, 429 quota, 502/503 AI upstream, 504 timeout. Client map sang câu Việt và giữ dữ liệu nhập khi retry.
- Timestamps UTC ISO 8601; `localDate`/lịch dùng IANA timezone. Pagination khi danh sách lớn: `limit ≤50`, `cursor` opaque. Bỏ/đổi nghĩa field cần version mới; thêm field tùy chọn không làm client cũ hỏng.
- **Không bao giờ** trả answer spec/rubric/hidden hint trước khi kết thúc câu; không trả token Gemini thật cho client ngoài ephemeral Live token đã giới hạn và consent nếu feature mở.

## 2. A — route đã có source code

| Nhóm | Route | Trách nhiệm và điểm cần kiểm |
| --- | --- | --- |
| Health/hồ sơ | `GET /health`, `GET/PATCH/DELETE /me`, `POST /me/consent` | Owner token, alias/grade/môn/consent, xóa `202`; test không lộ secret/không cross owner. Onboarding state/catalog version/plan draft **chưa mặc định có** trong payload hiện tại. |
| Lịch/báo thức | `GET/PUT /timetable`, `GET/POST /alarms`, `PATCH/DELETE /alarms/{id}` | Revision và idempotency; **API lưu cấu hình, Android mới lập lịch OS**. |
| Câu | `GET /challenges/next`, `POST/GET /questions/personalized` | Câu published theo môn/khối; AI personalized là draft luyện, không mặc định XP. |
| Phiên/attempt | `GET/POST /sessions`, `POST /sessions/{id}/events`, `/answers`, `/attempts`, `/feedback` | Session owner, câu/rubric revision, retry không nhân XP; ảnh chỉ tạm thời. |
| Tiến độ | `GET /progress/summary` | Chỉ dữ liệu user từ token, không lấy tiến độ bạn cùng lớp. |
| Học | `POST /study/sessions`, `/study/sessions/{id}/finish`, `/study/help`, `/study/live-token` | Timer local không bị API chặn; Live token opt-in và ephemeral; rate limit/timeout. |

Flutter phải có contract test cho mỗi endpoint nó dùng với payload thật, token sai/A-B, offline/timeout, schema thay đổi. Route hiện có vẫn có thể chưa pass runtime ở môi trường hiện tại; [hiện trạng](../00-start/01-hien-trang.md).

## 3. Payload tối thiểu cần thống nhất trong task tích hợp

**Alarm create:** `{localTime:"06:00", timeZone:"Asia/Ho_Chi_Minh", weekdays:[1,2,3,4,5], enabled:true, challengeMode:"short_review"}`. Trả `id`, `revision`, config; **không** trả `osScheduled:true` từ server. Khi Flutter có mode enum khác, task phải map/contract test rõ.

**Session:** `localSessionId`, `alarmId`, `questionId`, `questionRevision`, `localDate`, `timeZone`; server ràng buộc owner/revision và giữ một session cho key. **Attempt chữ:** `clientAttemptId`, `answerValue`, `reasoningText` (ít nhất một bước), `questionRevision`; **attempt ảnh:** multipart file + metadata, xem lại/xác nhận trước upload. Trả `result: correct|incorrect|uncertain`, `feedback`, `nextActions`, `rubricRevision`, `requestId`, `xpAwarded` do server quyết định. Không nhận `isCorrect`, `xp`, `rank`, `hp` hoặc đáp án chuẩn từ client.

**Study help:** task/subject/grade, nội dung người dùng hỏi và tối đa số lượt gần nhất theo policy; trả một gợi ý/câu hỏi gợi mở, không lời giải cuối trước nỗ lực. **Study finish:** client session ID + elapsed local summary; server ghi idempotent, không giữ người dùng chờ để thoát timer.

Ví dụ là contract mục tiêu; task B01/B03/B04 phải so với Pydantic schema hiện tại, sửa docs/schema/client/test **cùng lần** nếu lệch. Không viết client theo ví dụ rồi mặc định server đã hỗ trợ.

## 4. B — đề xuất chưa triển khai

Onboarding draft/commit và catalog `GET /catalog?grade=10|11|12&version=...`; plan draft/confirm có `planVersion`/`source`/`requiresConfirmation`; `POST /me/export`, `GET /me/exports/{id}`, `GET /me/delete-status`; task ngày/ngoại lệ lịch và notification preferences nếu cần sync (âm/OS schedule vẫn local); admin content review/import; avatar upload/moderation/public profile projection; friend request/accept/block, private study room/invite/join/leave/snapshot/event stream; PvP matchmaking/action/events/settle, rank/ledger/bảng; teacher/parent scopes. Chỉ mở endpoint sau PRD, quyền, SQL migration, contract tests và cổng release tương ứng. Không gắn route mock vào `/v1` production để UI trông hoàn thiện. [Onboarding](../01-product/07-dang-ky-va-khoi-tao-lo-trinh.md), [room](09-phong-hoc-realtime.md), [P-11](../01-product/05-lich-hoc-nhac-viec.md), [P-12](../01-product/06-ho-so-tien-do-xa-hoi.md).

## 5. Offline/retry và bảo vệ server

Alarm/timer local không chờ API. Metadata dismiss có thể queue tối đa 7 ngày với key ổn định sau đăng nhập/consent; không dựa vào giờ máy để cấp XP. Bản nháp chữ gửi sau chỉ khi người dùng xác nhận; ảnh **không queue upload ngầm**. Rate limit theo user/route/device rủi ro, payload length/MIME/magic bytes, timeout AI thấp hơn timeout client, request ID và log redaction. Tắt `/demo`, `/product` ở production, có test. [Kiểm thử](../03-quality/01-ke-hoach-kiem-thu.md).
