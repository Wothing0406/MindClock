# Kiểm thử T007

| ID | AC | Cách kiểm | Kỳ vọng | Kết quả |
| --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Rà HTML demo và SVG bằng `rg` | Chỉ concept mới, nhãn mô phỏng | PASS 12/11/2026: ba tên mới, không còn `i-owl` hoặc tên cũ; chưa xem trên browser |
| TC-02 | AC-02 | Đọc docs/22,43 | Ba tên, chưa chốt kit/art | PASS 12/11/2026 |
| TC-03 | AC-03 | `rg` tên/ID cũ trong docs/demo/AGENTS; `python scripts/check_task_records.py`; `git diff --check` | Không còn tên cũ, task hợp lệ | PASS 12/11/2026: `rg` không có match; task checker OK; diff không lỗi whitespace |
