# Hướng dẫn tích hợp API cho mobile, backend và Gemini

Tài liệu này chỉ rõ **cách dùng** hợp đồng tại [07](07-hop-dong-api-va-ai.md), không thay thế định nghĩa endpoint. Không gọi Gemini/Firebase Admin trực tiếp từ Flutter.

## 1. Chuẩn bị môi trường

1. Tạo Firebase project riêng cho `local/staging/production`; bật Authentication và Firestore; rules mặc định deny-all, kiểm thử emulator.
2. Tạo backend FastAPI có service account/identity riêng với quyền tối thiểu; xác minh Firebase ID token nhận từ mobile theo [Firebase Admin SDK](https://firebase.google.com/docs/auth/admin/verify-id-tokens).
3. Tạo Gemini API key chỉ ở backend secret store. Trước khi dùng ảnh học sinh thật, rà soát tier/điều khoản dữ liệu như [quy định AI](14-vai-tro-va-quy-dinh-ai.md).
4. Cấu hình model, promptVersion, timeout, quota, image size, feature flags theo môi trường. Pin phiên bản SDK vào lockfile khi code; tài liệu Google thay đổi nên tra docs lúc triển khai.

## 2. Mobile gọi MindClock API

| Tình huống | Thao tác | Lưu ý |
| --- | --- | --- |
| Sau đăng nhập | Lấy Firebase ID token hiện hành, gọi `/v1/me` | Gửi token qua HTTPS; refresh khi 401 hợp lệ, không log token |
| Lưu báo thức | POST/PATCH `/v1/alarms`; sau response lập lịch OS | Cập nhật UI theo **kết quả OS**, không chỉ API response |
| Lưu lịch | PUT `/v1/timetable` | Dùng `revision` để tránh ghi đè khi nhiều thiết bị |
| Tải câu | GET `/v1/challenges/next?date=...` | Cache prompt/revision local, không cache đáp án |
| Chuông reo | Không gọi API trước khi phát âm; xếp event local | Sync sau khi app/mạng sẵn sàng |
| Gửi bài | POST multipart `/v1/sessions/{id}/attempts` | Chỉ sau nút “Gửi bài”; nén ảnh và giới hạn 5 MB |
| Xem điểm | GET `/v1/progress/summary` | Không tự tính XP có thẩm quyền trên client |

**Timeout client:** 15 giây cho chấm ảnh; network retry có backoff và **giữ nguyên Idempotency-Key**. 401: refresh token một lần rồi retry. 409: tải state/revision mới. 413/415: báo chụp lại. 429/503/504: chuyển không chấm, cho kết thúc. Không retry upload ảnh vô hạn.

### Ví dụ request tạo phiên

```http
POST /v1/sessions HTTP/1.1
Authorization: Bearer <FIREBASE_ID_TOKEN>
Content-Type: application/json
Idempotency-Key: <UUID-CUA-PHIEN>

{"alarmId":"alarm_01","localSessionId":"local_01","localDate":"2026-11-16","questionId":"math9-linear-001","questionRevision":3,"startedAt":"2026-11-15T23:31:00Z"}
```

Server trả `sessionId`, `state`, `version`. `startedAt` là UTC do client ghi, được server kiểm tra hợp lý; không dùng nó một mình để chứng minh người dùng đã dậy đúng giờ.

### Ví dụ gửi bài

```text
POST /v1/sessions/{sessionId}/attempts
Headers: Authorization, Idempotency-Key, Content-Type: multipart/form-data
Fields: clientAttemptId, questionId, submissionKind=handwritten, image=<JPEG/PNG>
Response: result, observedSteps, firstIssue, feedback, hint, nextActions, xpAwarded
```

Client chỉ dùng `nextActions` để hiện các nút hợp lệ; không tự quyết “đúng” từ ảnh hay kết quả cuối do người học nhập.

## 3. Backend gọi Gemini

1. Xác thực người dùng/phiên và giới hạn tần suất **trước** khi gọi model.
2. Lấy câu và rubric bằng `questionId + revision` từ Firestore; chỉ sử dụng bản `published` hợp lệ cho attempt mới.
3. Gửi ảnh ở dạng inline nếu phù hợp giới hạn của SDK/request, hoặc File API khi cần theo [Gemini image understanding](https://ai.google.dev/gemini-api/docs/image-understanding). Chọn một đường, kiểm soát xử lý/lưu tệp và dọn dữ liệu tạm.
4. Gửi system instruction từ [quy định AI](14-vai-tro-va-quy-dinh-ai.md), prompt câu/rubric và schema structured output. Không đưa secret, profile học sinh, lịch cá nhân không cần thiết vào prompt.
5. Parse JSON, validate schema, đối chiếu validator kết quả; kết luận `correct/incorrect/uncertain` ở server. [Gemini structured outputs](https://ai.google.dev/gemini-api/docs/structured-output) yêu cầu kiểm tra giá trị dù JSON hợp lệ.
6. Ghi attempt và XP ledger transaction; trả feedback tiếng Việt đã giới hạn độ dài. Dọn ảnh tạm trong `finally` tương đương.

**Interface nội bộ gợi ý:** `QuestionSelector.select(uid, localDate)`, `GradeService.grade(questionRevision, image|answerText)`, `AnswerValidator.verify(answerSpec, observedAnswer)`, `ProgressService.record(session, gradeResult)`. Interface này giúp thay Gemini model hoặc tắt chấm mà không sửa alarm.

## 4. Firebase/Firestore thao tác nào ở đâu

| Tác vụ | Thực hiện tại | Bảo đảm |
| --- | --- | --- |
| Đăng nhập | Firebase client SDK trên mobile | ID token hợp lệ |
| Xác minh danh tính | Firebase Admin SDK trên backend | UID từ token, không từ body |
| Chọn câu | Backend truy vấn question bank | Chỉ bản published, đúng revision |
| Ghi session/attempt | Backend Firestore SDK | Quyền sở hữu + state machine |
| Ghi XP/streak | Backend transaction | Idempotent theo `eventId` |
| Đồng bộ alarm config | Backend và mobile local schedule | Hai trạng thái rõ: lưu server/đặt OS |
| Đọc lịch sử cá nhân | Backend hoặc Firestore rules đã test | Không đọc chéo uid |

Không đặt Firestore listener liên tục cho toàn bộ `attempts`; progress summary được đọc theo nhu cầu. Index chỉ tạo cho truy vấn thực tế. Không dùng Storage cho ảnh MVP nếu đã chọn xử lý tạm.

## 5. Mock và fixture để hai bên coding song song

Chuẩn bị fixture JSON cho: `question_next`, `grade_correct`, `grade_incorrect`, `grade_uncertain_blurry`, `grade_timeout`, `permission_denied`, `session_conflict`, `progress_summary`. Mobile dùng fixture để dựng UI trước; backend dùng cùng fixture làm contract test. Mỗi fixture có `schemaVersion`, `questionRevision` và tiếng Việt đã duyệt. Khi API thật khác fixture, cập nhật contract trước khi ghép.

## 6. Quy định lỗi và quan sát

Mỗi request có `requestId` (server phát), trace latency theo từng tầng auth/DB/AI/validation, không log payload ảnh/token. Metrics chỉ dùng dữ liệu tổng hợp. Với request chấm có lỗi, server trả mã lỗi và hành động an toàn; app không hiển thị raw Gemini response. Có alert khi tỷ lệ `uncertain`, 5xx hoặc chi phí tăng bất thường. Thử toàn bộ lỗi trên staging trước pilot.

