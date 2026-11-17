# Kiểm tra T044

| ID | AC | Kịch bản | Mong đợi | Cách chạy | Kết quả 2026-11-17 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Rà QR/redeem/expiry/block | Không tự join, token không lộ dữ liệu | Rà product/engineering | Đạt tài liệu |
| TC-02 | AC-02 | Rà chat/ảnh/AI | Nhóm không tự vào AI, ảnh tạm | Rà product/privacy/API | Đạt tài liệu |
| TC-03 | AC-03 | Rà voice/deep/avatar | Audio thật điều khiển mặt, text fallback | Rà product/engineering/quality | Đạt tài liệu |
| TC-04 | AC-04 | Rà solo | Timer độc lập | Rà room/PRD | Đạt tài liệu |
| TC-05 | AC-01..04 | Link/task/diff | Không lỗi | `python scripts/check_docs_links.py`; `python -X utf8 scripts/check_task_records.py`; `git diff --check` | Đạt: 473 Markdown links, task records OK, diff check 0. |

## Giới hạn runtime

Android/API/PostgreSQL/asset chưa được triển khai trong task này; ROOM-09–11 là thiết kế kiểm thử cho R7.
