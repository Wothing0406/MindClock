# Gemini, Socratic và chấm bài công bằng

**Vai AI:** gợi ý nội dung nháp, đọc ảnh/lời giải, đề xuất feedback, hỏi gợi mở, diễn đạt kế hoạch và đối thoại trong phòng học. **Vai EduSkills-VN:** quy tắc bộ môn để biên tập câu/rubric và hướng dẫn chấm phiên bản nhỏ theo từng tác vụ; không phải model chấm hoặc nguồn điểm. **Vai backend:** xác minh catalog/câu/rubric/quyền, quyết định `correct|incorrect|uncertain`, XP/tiến độ và audit. AI không gán gian lận, HP/RP/rank/streak hoặc tự phát câu scored. Không gửi API key tới app. [Question bank](05-ngan-hang-cau-hoi.md), [EduSkills](11-eduskills-vn-tich-hop.md), [planner](10-catalog-chuong-trinh-va-ke-hoach.md), [phòng học](09-phong-hoc-realtime.md), [API](04-hop-dong-api.md).

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

Chế độ thử thách chỉ trả gợi ý công khai từ lần **incorrect rõ thứ 3**; trước đó không lộ qua response field, analytics hoặc khác biệt lỗi. Từ lần `incorrect` rõ thứ 5 mở `Bỏ lượt`; backend đếm theo attempt ID duy nhất, `uncertain`/lỗi hệ thống không tăng. Socratic đưa một câu hỏi/công thức/bước kế tiếp, không lời giải cuối trước nỗ lực. Sau khi kết thúc, có thể xem lời giải và đoạn kết mở màn đã duyệt. `Bỏ lượt` không có EXP/ngày chuỗi mới; không trừ EXP/RP đã có. Dừng âm khẩn cấp không chờ AI.

## 3. Model, quota, consent, tái tạo câu khó & Hiển thị công thức

Model ID/prompt/schema/validator/grading policy đặt ở cấu hình server (`GEMINI_PRIMARY_MODEL`, `GEMINI_FAST_MODEL`, `GEMINI_LIVE_MODEL` trong `.env` server) và log phiên bản. Phải dùng **tên model Gemini Developer API thực tế đang hỗ trợ** (ví dụ `gemini-2.5-flash`, `gemini-2.5-flash-lite`; không dùng tên model giả định không tồn tại trên endpoint). Có timeout ngắn hơn client, circuit breaker/fallback, cache nội dung đã duyệt, hạn lượt theo user/route và budget ngày.

- **Tái tạo câu hỏi thực tế đa giai đoạn từ ngân hàng câu (T060):** Endpoint tạo câu cá nhân hóa nhận thêm `stage` (`foundational` / `applied` / `advanced`), tham chiếu câu gốc từ ngân hàng đã duyệt (`seedQuestionId`, `topicId`, `gradeLevel`) để tái tạo đề bài gắn ngữ cảnh thực tế với số liệu/tình huống mới, rubric bước giải rõ ràng và đáp án đối chiếu. Không lấy key Gemini xuống Flutter.
- **Hiển thị ký hiệu Toán/Lý/Hóa & Bàn phím công thức (T060):** Câu hỏi, gợi ý và ô nhập đáp án hỗ trợ hiển thị chuẩn ký hiệu mũ ($x^2$, $10^{-3}$), phân số ($\frac{a}{b}$), phần trăm ($\%$), đạo hàm ($f'(x)$), tích phân ($\int$), căn bậc hai ($\sqrt{\phantom{x}}$), ký tự Hy Lạp ($\Delta, \pi, \Omega$) và thanh **bàn phím nhập nhanh công thức (`MathInputKeypad`)** trên mobile.

Realtime audio/camera chỉ opt-in, giới hạn phiên/lượt, có nút dừng rõ và phương án text. Không quan sát camera liên tục để chấm “sao nhãng”. Phòng học dùng giọng `quiet|gentle|firm` nhưng cùng chính sách: không nhục mạ, đe dọa, thao túng cảm xúc; user có thể tắt nhắc. AI không được nói mình là người thật. Camera frame bài chỉ sau user chọn/xem lại, không lấy stream để suy lười học.

## 4. Bộ đánh giá trước pilot

Tập bài do người dạy chấm độc lập, đa môn/khối/ánh sáng/chữ/cách giải, có ca sai rõ, đúng nhiều cách, thiếu bước, prompt injection trong ảnh, ảnh người khác, câu không rubric. Báo `false_correct`, `false_incorrect`, `uncertain_rate`, latency p50/p95, cost/attempt, sai lệch theo nhóm. Ngưỡng release chốt **trước** khi xem kết quả; nếu chưa đạt, giảm phạm vi dạng câu/môn, trả uncertain hoặc tắt chấm ảnh. Test không lấy output Gemini tự chấm chính nó làm nhãn chuẩn. Ranked chỉ mở cho cohort câu/dạng đã đạt và khi `uncertain` void trận, không tính RP. [Quality](../03-quality/01-ke-hoach-kiem-thu.md).
