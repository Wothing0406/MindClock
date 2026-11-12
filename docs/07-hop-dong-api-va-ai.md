# Hợp đồng API và đặc tả AI

> **Mở rộng cần version hóa khi coding:** hồ sơ nhiều môn, mục tiêu thi, task/nhắc lịch và chế độ thử thách tại [docs/31](31-bao-thuc-thu-thach.md), [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md). `snooze` chỉ còn cho chế độ thường; `incorrect` lần 1–2 của chế độ thử thách không trả hint, `uncertain` không tăng số lần sai. Endpoint mới ở docs/32 là đề xuất, chưa là API chạy.

> **API giai đoạn đấu trường/kinh tế/nội dung:** danh sách endpoint và bảng dữ liệu dự kiến ở [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md), [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md), [docs/38](38-nguon-du-lieu-va-duong-nhap-cau-hoi.md), hợp đồng nhân vật/rank/bảng ở [docs/44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md). Chúng chưa là API đã triển khai; task coding phải chốt payload, quyền, idempotency và contract tests trong cùng lần.

> **PvP v0.1 mới:** [docs/46 §6](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) thay action/event/payload HP của bản 60 HP cũ; docs/46 là **dự kiến**, chưa có endpoint chạy. Trước code phải chốt schema/contract test hai máy và quyền participant.

> **Hợp đồng bài có trình bày:** `answer_value` + `reasoning_text|handwritten`, ba kết quả và policy chấm theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). PvP heal/hút/choáng ở [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md). Endpoint gợi ý giờ dậy chỉ preview theo [docs/32 §5–6](32-ho-so-hoc-tap-va-nhieu-mon.md); không tự tạo alarm. Đây là phần mở rộng chưa triển khai; khi code phải đổi payload/contract tests của `/answers`, `/attempts`, match submission cùng lúc.

**Base path:** `/v1` · **Transport:** HTTPS + JSON UTF-8, riêng ảnh dùng `multipart/form-data` · **Auth:** `Authorization: Bearer <Firebase ID token>` cho mọi endpoint trừ `/health`. Backend xác minh token, lấy `uid` từ token. Mọi thời điểm API trả ISO 8601 UTC; `localDate` theo múi giờ IANA của người dùng.

Đây là **hợp đồng triển khai**, chưa phải API đang chạy. Nếu thay đổi field, sửa tài liệu và contract test cùng lúc; không tự ý đổi từ mobile hoặc backend một phía.

## 1. Quy ước chung

- Mọi POST tạo phiên/nộp bài/cấp điểm dùng header `Idempotency-Key` (UUID). Cùng key + cùng payload trả cùng kết quả; cùng key + payload khác trả `409 IDEMPOTENCY_CONFLICT`.
- `POST /sessions` và `/events` cho phép đồng bộ **metadata sự kiện** offline trong 7 ngày sau khi người dùng đăng nhập/đồng ý đồng bộ; server kiểm tra thứ tự, mốc thời gian hợp lý, quyền sở hữu và `questionRevision`. Không mặc nhiên tin đồng hồ thiết bị, cờ `reasoning_present` hoặc kết quả local để cấp XP. Ảnh không được xếp hàng tải ngầm; bài chữ offline chỉ gửi khi người dùng chọn rõ theo §8.
- Pagination: `limit` tối đa 50, `cursor` opaque. Versioning qua `/v1`; thêm field tùy chọn không phá client, xóa/đổi nghĩa field cần `/v2`.
- Dữ liệu từ client được kiểm tra kiểu, độ dài, quyền sở hữu và trạng thái nghiệp vụ. Không tin `userId`, `xp`, `correct` hay `rank` gửi lên.
- Mã lỗi thống nhất: `{"error":{"code":"...","message":"...","requestId":"...","retryable":false}}`. `message` là nội dung an toàn cho người dùng; client có thể ánh xạ sang chuỗi Việt trong [UX](05-ux-va-noi-dung-tieng-viet.md).
- HTTP: `400` dữ liệu sai, `401` chưa xác thực, `403` không có quyền, `404` không thấy, `409` trạng thái/xung đột, `413` ảnh quá lớn, `415` sai MIME, `429` giới hạn, `502/503` dịch vụ AI lỗi, `504` quá hạn. Với lỗi AI, server trả trạng thái `uncertain` khi có thể để người dùng tiếp tục.

## 2. Endpoint MVP

| Method/path | Yêu cầu chính | Kết quả chính | Ghi chú |
| --- | --- | --- | --- |
| `GET /health` | Không auth | `status`, `version` | Không lộ cấu hình |
| `GET /me` | Token | Hồ sơ và cài đặt | Tự tạo hồ sơ tối thiểu nếu chưa có; không áp dụng khách local |
| `PATCH /me` | `displayName`, `gradeBand`, `timeZone`, `locale` | Hồ sơ mới | Không nhận field quyền/XP; email/mật khẩu qua Firebase SDK |
| `DELETE /me` | Token + xác thực lại trong app + `Idempotency-Key` | `202 {deletionRequestId,status}` | Thu hồi quyền/ẩn bảng ngay, xóa bất đồng bộ; không trả `đã xóa` trước khi hoàn tất |
| `GET /me/delete-status` | Token hoặc deletion token giới hạn theo flow | `status`, `updatedAt` | `pending|processing|completed|failed`; không lộ dữ liệu sau thu hồi |
| `POST /me/export` | Token + `Idempotency-Key` | `202 {exportId,status}` | Tạo bản xuất có TTL; không gửi link qua bảng/log |
| `GET /me/exports/{id}` | Token | `status`, `downloadUrl` chỉ khi ready | Chỉ chủ sở hữu, URL ngắn hạn theo docs/25 |
| `GET /alarms` | Token | Danh sách báo thức | Cấu hình server, mobile tự lập lịch local |
| `POST /alarms` | `localTime`, `weekdays`, `enabled`, `challengeMode` | Alarm + `revision` | Mobile chỉ báo “đã cài” khi local schedule thành công |
| `PATCH /alarms/{id}` | Trường sửa + `revision` | Alarm mới | `409` nếu sửa trên bản cũ |
| `DELETE /alarms/{id}` | Token | `204` | Mobile hủy local schedule |
| `GET /timetable` | Token | 7 ngày và môn/chủ đề | Không bắt buộc mọi ngày có môn |
| `PUT /timetable` | Danh sách 7 ngày | Bản đã chuẩn hóa | Validate môn/chủ đề |
| `GET /challenges/next?date=YYYY-MM-DD` | Token | Câu hỏi đã duyệt, `questionRevision`, `reasoningPromptVi`, `validForDate`, `offlinePolicy` | Dùng tải trước; **không gửi đáp án/rubric/giải thích xuống máy trước khi làm**; offline chỉ hoàn thành không chấm |
| `POST /alarms/wake-suggestions` | Giờ học và phút đi đường/chuẩn bị/đệm đã xác nhận | `suggestions[]`, `inputRevision`, `calculationVersion` | Preview, không tạo/sửa alarm; client kiểm phép tính và yêu cầu xác nhận |
| `POST /sessions` | `alarmId`, `localSessionId`, `localDate`, `questionId`, `questionRevision`, `startedAt` | `sessionId`, `state`, `version` | Tạo/đồng bộ phiên idempotent |
| `POST /sessions/{id}/events` | `eventType`, `occurredAt`, `version` | Phiên mới | `ring`, `snooze`, `start`, `dismiss`, `complete_ungraded` |
| `POST /sessions/{id}/attempts` | Multipart `image`, `answerValue`, `questionId`, `submissionKind=handwritten`, `clientAttemptId` | `attemptId`, `result`, `feedback`, `nextActions` | Đáp án + ảnh cách làm; tối đa 5 MB; không lưu ảnh mặc định |
| `POST /sessions/{id}/answers` | `answerValue`, `reasoningText`, `clientAttemptId` | Cùng kiểu kết quả attempt | Đáp án + cách làm chữ thay camera; không gửi tự động bản nháp offline; theo docs/39 |
| `POST /sessions/{id}/feedback` | `attemptId`, `category`, `comment?` | `feedbackId`, `status` | Báo AI chấm sai |
| `GET /progress/summary` | Token | XP, streak, buổi hoàn thành, chủ đề cần ôn | Server tính từ ledger |
| `GET /sessions?limit=&cursor=` | Token | Lịch sử phiên tối giản | Không trả ảnh |

## 3. Ví dụ payload quan trọng

### Tạo báo thức

```json
{
  "localTime": "06:30",
  "timeZone": "Asia/Ho_Chi_Minh",
  "weekdays": [1, 2, 3, 4, 5],
  "enabled": true,
  "challengeMode": "short_review",
  "snoozeMinutes": null
}
```

Response thêm `alarmId`, `revision`, `createdAt`, `updatedAt`. Client **không coi response là bằng chứng đã đặt được báo thức OS**; sau đó phải kiểm tra quyền và lập lịch local.

### Tải câu tiếp theo

```json
{
  "questionId": "math9-linear-001",
  "questionRevision": 3,
  "validForDate": "2026-11-16",
  "subject": "math",
  "topicId": "linear_equation_1var",
  "difficulty": 1,
  "prompt": "Giải phương trình 2(x − 3) = 10.",
  "reasoningPromptVi": "Viết một hoặc hai bước bạn đã làm.",
  "offlinePolicy": "ungraded_only",
  "estimatedSeconds": 75,
  "fallback": false
}
```

### Kết quả chấm

```json
{
  "attemptId": "att_01",
  "result": "incorrect",
  "confidence": 0.88,
  "observedSteps": [],
  "firstIssue": null,
  "feedback": "Bài này chưa đúng. Bạn có thể thử lại.",
  "hint": null,
  "nextActions": ["retry", "finish_ungraded", "emergency_stop"],
  "xpAwarded": 0,
  "modelVersion": "configured-server-side",
  "rubricRevision": 3
}
```

Ví dụ trên là `incorrect` **lần 1 trong chế độ thử thách**, nên `observedSteps` công khai rỗng, `firstIssue` và `hint` đều `null`; backend giữ nhận định nội bộ để phản hồi sau ngưỡng/hoàn thành. Sau lần sai rõ thứ 3 mới trả bước cần xem và gợi ý phương pháp theo docs/31. `confidence` là tín hiệu nội bộ cần hiệu chuẩn, không phải xác suất đúng được bảo đảm. UI không cần hiển thị số này. `modelVersion` là phiên bản thực tế backend ghi, không hard-code theo ví dụ.

## 4. Định dạng câu hỏi đã duyệt

Mỗi câu trong bảng `questions`/`question_revisions` có `questionId`, `revision`, `status=draft|reviewed|published|retired`, `subject`, `gradeBand`, `topicId`, `difficulty=1..4`, `estimatedSeconds`, `prompt`, `reasoningPromptVi`, `answerSpec`, `rubric`, `editorId`, `reviewerId`, `sourceLicense` và timestamps. Chỉ `published` mới được chọn cho người học. `questionId + revision` là bất biến sau khi xuất bản; sửa nội dung tạo revision mới. Nội dung có bản quyền chỉ nhập khi có quyền sử dụng.

Ví dụ `answerSpec` cho câu `2(x − 3) = 10`: `type=single_variable_equation`, `variable=x`, `acceptedValues=[8]`, `tolerance=0`. `rubric` có ba bước: phân phối `2x−6=10`, chuyển vế `2x=16`, kết luận `x=8`; cho phép cách giải tương đương không đi qua đúng chuỗi này, nên AI phải mô tả bước thực thấy và validator chỉ kiểm tra kết quả xác định. Ghi lỗi thường gặp `2x−3=10` là phân phối thiếu nhân 2 với 3. Với môn khác, định nghĩa `answerSpec` riêng, không lạm dụng rubric Toán.

Quy trình biên tập: người soạn tạo `draft` → người duyệt chuyên môn xác nhận đáp án/rubric/thời lượng → `published` → khi phát hiện lỗi chuyển `retired` và ngừng chọn câu. Mỗi phiên giữ `questionRevision` đã dùng để giải thích kết quả lịch sử.

## 5. Quy trình chấm ảnh

1. Server kiểm tra token, quyền với session, trạng thái phiên, số attempt, kích thước, MIME, magic bytes, giới hạn request và khóa idempotency.
2. Server lấy question/rubric đã duyệt theo `questionId + revision`; không nhận đáp án chuẩn từ client.
3. Nén/chuẩn hóa ảnh theo giới hạn; gửi ảnh cùng rubric cho Gemini. Prompt yêu cầu: đọc từng bước có thể nhìn thấy, không tự bổ sung bước không có trong ảnh, nêu chỗ không chắc, trả JSON theo schema.
4. Server kiểm tra schema **và ngữ nghĩa**: enum, index hợp lệ, độ dài text, không lộ prompt, không có câu trả lời mâu thuẫn với `answerSpec`.
5. Với Toán có đáp án xác định, backend dùng bộ kiểm tra độc lập cho kết quả cuối (ví dụ phân tích `x=8`), nhưng không thay thế đánh giá logic các bước. Nếu AI bảo `correct` mà validator thấy kết quả sai, trả `uncertain` và ghi cờ rà soát.
6. Chỉ kết quả đủ điều kiện mới ghi attempt và XP trong transaction. Backend đặt deadline AI ngắn hơn timeout client 15 giây; nếu API AI lỗi/quá hạn, trả `uncertain` với hành động an toàn và không có lần chấm chạy nền tự cấp XP muộn.
7. Hủy ảnh tạm sau request. Log chỉ có `requestId`, latency, mã lỗi, question ID và phiên bản model; không log ảnh/chữ viết.

### Schema nội bộ tối thiểu từ AI

`readable: boolean`, `observedSteps: string[]`, `finalAnswer: string|null`, `candidateVerdict: correct|incorrect|uncertain`, `firstIssueStepIndex: integer|null`, `issueReason: string|null`, `confidenceSignal: number`, `hint: string|null`. Backend tự tạo `result`, `feedback` đã chuẩn hóa và `xpAwarded`. Không cho AI tự quyết XP, streak, rank hoặc ghi dữ liệu.

### Quy tắc `uncertain`

Ảnh mờ/cắt thiếu; không đọc được ít nhất một bước quan trọng; nhiều cách hiểu; AI và validator bất đồng; confidence dưới ngưỡng đã hiệu chuẩn; timeout; câu hỏi/rubric thiếu hoặc hết hiệu lực. Bản đầu có thể đặt ngưỡng bảo thủ và điều chỉnh bằng tập đánh giá, không lấy số confidence của model làm sự thật tuyệt đối.

## 6. Gợi ý Socratic

- Trước lần sai rõ thứ ba ở mode thử thách, response công khai chỉ nói chưa đúng và cho thử lại; không lộ `firstIssue`, lời giải hoặc đáp án qua field khác/analytics. Backend có thể giữ lỗi bước ở quyết định nội bộ có quyền để phục vụ review.
- Gợi ý đầu tiên từ lần sai rõ thứ ba nhắc **phép biến đổi hoặc khái niệm**, không đưa đáp án cuối.
- Gợi ý dựa vào `firstIssue`; trong mode thử thách chỉ hiện sau lần `incorrect` rõ thứ ba. Sau 5 lần sai rõ, không tăng âm/độ khó; người học đổi câu dễ hơn hoặc Dừng khẩn cấp. Không dùng số lần `uncertain` để mở hint.
- Khi người học kết thúc hoặc yêu cầu sau lần thử, cho xem lời giải đầy đủ để học; không cấm tuyệt đối đáp án.
- Nội dung AI phải được kiểm tra tránh xúc phạm, gán nhãn năng lực, thông tin ngoài phạm vi câu hỏi và câu trả lời quá dài.

## 7. Bảo vệ API và chi phí

Giới hạn 2 ảnh/phiên và số phiên/ngày; auth + rate limit theo `uid` và IP; kích thước ảnh tối đa; timeout server; cache câu hỏi; không gọi AI để sinh câu hàng loạt trên mỗi lần reo. Theo dõi số token/chi phí theo loại request nhưng không gắn log với ảnh. Khóa Gemini ở Secret Manager; có công tắc tắt chấm AI khi chi phí hoặc lỗi vượt ngưỡng. Nếu công tắc tắt, app vẫn báo thức và cho hoàn thành không chấm.

## 8. Quy tắc offline, khách local và đồng bộ bài

1. **Chuông trước API:** OS lập lịch/phát/dừng bằng dữ liệu local, không yêu cầu token. Khách local có thể đặt giờ và xem câu mẫu/đã cache, nhưng không có XP/RP server. Server response tạo alarm không được hiển thị như bằng chứng OS đã đặt thành công.
2. **Đề tải trước:** `/challenges/next` trả đề và yêu cầu viết ngắn, không trả đáp án/rubric/giải thích. Khi offline, người dùng vẫn làm câu đã cache hoặc câu tự biên soạn đóng gói trong app. App có thể hiện `Đã ghi bài làm`/`Hoàn thành không chấm`, **không hiện `correct`/`incorrect` từ bài viết tự do**. Không dùng đáp án client để cấp XP.
3. **Bản nháp offline:** mặc định chỉ tồn tại trong phiên local, xóa khi người dùng kết thúc nếu không chọn lưu. Có nút tự chọn `Lưu trên máy để gửi sau` cho **bài chữ**: lưu trong vùng app được OS bảo vệ, gắn local profile, tối đa 24 giờ; UI cho xem/xóa. Khi có mạng và đã đăng nhập, hỏi `Gửi bài này để nhận nhận xét?`; chỉ sau xác nhận mới POST. Ảnh không được tự lưu hoặc upload lại; có thể chụp mới khi online. Đổi tài khoản trên máy không hiển thị bản nháp của người trước.
4. **Sự kiện và điểm:** metadata `ring/start/dismiss/complete_ungraded` có thể đồng bộ tối đa 7 ngày với idempotency; `dismiss` bao gồm Dừng khẩn cấp, không cần gửi lý do. Offline chỉ hiện tiến độ local `Chưa đồng bộ`; XP `+10/+6` chỉ khi backend chấm rõ. `+2` hoàn thành không chấm chỉ khi **server đã nhận attempt hợp lệ và ghi ledger**; metadata local riêng không đủ cấp điểm. Không trừ điểm nếu không gửi bài hoặc xóa bản nháp.
5. **Lỗi/timeout:** khi AI hoặc mạng lỗi, hiển thị `Chưa thể chấm. Bạn có thể kết thúc báo thức.`; Dừng khẩn cấp luôn dừng ngay. Không tự retry upload ảnh hoặc bài chữ khi người dùng đã từ chối.

**Contract tests P0:** cùng `Idempotency-Key`/payload trả cùng kết quả, khác payload 409; token người A không đọc session/bản xuất người B; không có `answerSpec`/rubric trong GET trước reveal; `snoozeMinutes` bị từ chối hoặc bỏ qua có thông báo ở mode thử thách; offline event không tự cấp XP; draft chưa đồng ý không được gửi; xóa tài khoản 202/kiểm trạng thái; AI `uncertain` không tăng số lần sai hoặc rank.

