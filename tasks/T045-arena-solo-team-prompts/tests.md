# Kiểm tra T045

| ID | AC | Kịch bản | Mong đợi | Cách chạy | Kết quả 2026-11-17 |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Rà ba mode | Mục tiêu/cổng khác nhau | Rà docs game/PRD | Đạt tài liệu |
| TC-02 | AC-02 | Rà bốn submission/target/void | Không client authority | Rà game/API/SQL/quality | Đạt tài liệu |
| TC-03 | AC-03 | So manifest/checker với bảng asset | Không claim release từ file count | Rà assets/game + docs | Đạt tài liệu |
| TC-04 | AC-04 | Rà prompts G1–G4 | Task dọc/test/gate | Rà prompt docs | Đạt tài liệu |
| TC-05 | AC-01..04 | Link/task/diff | Không lỗi | `python scripts/check_docs_links.py`; `python -X utf8 scripts/check_task_records.py`; `git diff --check` | Đạt: 481 Markdown links, task records OK, diff check 0. |

## Giới hạn runtime

Không có build Flutter/PvP/backend, playtest, quyền asset hoặc máy thật trong task docs này. GAME-06–10 là ca nghiệm thu để triển khai sau.
