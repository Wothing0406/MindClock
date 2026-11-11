# Kế hoạch và kết quả kiểm thử T005

| ID | AC | Cách kiểm | Kỳ vọng | Kết quả |
| --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Review journey, giả thuyết, AC UI | đủ trường hợp ngày học/ngày nghỉ/mất mạng/không camera/sai/không muốn thi | **Pass tài liệu:** docs/41 N01–N10, U01–U10, hành trình và kế hoạch thử; chưa phỏng vấn học sinh |
| TC-02 | AC-02 | `rg` Firestore/API/Hoãn/3 nhân vật; đối chiếu trang nguồn | luật hiện hành thống nhất, trang cũ được thay/ghi lưu trữ | **Pass tài liệu:** docs/06,17–18,21 viết lại; docs/28/35/README/AGENTS đồng bộ; quét không còn `Firestore repository`, `giữ 2 giây`, `3 nhân vật` trong docs hiện hành |
| TC-03 | AC-03 | Trace câu cache → nộp offline → sync/không sync → XP | không lộ đáp án trước reveal, không grade giả, dừng chuông local | **Pass review:** docs/06 §2–3, docs/07 §2/§8, docs/17 §2–4; chưa test thiết bị/API thật |
| TC-04 | AC-04 | So docs chấm, trận, privacy và test plan | `uncertain`/khiếu nại/rating có đường xử lý rõ | **Pass review:** docs/07,09,21,35,39,42; cổng ranked vẫn chưa được kiểm chứng thực tế |
| TC-05 | AC-05 | Đọc runbook + `demo/index.html`, phân biệt live/mock | không hứa tính năng chưa có, có phương án mạng/API/thiết bị lỗi | **Pass tài liệu:** docs/02/26/29 ghi live/mock; demo HTML có nhãn mô phỏng, nút gợi ý cũ đã được cảnh báo không dùng làm bằng chứng luật thử thách |
| TC-06 | AC-06 | `python -X utf8 scripts/check_task_records.py`, local links, `git diff --check` | pass, handoff cụ thể | **Pass:** Task records OK; 50 file Markdown/0 link local thiếu; diff check exit 0 (chỉ cảnh báo LF/CRLF) |

Không có app hoặc pilot; kiểm thử trong task này chỉ chứng minh chất lượng hồ sơ tài liệu, không chứng minh hành vi sản phẩm. Kiểm thử U01–U10 trên người học/máy thật nằm ở các task coding/pilot sau.
