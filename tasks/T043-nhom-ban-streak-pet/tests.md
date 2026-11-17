# Kiểm tra T043

| ID | AC | Kịch bản | Kết quả mong đợi | Cách chạy | Kết quả 2026-11-17 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Rà tạo nhóm/link/consent | Không tự join, quyền rõ | Rà docs product | Đạt tài liệu |
| TC-02 | AC-02 | Rà on-time/late/grace | Chuỗi tách, không thưởng oan | Rà product/engineering/quality | Đạt tài liệu |
| TC-03 | AC-03 | Rà care/group day/retry | Một nguồn, không trừ pet | Rà engineering/quality | Đạt tài liệu |
| TC-04 | AC-04 | Rà AI/deep/study care | Không tự nói, care phụ có trần | Rà product/engineering | Đạt tài liệu |
| TC-05 | AC-01..04 | Link/task/diff | Không lỗi | `python scripts/check_docs_links.py`; `python -X utf8 scripts/check_task_records.py`; `git diff --check` | Đạt: 467 Markdown links, task records OK, diff check 0. |

## Giới hạn runtime

Kiểm thử Android/PostgreSQL/AI được để cho task triển khai vì T043 chỉ chỉnh docs; GROUP-06/09 là ca test cho task sau.
