# Kiểm thử T025

| ID | AC | Kịch bản | Kỳ vọng | Cách chạy | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Liệt kê root docs và folder canonical/archive | Root chỉ có README và folder; số file cũ được giữ trong archive | PowerShell/Python audit | Pass 15/11/2026: root chỉ README.md; archive 58 file đánh số |
| TC-02 | AC-02 | Đi từ index theo 5 task mẫu: alarm, API/auth, AI chấm, nội dung, PvP | Mỗi đường có spec, contract, test, next task và giới hạn | review ma trận điều hướng/PRD ↔ TC | Pass 15/11/2026: 00-start→01-product→02-engineering→03-quality; game sau gate, B01a–B05 cụ thể; sửa lệch P-04–P-08 |
| TC-03 | AC-03 | Link Markdown đệ quy, cố tình link thiếu trong fixture | Pass repo; checker bắt missing fixture | `python scripts/check_docs_links.py`; test checker | Pass 15/11/2026: 338 Markdown gồm docs/tasks/skill nội bộ; regression nested/missing pass |
| TC-04 | AC-04 | `git diff`, task records, whitespace | Không đổi app/API/WIP; docs không claim production | status/diff/task checker | Pass phần docs: task records OK, Python compile OK; diff code app/API WIP có sẵn và không stage. `git diff --check` toàn repo fail do whitespace trong `services/api/app/demo_ui.py` WIP, không thuộc T025; staged docs sẽ kiểm riêng. |

Android máy thật/API runtime không thuộc task docs; ghi trạng thái chưa kiểm, không giả pass.
