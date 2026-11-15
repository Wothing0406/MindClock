# Tích hợp EduSkills-VN vào nội dung và chấm bài

**Nguồn:** [EduSkills-VN](https://github.com/Wothing0406/EduSkills-VN) của nhóm. Đây là **bộ quy tắc sư phạm, chuẩn hóa và tạo prompt**, không phải kho câu hỏi đã duyệt hay model chấm bài. Bản tích hợp đầu là thiết kế; chưa có adapter chạy trong FastAPI. [Ngân hàng câu](05-ngan-hang-cau-hoi.md), [AI/chấm](06-ai-va-cham-bai.md), [catalog](10-catalog-chuong-trinh-va-ke-hoach.md).

## 1. Phạm vi dùng được

| Nguồn EduSkills | Việc trong MindClock | Ranh giới |
| --- | --- | --- |
| `tao-quiz-bgd` + skill môn THPT | Đề xuất câu, chuẩn thuật ngữ, lỗi sai, cách giải và rubric cho người biên tập | Đầu ra là `draft`; reviewer kiểm chương trình, quyền và đáp án trước publish. |
| `giai-chi-tiet`/Socratic | Biên soạn gợi ý từng bước và giải thích sau lượt | Không dùng nguyên prompt bốn tầng để trả lời lúc người học chưa nỗ lực; dễ lộ đáp án. |
| `tomtat-mindmap` + skill môn | Tóm tắt sau lượt, gợi ôn chuyên đề yếu | Không tự gán mức học hoặc câu scored. |
| Parser/OCR của repo | Gợi trích thời khóa biểu/tài liệu **in** để người dùng xác nhận | Tesseract.js không phù hợp làm bộ đọc bài giải viết tay có thẩm quyền; [FAQ chính thức](https://github.com/naptha/tesseract.js/blob/master/docs/faq.md). |

Skill môn là tài liệu cho agent và pipeline server, **không phải code mobile tự chạy**. Không bundle toàn bộ Markdown/metadata sách lên client. Chỉ mang nội dung cần thiết và có quyền vào từng tác vụ. Repo MIT cho mã không đồng nghĩa quyền công bố mọi trang sách, đề, ảnh hoặc liên kết Drive.

## 2. Hợp đồng nội dung của một lượt sáng

`MorningCard` là cặp **mở màn + câu hỏi + rubric + đoạn kết**, cùng `questionRevision` và `contentHash`:

```json
{
  "cardId": "physics10-inertia-01",
  "questionId": "physics10-inertia-01-q",
  "questionRevision": 1,
  "grade": 10,
  "subjectCode": "physics",
  "topicId": "inertia",
  "learningOutcome": "Giải thích biểu hiện của quán tính trong tình huống quen thuộc",
  "hook": {
    "durationTargetSeconds": 9,
    "setupVi": "Xe dừng lại. Chiếc cặp trên ghế vẫn lao về phía trước…",
    "cliffVi": "Điều gì khiến chiếc cặp tiếp tục chuyển động?",
    "staticFallbackVi": "Xe dừng, chiếc cặp tiếp tục chuyển động. Vì sao?",
    "assetId": "team-owned-physics10-inertia-01"
  },
  "question": {
    "stemVi": "Nêu hiện tượng vật lí và giải thích bằng một ý.",
    "responseMode": "short_reasoning",
    "estimatedSeconds": 90
  },
  "revealVi": "Sau lượt học, xem đoạn kết và lời giải đã duyệt."
}
```

Đây là **ví dụ cấu trúc**, chưa phải câu đã duyệt. `MorningCard.learningOutcome` phải trùng outcome đã duyệt của `questionId + revision`; hook phải minh họa đúng outcome đó, không chứa đáp án hoặc quảng cáo. `reveal` xem được khi phiên kết thúc dù đúng hay bỏ lượt. Asset nhẹ, tải/cached trước, có fallback chữ và Reduce Motion. Bỏ qua hook không bỏ qua câu. Câu chỉ mở scored khi question/rubric/hook có trạng thái published, reviewer và quyền. Không gọi Gemini để dựng video/câu ngay lúc chuông reo.

## 3. Pipeline biên tập và runtime

1. **Biên tập ngoại tuyến:** input `catalogVersion + grade + subject + topic + learningOutcome + nguồn được phép`; chọn skill môn và `tao-quiz-bgd`; tạo `questionDraft`, `rubricDraft`, `hookDraft`, `hintStep`, `revealDraft`. Không có nguồn/chuyên đề hợp lệ thì dừng draft.
2. **Duyệt:** biên tập viên và reviewer bộ môn kiểm câu, các lời giải tương đương, checkpoint, độ khó/thời gian, hook liên quan, quyền tài sản, không lộ đáp án. Publish revision bất biến; giữ `eduSkillsCommit`, `promptTemplateVersion`, `reviewerId`, `rightsRef` để truy vết.
3. **Trước giờ reo:** backend chọn `MorningCard` published theo lớp/môn/TKB/band và gửi gói công khai tối thiểu cho cache local. Answer/rubric/reveal có quyền vẫn server-only; fallback không câu thì báo rõ và không cấp XP.
4. **Nộp:** app gửi đáp án + bước giải chữ hoặc ảnh có xác nhận. FastAPI kiểm auth/session/revision/idempotency; validator theo môn kiểm các điều kiện xác định. Gemini Vision/Text dùng **đoạn hướng dẫn chấm đã rút gọn từ EduSkills** và rubric của câu để đề xuất `correct|incorrect|uncertain` cùng chứng cứ bước.
5. **Chốt:** backend đối chiếu candidate với validator/rubric; bất đồng/ảnh mờ/thiếu bước/AI lỗi → `uncertain`. Chỉ verdict `correct` chắc mới cấp EXP/chuỗi theo policy. Từ lần sai rõ 3 trả `hintStep`; từ lần 5 cho `abandon`. Sau kết thúc mới trả lời giải/đoạn kết.

Không nhập nguyên prompt EduSkills hiện tại vào mọi request: mã tạo prompt của repo có chế độ **tự sinh và giải trọn bài**, phù hợp tác vụ biên tập hoặc giải thích sau lượt, không phù hợp gợi ý trước khi nộp. [Mã prompt generator](https://github.com/Wothing0406/EduSkills-VN/blob/main/backend/ocr-engine.js). Nên export từng policy nhỏ, có version và test, sang dịch vụ FastAPI hiện có; không dựng thêm Node server chỉ để dùng skill.

## 4. Chế độ prompt và kiểm định

| Chế độ | Được trả | Không được trả trước khi kết thúc |
| --- | --- | --- |
| `AUTHOR_DRAFT` | Câu/rubric/hook/đoạn kết cho người duyệt | Tự publish hoặc cấp quyền nguồn. |
| `GRADE_CANDIDATE` | Bước đọc được, lỗi đầu tiên, candidate verdict, tín hiệu không chắc | XP/streak/gian lận hoặc lời giải cho client. |
| `HINT_ONE_STEP` | Một câu hỏi gợi mở/checkpoint từ hint đã duyệt | Đáp án cuối và toàn bộ lời giải. |
| `POST_ATTEMPT_EXPLAIN` | Giải thích đã duyệt sau khi phiên kết thúc | Thay đổi verdict/EXP bằng lời giải mới. |

Đánh giá trên bài thật được người dạy gán nhãn độc lập, đa môn/khối/chữ viết/cách giải tương đương; đo false-correct, false-incorrect, uncertain và lỗi lộ đáp án. Test riêng số lần sai 3/5, retry kép, mạng đứt, câu bị retire, hook và câu lệch kiến thức. Khi thiếu dữ liệu đánh giá cho một môn, chỉ dùng EduSkills để soạn nội dung/feedback luyện tập, không bật chấm scored hoặc ranked cho môn đó.
