# Bài làm có trình bày và chấm công bằng

**Trạng thái:** đặc tả để coding/đánh giá, chưa có bộ chấm chạy thật. Tài liệu này là nguồn chuẩn mới cho câu hỏi có trình bày ở báo thức, luyện tập, giao hữu và ranked; đọc cùng [ngân hàng câu](34-ngan-hang-cau-hoi-da-mon.md), [luật trận](35-solo-rpg-dong-bo-va-ky-nang.md), [quy định AI](14-vai-tro-va-quy-dinh-ai.md). Không gọi chấm AI là công tâm khi chưa có kiểm định người chấm.

## 1. Một câu = đáp án + cách nghĩ

Mỗi câu được phát hành cho chế độ có chấm cần `answer_spec` (kết luận kiểm được), `reasoning_prompt_vi` (một yêu cầu giải thích ngắn), `reasoning_rubric` (các ý/bước chấp nhận được, cách tương đương, lỗi nghiêm trọng), `rubric_revision`, `estimated_seconds`, `offline_gradable`, `grading_modes`. Không lấy câu trắc nghiệm nguồn ngoài rồi tự suy rubric từ đáp án A/B/C/D. Nếu câu không có rubric trình bày được người dạy duyệt, giữ `research_only` hoặc `practice_feedback_only`.

Người học chọn/nhập đáp án và **viết ít nhất một lý do hoặc bước làm** bằng ô chữ; có thể chụp giấy viết tay nếu đồng ý. Không buộc dùng camera, không buộc nét chữ đẹp, không chấm chính tả ngoài môn đang kiểm tra. Câu ngắn là một bước tư duy có thể làm trong 60–90 giây, không ép viết bài dài khi vừa thức dậy. Nút `Nộp bài` chỉ bật khi đã nhập phần giải thích; kiểm tra nhập liệu chỉ xác nhận có nội dung, không dùng độ dài/chữ mẫu để suy đúng sai. Người dùng vẫn có `Dừng khẩn cấp` ở báo thức mọi lúc.

| Dạng/môn | Đáp án cấu trúc | Phần trình bày ngắn | Điều kiện tránh chấm oan |
| --- | --- | --- | --- |
| Toán/Lý/Hóa | số/biểu thức + đơn vị khi cần | phép biến đổi, công thức và thay số hoặc lý do chọn | chấp nhận đường giải tương đương; kiểm tra đơn vị/tolerance |
| Sinh/Tin/Công nghệ | khái niệm/output/quy trình | nêu cơ chế hoặc bước quyết định | thuật ngữ đồng nghĩa và trường hợp biên duyệt sẵn |
| Anh | từ/cấu trúc/ý đọc | nêu dấu hiệu ngữ pháp hoặc dẫn chứng ngắn | không trừ vì diễn đạt tiếng Việt khác mẫu |
| Sử/Địa/Kinh tế & pháp luật | sự kiện/quan hệ/dữ kiện | một căn cứ từ tư liệu/bảng hoặc quan hệ nhân quả | nguồn và năm áp dụng rõ; câu tranh cãi chỉ luyện |
| Văn | nhận diện đặc điểm ngữ liệu | chỉ ra chi tiết trong đoạn và tác dụng ngắn | diễn giải mở chỉ phản hồi, không vào ranked/khóa chuông |

## 2. Rubric và quyết định chấm

Rubric v1 có tối đa **3 điểm nhận định**: đáp án cuối hợp lệ 1; luận cứ/bước 1 hợp lệ 1; luận cứ/bước 2 hoặc cách lý giải tương đương hợp lệ 1. Từng checkpoint ghi điều kiện đạt, các cách thay thế, lỗi logic rõ và ví dụ do người dạy duyệt. Với câu chỉ cần một bước, rubric ghi `reasoning_required=1` và điểm tối đa 2. Không dùng tổng điểm này làm RP hoặc sát thương trực tiếp.

- `correct`: kết quả cuối đúng theo validator và đạt ít nhất một checkpoint lý do bắt buộc, không có mâu thuẫn logic rõ. Đáp án đúng nhưng giải thích “đoán”, sao chép lại đề hoặc lý do không liên quan **chưa đủ**; trả `uncertain` nếu không phân biệt được thiếu/khác cách, `incorrect` chỉ khi thấy lỗi xác định.
- `incorrect`: kết quả sai đã xác minh, hoặc bước suy luận sai rõ ràng dù khoanh trúng. Phản hồi chỉ chỉ ra bước đầu cần xem lại; không trừ XP/streak.
- `uncertain`: ảnh mờ, OCR thiếu bước, rubric thiếu cách giải hợp lệ, AI/validator bất đồng, câu lỗi, timeout, model blocked. Không biến `uncertain` thành sai vì hết ngân sách. Người học có thể nhập lại/chụp lại; báo thức còn Dừng khẩn cấp.

AI chỉ trích bước nhìn thấy và đưa **đề xuất** `candidate_verdict` + chứng cứ checkpoint. Backend kiểm tra đáp án cấu trúc, schema, rubric/version và policy rồi ghi kết quả. AI không tự tính XP, HP, RP, MMR, streak hoặc “gian lận”. Nếu hai bài có cùng nội dung và rubric, server cùng dùng một `grading_policy_version`/model/prompt cố định cho toàn trận; thay model giữa trận phải void. Không giữ ảnh mặc định; tranh chấp ảnh chỉ lưu khi có đồng ý riêng, TTL và quyền xem hạn chế.

## 3. Khác nhau giữa chế độ

| Chế độ | Bài có trình bày | Khi AI không chắc/mất mạng | Điểm |
| --- | --- | --- | --- |
| Luyện | yêu cầu viết; được sửa/nộp lại | hiện `Chưa đủ rõ để chấm`, gợi ý nhập chữ | không phạt |
| Báo thức thử thách | yêu cầu viết trong đường chấm; câu dự phòng local | cho thử lại hoặc `Hoàn thành không chấm` sau nỗ lực, và luôn Dừng khẩn cấp; dừng âm thanh an toàn | chỉ cấp XP khi chấm rõ và server xác minh; không phạt khi dừng |
| Giao hữu | một bài/vòng, không hint trước reveal | vòng `needs_review`/void, không xử thua vì AI lỗi | không tính RP |
| Ranked (chưa bật) | cùng câu, cùng rubric, một bài/vòng | **void cả trận**, không đổi RP/MMR, hoàn phần thưởng nếu đã treo | chỉ server chốt thắng/hòa/thua sau khi cả hai bài có kết quả rõ |

Ranked chỉ bật cho từng `{môn,lớp,bộ nội dung,dạng câu}` sau khi có tập bài **độc lập do người dạy chấm**, đánh giá false-correct/false-incorrect, tỷ lệ `uncertain`, thời gian chấm và khiếu nại trên cả bài chữ lẫn ảnh. Ngưỡng phát hành phải chốt trước pilot trong `grading_policy_version`; khi chưa có dữ liệu thì `ranked_enabled=false`. Trong trận, UI hiện `Đang kiểm tra bài làm`; không hiện thắng/HP mới cho đến khi chốt. Nộp nhanh không cộng sát thương trong chế độ yêu cầu viết, vì tốc độ viết/ảnh/mạng không tương đương. Có nút `Báo chấm sai`; tranh chấp có thể void/reverse ledger bằng giao dịch bù trừ có audit, không sửa âm thầm.

## 4. Contract cho backend và câu hỏi

Question revision thêm `reasoning_prompt_vi`, `reasoning_rubric_json`, `required_reasoning_checkpoints`, `grading_modes`, `grading_policy_version`, `rubric_revision`, `reviewer_id`, `approved_at`. `reasoning_rubric_json` **server only** trước khi chấm/reveal. `answer_spec` và rubric của nguồn ngoài phải là bản biên tập đã duyệt, không phải lời giải AI tự sinh rồi đưa thẳng vào ranked.

Submission chung: `submission_id`, `question_id+revision`, `answer_value`, `reasoning_kind=text|handwritten`, `reasoning_text` hoặc ảnh tạm, `client_attempt_id`, `submitted_at`. Server lấy `uid` từ token, không nhận `is_correct`/`score`/`hp` từ client. Giới hạn kích thước và MIME ảnh theo docs/07; chữ có giới hạn độ dài an toàn. Đáp ứng: `result=correct|incorrect|uncertain`, `answer_valid`, `reasoning_checkpoints[]` (mã/đạt/chưa rõ, không lộ rubric trước reveal), `first_issue`, `rubric_revision`, `grading_policy_version`, `next_actions`, `request_id`. Không trả toàn bộ chain-of-thought AI.

Lưu `grading_decisions(id,submission_id,question_revision,answer_validator_version,rubric_revision,policy_version,model_version,prompt_version,result,reason_codes,created_at)` và `grade_reviews(id,decision_id,reporter_id,state,resolution,created_at)` với quyền/TTL phù hợp. Ảnh bài không nằm trong event WebSocket, log hoặc analytics. Trong trận, `round_submissions` trỏ decision; chốt vòng chỉ khi cả hai `correct/incorrect` hoặc timeout đã xác minh; `uncertain` → void.

## 5. Độ khó ngày đầu và tăng dần

`difficulty_band` là 1–4 do người biên tập gán, sau đó hiệu chuẩn bằng tỷ lệ đúng/thời gian. **Ba phiên luyện/báo thức có bài chấm hợp lệ đầu tiên ở band 1**, không phải ba ngày liên tiếp; bỏ ngày không làm nhảy khó. Từ phiên 4, xét cửa sổ 5 phiên cùng môn/chủ đề: ≥4 `correct` và ít `uncertain` → đề xuất tăng **một** band; ≤1 `correct` → giảm một band; còn lại giữ. Tối đa tăng một band sau mỗi 7 phiên hợp lệ. Người dùng chọn trần `Dễ/Vừa/Thử thách`; AI không tự nâng vượt trần. Chủ đề mới bắt đầu thấp hơn tối đa một band để tránh đột ngột. Rank/XP/streak không quyết định band. Khi thiếu câu đủ chất lượng, giữ band hoặc chuyển `Chỉ báo thức`, không phát câu chưa duyệt.

Ranked dùng bộ 3 câu đã khóa với độ khó **giống hệt cho hai người**; adaptive cá nhân không áp vào trận. Lần đầu đấu có thể giao hữu/placement, không cho người mới gặp đề vượt chương trình đã xác nhận. Dữ liệu nghiên cứu VNHSGE/VMLU **không có nhãn band đáng tin cho từng câu**; không tự gán từ split hoặc vị trí trong file.

## 6. Test cần viết khi coding

`G01` đáp án đúng nhưng thiếu/lý do sai rõ; `G02` cách giải tương đương hợp lệ; `G03` chữ viết mờ/AI bất đồng; `G04` cùng nội dung hai người → cùng kết quả, model/rubric khóa; `G05` double submit/retry không nhân XP/RP; `G06` offline alarm vẫn dừng được và không giả chấm; `G07` ba phiên đầu band 1, bỏ ngày/đổi chủ đề/đạt trần; `G08` ranked uncertain/appeal void hoặc bù trừ có audit. Đo trên tập người chấm độc lập, không chỉ test fixture do chính prompt sinh.
