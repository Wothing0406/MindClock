# Ngân hàng câu hỏi nhiều môn và quyền nguồn

**Quy tắc P0:** câu chấm/cho XP đến từ ngân hàng **đã được đội và người có chuyên môn duyệt**, không sinh trực tiếp khi chuông reo/ghép trận. Gemini có thể đề xuất bản nháp hoặc gợi ý, không tự publish. `data/sources/registry.json` là metadata; corpus nghiên cứu local không phải ngân hàng đã tích hợp. [AI/chấm](06-ai-va-cham-bai.md), [SQL](03-du-lieu-sql.md).

## 1. Một item xuất bản cần gì

```json
{
  "questionId": "team-math9-001",
  "revision": 1,
  "locale": "vi-VN",
  "subjectCode": "TOAN",
  "gradeBand": "9",
  "curriculumId": "vietnam-2026-reviewed",
  "topicId": "linear_equation",
  "learningOutcome": "Giải phương trình một ẩn đơn giản",
  "difficultyBand": 1,
  "formatType": "short_answer",
  "stem": "Giải 2x + 4 = 10.",
  "reasoningPromptVi": "Viết một bước biến đổi bạn đã làm.",
  "answerSpec": {"canonicalValue": "3", "acceptedVariants": ["x=3"]},
  "rubric": {"requiredCheckpoints": ["trừ 4 hai vế", "chia 2 hai vế"]},
  "modeEligibility": ["practice", "alarm"],
  "source": {"kind": "team_authored", "licenseScope": "team_owned"},
  "status": "draft"
}
```

Ví dụ **chỉ là bản nháp minh họa**, không tự được coi đã có reviewer. Bản published cần `editorId`, `reviewerId`, `approvedAt`, `rubricRevision`, `contentHash`, `scoringPolicyVersion`, bằng chứng quyền. Answer/rubric giữ server-only trước reveal. Sửa stem/đáp án/rubric tạo revision bất biến; phiên/trận ghim revision.

## 2. Taxonomy và format

`subject → gradeBand → curriculumId → topicId → learningOutcome → difficultyBand(1–4) → formatType`. Cohort đầu THPT 10–12 dùng catalog có nguồn Bộ GD&ĐT/reviewer; môn người dùng chọn phải khớp lớp và chương trình, trường hợp môn riêng có lịch nhưng chưa chắc có pool. Hỗ trợ `single_choice`, `true_false_4`, `short_answer`, `open_response` với UI/rubric riêng; không tự biến câu cũ 4 lựa chọn thành đúng/sai. Toán/Lý/Hóa có đáp số, đơn vị, tolerance và bước giải; Anh có accepted variants/ngữ pháp, phát âm chỉ nghiên cứu; Sử/Địa/Sinh/Tin/Kinh tế pháp luật cần nguồn/thuật ngữ; Ngữ văn/đọc hiểu mở dùng feedback, **không chấm nhị phân ranked** khi chưa kiểm định. Một câu khoanh đúng nhưng lý do sai rõ không được coi hiểu đúng trong luồng yêu cầu trình bày. [Catalog](10-catalog-chuong-trinh-va-ke-hoach.md).

Trong alarm và PvP, ngân hàng xuất bản phải có phiên bản **tự luận ngắn đã được người duyệt chuyển thể**: prompt, đáp án, checkpoint trình bày, cách giải tương đương, thời gian ước lượng và rubric. Gemini có thể tạo bản nháp chuyển trắc nghiệm thành tự luận để biên tập viên xem, nhưng không publish/chấm điểm tự động từ câu chuyển thể chưa duyệt. Điều này giảm gọi model đúng giây reo/ghép trận và tránh câu mơ hồ. Ảnh chụp mới từ camera có thể yêu cầu trong mode cụ thể, song vẫn có đường nhập chữ và không chống điện thoại thứ hai; tốc độ/ảnh không tự là nhãn gian lận.

Mỗi môn có trạng thái `not_available`, `practice_only`, `friendly_enabled`, `ranked_enabled` theo chất lượng nội dung/chấm, không theo nhu cầu marketing. Tổ hợp thi là tập môn người học chọn, không ép toàn bộ; trong PvP chỉ ghép khi có **một môn chung cùng khối/chương trình/pool**. Không có câu đã duyệt: UI nói rõ, cho chọn môn khác/ôn sau/chỉ chuông.

## 3. Chọn câu và adaptive

Ưu tiên môn trong TKB hôm nay đã được người dùng xác nhận, sau đó môn ưu tiên/chủ đề yếu/câu chưa lặp. Ba **phiên có bài chấm hợp lệ** đầu của mỗi người ở band 1, không phải ba ngày liên tục. Từ phiên 4, xét 5 phiên cùng môn/chủ đề: ≥4 đúng và ít uncertain → đề xuất +1 band; ≤1 đúng → −1; còn lại giữ. Tối đa +1 band sau 7 phiên hợp lệ; không vượt trần Dễ/Vừa/Thử thách do người dùng chọn. Thiếu câu đủ chất lượng thì giữ band/chọn môn khác, không phát AI draft cho XP. Rank không quyết định độ khó báo thức. PvP dùng cùng bộ/rubric cho hai bên, không áp adaptive riêng trong trận.

## 4. Pipeline nội dung và dữ liệu ngoài

`registry + quyền → raw local cách ly → parse → normalize → quarantine lỗi/trùng/quyền → người dạy duyệt đáp án/rubric/độ khó → publish revision → pool theo mode`. Import mặc định `dry_run`, không có `publish_all`. Báo cáo số `seen/parsed/quarantined/awaiting_rights/awaiting_rubric/reviewed/published` và hash/adapter version. Raw corpus/ảnh bên thứ ba không commit, không đưa lên cloud/app khi chưa có quyền từng nguồn/item/ảnh. Repo VNHSGE/VMLU/ViMMRC được nêu trong tài liệu cũ chỉ là **nguồn nghiên cứu**, không tự có giấy phép phát hành câu/ảnh; không suy nhãn độ khó từng câu từ tên dataset. Item mơ hồ, đáp án thiếu, hình/LaTeX lỗi, không hợp chương trình → quarantine.

## 5. QA nội dung

Hai người (biên tập/reviewer) độc lập kiểm stem, đáp án, giải thích, rubric, phương án nhiễu, câu chữ `vi-VN`, bản quyền, khối/năm, thời gian ước lượng và mọi cách giải hợp lệ. Content test cho variant trùng, đơn vị, dấu thập phân, bốn ý đúng/sai đủ, đáp án thuộc lựa chọn, script injection trong stem, asset tồn tại, publish không reviewer, retire revision đang dùng. Trước ranked cần thử với người học để hiệu chuẩn tỷ lệ đúng/thời gian và đánh giá chấm công bằng. [Test matrix](../03-quality/01-ke-hoach-kiem-thu.md).
