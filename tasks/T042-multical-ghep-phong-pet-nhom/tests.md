# Kiểm tra T042

| ID | AC | Kịch bản | Mong đợi | Cách chạy | Kết quả 2026-11-17 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Rà MultiCal/availability/vote | Free/busy, xác nhận, timezone/quiet hours | Rà docs product/engineering | Đạt ở mức tài liệu |
| TC-02 | AC-02 | Rà 4 cách học | AI 1–1 khác người thật, deep im lặng | Rà docs product/room | Đạt ở mức tài liệu |
| TC-03 | AC-03 | Rà hard/soft matching | Consent/block/capacity và empty state | Rà docs product/engineering | Đạt ở mức tài liệu |
| TC-04 | AC-04 | Rà pet/ledger | Cap, idempotency, không phạt tập thể | Rà docs product/engineering | Đạt ở mức tài liệu |
| TC-05 | AC-05 | Kiểm link/task/diff | Không lỗi | `python scripts/check_docs_links.py`; `python -X utf8 scripts/check_task_records.py`; `git diff --check` | Đạt sau thêm task; 461 Markdown links, task records OK, diff check 0. Dùng `-X utf8` vì terminal Windows cp1252 không in được thông báo Unicode khi báo lỗi. |

## Giới hạn kiểm chứng runtime

Không có test Android, media, API/PostgreSQL hoặc pet asset vì task này chỉ thiết kế. GROUP-01–08 là ca nghiệm thu cho các task code R7b, chưa pass.
