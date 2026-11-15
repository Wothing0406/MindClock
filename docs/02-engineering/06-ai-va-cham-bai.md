# Gemini, Socratic và chấm bài công bằng

**Vai AI:** gợi ý nội dung nháp, đọc ảnh/lời giải, đề xuất feedback, hỏi gợi mở, diễn đạt kế hoạch và đối thoại trong phòng học. **Vai backend:** xác minh catalog/câu/rubric/quyền, quyết định `correct|incorrect|uncertain`, XP/tiến độ, giới hạn chi phí và audit. AI không gán gian lận, HP/RP/rank/streak hoặc tự phát câu scored. Không gửi API key tới app. [Question bank](05-ngan-hang-cau-hoi.md), [planner](10-catalog-chuong-trinh-va-ke-hoach.md), [phòng học](09-phong-hoc-realtime.md), [API](04-hop-dong-api.md).

## 1. Quy trình nộp và chấm

1. Client gửi `answerValue` và `reasoningText` hoặc ảnh sau khi người dùng xem/xác nhận, có `clientAttemptId`, session/question revision và idempotency key. Ảnh bị giới hạn kích thước/MIME/magic bytes, xử lý tạm, xóa khi thành công/lỗi/timeout.
2. Backend xác minh Firebase token, owner, session state, question `published`/mode, revision/rubric; không nhận đáp án chuẩn từ client. Với dạng xác định, chạy validator riêng (số, đơn vị, accepted variants) trước/đồng thời AI.
3. Gemini nhận **chỉ** câu/rubric cần thiết và bài đã nộp; instruction không tiết lộ đáp án sớm, đọc bước **thực sự nhìn thấy**, nêu chỗ mờ/chưa chắc, trả JSON schema: `readable`, `observedSteps[]`, `finalAnswer`, `candidateVerdict`, `firstIssueStepIndex`, `issueReason`, `confidenceSignal`, `hint`.
4. Backend validate JSON và ngữ nghĩa. AI `correct` nhưng validator/rubric bất đồng → `uncertain`; ảnh mờ/thiếu bước, câu lỗi, timeout, model blocked → `uncertain`. Không biến thiếu ngân sách thành sai. Chỉ server ghi attempt/XP hợp lệ trong transaction; log request ID/latency/model/question revision, **không ảnh, token, lời giải cá nhân**.
5. Trả feedback ngắn về bước đầu cần xem, không trả chain-of-thought model. Có `Báo chấm sai`; review có audit. Offline: hoàn thành không chấm, không tự cấp XP.

## 2. Quy tắc quyết định

| Tình huống | Kết quả | Hệ quả |
| --- | --- | --- |
| Đáp án và checkpoint trình bày hợp lệ | `correct` | Server cấp XP theo policy/version nếu đủ điều kiện, đúng một lần. |
| Đáp án sai hoặc lý do sai rõ, chứng cứ đủ | `incorrect` | Cho thử lại; không trừ uy tín/rank. |
| Ảnh mờ, bước thiếu, nhiều cách hiểu, AI/validator bất đồng, rubric lỗi, timeout | `uncertain` | Không tính sai, không tăng wrong count; nhập chữ/chụp lại/ôn sau. |
| Câu AI tự sinh chưa duyệt | Feedback luyện không scored | Không XP/ranked; label rõ. |

Chế độ thử thách chỉ trả gợi ý công khai từ lần **incorrect rõ thứ 3**; trước đó không lộ qua response field, analytics hoặc khác biệt lỗi. Socratic đưa một câu hỏi/công thức/bước kế tiếp, không lời giải cuối trước nỗ lực. Sau khi kết thúc, có thể xem lời giải đã duyệt.

## 3. Model, quota, consent

Model ID/prompt/schema/validator/grading policy đặt ở cấu hình server và log phiên bản. Không hardcode tên model giả định còn hiệu lực; trước task tích hợp cần kiểm docs nhà cung cấp, quota, region, giá và quyền dữ liệu tại thời điểm triển khai. Có timeout ngắn hơn client, circuit breaker/fallback, cache nội dung đã duyệt, hạn lượt theo user/route và budget ngày. Realtime audio/camera chỉ opt-in, giới hạn phiên/lượt, có nút dừng rõ và phương án text. Không quan sát camera liên tục để chấm “sao nhãng”. Phòng học dùng giọng `quiet|gentle|firm` nhưng cùng chính sách: không nhục mạ, đe dọa, thao túng cảm xúc; user có thể tắt nhắc. AI không được nói mình là người thật. Camera frame bài chỉ sau user chọn/xem lại, không lấy stream để suy lười học.

## 4. Bộ đánh giá trước pilot

Tập bài do người dạy chấm độc lập, đa môn/khối/ánh sáng/chữ/cách giải, có ca sai rõ, đúng nhiều cách, thiếu bước, prompt injection trong ảnh, ảnh người khác, câu không rubric. Báo `false_correct`, `false_incorrect`, `uncertain_rate`, latency p50/p95, cost/attempt, sai lệch theo nhóm. Ngưỡng release chốt **trước** khi xem kết quả; nếu chưa đạt, giảm phạm vi dạng câu/môn, trả uncertain hoặc tắt chấm ảnh. Test không lấy output Gemini tự chấm chính nó làm nhãn chuẩn. Ranked chỉ mở cho cohort câu/dạng đã đạt và khi `uncertain` void trận, không tính RP. [Quality](../03-quality/01-ke-hoach-kiem-thu.md).
