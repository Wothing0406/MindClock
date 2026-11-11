# Nguồn dữ liệu câu hỏi và đường nhập an toàn

**Trạng thái:** đã tải VNHSGE và một mirror VMLU vào **khu nghiên cứu local bị Git bỏ qua**, chưa nạp câu nào vào ngân hàng MindClock hay app. [Manifest](../data/research/research-manifest.json) ghi commit, hash, số item thực đọc; [hướng dẫn khu nghiên cứu](../data/research/README.md) nêu ranh giới. Chỉ `published` sau khi có quyền tái sử dụng, đối chiếu chương trình, rubric trình bày, người duyệt nội dung và test đáp án. Mốc kiểm tra nguồn: 11/11/2026.

## 1. Đánh giá ba nguồn người dùng đề xuất

| Nguồn | Điều xác nhận từ nguồn gốc | Quyết định MindClock |
| --- | --- | --- |
| [VNHSGE](https://github.com/Xdao85/VNHSGE) | README nêu khoảng 19.000 câu chọn đáp án và 300 mục Văn, nhiều đề cũ/đề thử; repo không nêu licence tái sử dụng rõ, có đề từ sách đề thi thử. Bản local **406 JSON/17.054 mục** ở commit ghi trong manifest; thiếu ảnh/Word. JSON thực dùng hai schema `Question/Choice/Explanation` và mục Văn tiếng Việt, không chỉ key ví dụ README `Q/C/E`. | **Research local only**. Cần xác minh quyền **từng nhóm đề/ảnh/giải thích**, năm, chương trình, đáp án; không tự publish. Số đọc được không bằng số công bố và không có nghĩa 17.054 câu dùng được. |
| [VMLU](https://github.com/ZaloAI-Jaist/VMLU) | Benchmark 10.880 câu/58 lĩnh vực, nhiều lĩnh vực ngoài THPT; README `Licenses` còn `TBU`, dù mã repo MIT. Bản local lấy từ [mirror cộng đồng](https://huggingface.co/datasets/tridm/VMLU), **3 JSONL/10.880 mục**; `test.jsonl` 9.833 mục **không có trường đáp án**, 1.047 mục train/valid có đáp án. Mirror không chứng minh tính chính thức hay quyền tái sử dụng. | Chỉ nghiên cứu cấu trúc/đánh giá nội bộ theo điều kiện nguồn; không dùng tập test không đáp án để chấm, không đưa câu lên sản phẩm. Cần xác minh với nguồn chính thức, quyền nội dung và phù hợp môn/lớp. |
| [ViMMRC 2.0](https://github.com/sonlam1102/vimmrc2) | README nói miễn phí **cho nghiên cứu**, cần ký thỏa thuận, Hugging Face có cổng cấp quyền. | Chỉ ghi nguồn và khả năng đọc hiểu. **Không tải/nạp/hiển thị trong app** nếu chưa có thỏa thuận cho mục đích sản phẩm. Có thể tự biên soạn ngữ liệu được cấp quyền cho demo. |

Các con số/nhãn do người dùng gửi về “4 mức Bloom chuẩn”, “đã sát 2025–2026” chưa được xác nhận ở từng item; importer không tự gán nhãn này. Nguồn benchmark dùng để đo model có thể bị **rò đáp án** nếu dùng nguyên câu làm luyện/ranked; cũng cần tránh trộn train/dev/test vào kho học sinh và công bố bảng điểm AI trên dữ liệu đã lộ. Không dùng từ “đề chuẩn Bộ” cho đề thử/trích sách. VNHSGE có ảnh tham chiếu nhưng lần tải nghiên cứu này **không tải ảnh**, nên câu cần ảnh không đủ để đọc/chấm.

## 2. Schema chuẩn, tương thích ba dạng từ 2025

Theo [tài liệu Bộ GD&ĐT về định dạng từ 2025](https://moet.gov.vn/content/vanban/Lists/VBDH/Attachments/3713/7mon-hoa-hoc-lop-11-ban-chinh-thuc-chot-ngay-392024signed.pdf), có dạng nhiều lựa chọn bốn phương án, đúng/sai bốn ý và trả lời ngắn; **không phải mọi môn/bài đều có cả ba dạng**. Schema MindClock dùng `single_choice`, `true_false_4`, `short_answer`, thêm `open_response` chỉ cho luyện/phản hồi. Loại câu là dữ liệu từng item, không suy từ tên dataset. Điểm chấm chính thức theo môn/năm là `scoring_policy_version` riêng; Solo dùng chấm đúng/sai cấu trúc của game, không tự tuyên bố mô phỏng điểm thi quốc gia.

```json
{
  "question_id": "team-physics-12-001",
  "revision": 1,
  "locale": "vi-VN",
  "subject_code": "physics",
  "grade_band": "12",
  "curriculum_id": "team-reviewed-2025",
  "content_version": "2026-11",
  "format_type": "single_choice",
  "cognitive_level": "understanding",
  "cognitive_level_source": "teacher_review",
  "content": {
    "stem": "Một điện trở có hiệu điện thế 6 V và cường độ dòng điện 2 A. Điện trở bằng bao nhiêu?",
    "choices": [
      {"id": "A", "text": "2 Ω"},
      {"id": "B", "text": "3 Ω"},
      {"id": "C", "text": "8 Ω"},
      {"id": "D", "text": "12 Ω"}
    ],
    "asset_refs": []
  },
  "answer_spec": {"correct_choice_id": "B"},
  "explanation": "Theo định luật Ôm, R = U/I = 6/2 = 3 Ω.",
  "provenance": {
    "source_id": "team_authored",
    "source_item_id": "team-physics-12-001",
    "source_year": 2026,
    "license_scope": "team_owned",
    "attribution": "Đội MindClock",
    "reviewer_id": "teacher-test-01"
  },
  "mode_eligibility": ["practice", "alarm", "friendly"],
  "status": "draft"
}
```

Ví dụ trên do đội tài liệu tự viết để minh họa schema, **không phải câu đề thi chính thức** và chưa có reviewer thật; `reviewer_id` là placeholder, không được publish. `answer_spec`/`explanation` chỉ server giữ trước reveal. `true_false_4`: `statements` đúng bốn mục `a,b,c,d`, `answer_spec` là bốn boolean bắt buộc; không gộp câu chọn A/B/C/D thành bốn ý. `short_answer`: lưu `canonical_value`, `accepted_variants`, quy tắc số thập phân/đơn vị/tolerance và `normalizer_version`; nếu có nhiều cách viết chưa kiểm được thì `practice_only`. `open_response`: không vào ranked hoặc khóa chuông theo chấm nhị phân.

## 3. Pipeline nhập, không nạp thẳng vào production

```mermaid
flowchart LR
  A[Registry nguồn + quyền] --> B[Nhập file local có kiểm tra hash]
  B --> C[Raw staging cách ly]
  C --> D[Parse adapter theo nguồn]
  D --> E[Chuẩn hóa + phát hiện trùng + kiểm tra ảnh]
  E --> F[Đối chiếu chương trình/năm/đáp án]
  F --> G[Người dạy duyệt + chứng cứ quyền]
  G --> H[Published revision bất biến]
  H --> I[Pool luyện/báo thức/giao hữu/ranked theo cổng riêng]
```

1. Registry `data/sources/registry.json` lưu URL, phiên bản/commit tải, quyền, trạng thái; VNHSGE/VMLU hiện `local_research_only`, ViMMRC vẫn `metadata_only`. Raw ở `data/research/raw/` bị `.gitignore`; manifest chỉ metadata. Không chạy `git clone` tự động từ app/server production. Không đưa raw corpus hay asset nguồn lên repo.
2. Khi có quyền: người vận hành đặt file được phép vào staging local riêng, ghi SHA-256 và danh sách item/ảnh được cấp. Adapter đọc hai biến thể `VNHSGE` JSON (câu có thể trộn stem/lựa chọn; phải parse/kiểm thủ công) hoặc `VMLU` JSONL; tập test mirror thiếu đáp án phải quarantine; ViMMRC chỉ sau thỏa thuận. Adapter **không** tự đặt `status=published`.
3. Kiểm định từng item: mã môn/lớp/năm, `curriculum_id`, công thức/LaTeX, hình có bản quyền và tồn tại, 4 lựa chọn không trùng, đáp án nằm trong lựa chọn, giải thích đúng, ngôn ngữ Việt, độ khó có bằng chứng. **Thêm câu yêu cầu trình bày và rubric do người dạy duyệt** theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md); đáp án khoanh không đủ để vào báo thức/ranked. Câu mơ hồ, đáp án thiếu, đề quá dài cho 60–90 giây, nguồn cũ không phù hợp → quarantine. Dedupe theo normalized stem + asset hash và `variant_family_id`, tránh trùng giữa nguồn.
4. Người dạy duyệt ít nhất câu, đáp án, giải thích, độ khó, mode eligibility. `published` ghi `reviewer_id`, `approved_at`, `license_evidence_ref`, `content_hash`, `revision`; sửa tạo revision mới. Trước ranked cần thêm thử nghiệm tỷ lệ đúng/thời gian và kiểm tra câu không lặp theo docs/34.
5. Trả về báo cáo `seen/parsed/quarantined/awaiting_rights/awaiting_rubric/reviewed/published`, không chỉ “đã nhập N câu”. `dry_run` mặc định; chỉ người vận hành có quyền mới cho phép `publish`. Import retry idempotent theo `(source_id,source_item_id,source_revision)`; rollback/retire revision có audit, không xóa lịch sử trận.

## 4. SQL và contract cho task import

Thêm `content_sources(id,url,commit_hash,license_status,license_evidence_ref,allowed_use,reviewed_at)`, `import_batches(id,source_id,file_hash,adapter_version,state,counts_json,created_at)`, `raw_questions_staging(batch_id,source_item_id,raw_payload,parse_status,quarantine_reason)` chỉ trong môi trường biên tập có hạn lưu, `question_provenance(question_id,revision,source_id,source_item_id,source_year,licence_scope,attribution,source_asset_hashes)`, và các cột `format_type,curriculum_id,content_version,cognitive_level,cognitive_level_source,scoring_policy_version` trên revision câu. `question_revisions` ở docs/34 vẫn là bản phát hành chính. Kiểm tra quyền biên tập; API học sinh không đọc staging/provenance nội bộ nếu không cần. Không dùng URL ảnh nguồn bên ngoài ở client; asset được duyệt, lưu host hợp lệ có quyền hoặc tự vẽ lại từ dữ kiện có quyền.

Adapter interface đề xuất: `detect(source_id, path)`, `parse_raw(raw)`, `normalize(raw) -> draft + warnings`, `validate(draft)`, `report(batch_id)`; **không có `publish_all`**. Contract tests: parse câu thường/LaTeX/ảnh, đáp án sai, thiếu licence, trùng ID/hash, true_false thiếu 1 ý, short_answer thiếu tolerance, UTF-8, script injection trong stem, retry batch; tất cả phải vào quarantine hoặc draft đúng, không được publish nhầm.

## 5. Mức demo khả thi

Một môn/lớp với ba câu **đội tự viết và được người có chuyên môn kiểm tra**, có rubric giải thích ngắn, đủ để trình diễn một trận giao hữu; không cần 19.000 câu. Nếu muốn cho giám khảo xem khả năng mở rộng, trình bày màn quản trị `Nguồn → Nháp → Duyệt → Xuất bản` bằng **dữ liệu giả có nhãn**. Trên slide nói rõ hai nguồn đã tải **chỉ ở khu nghiên cứu local**, chưa tích hợp nội dung thật vào app; ViMMRC chưa tải. Khi có quyền và reviewer, mở từng pool theo `practice → friendly → ranked`; không mở hàng loạt chỉ vì parse được JSON.
