# Kiểm chứng T026

| ID | AC | Kịch bản | Cách kiểm | Kết quả |
| --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Đi từ mở app đến dashboard và các nhánh | Review PRD/UX/AC IDs | PASS — PRD P-01–15, ON-01–06, hành trình UX và nhánh offline/quyền; 15/11/2026. |
| TC-02 | AC-02 | OS từ chối quyền, offline, sai bài nhiều lần, DND không được cấp | Review alarm/quality với nguồn Android | PASS — SLEEP-01–05, AD01–09 và quy tắc Dừng local; nguồn Android chính thức; 15/11/2026. |
| TC-03 | AC-03 | Học một mình/AI/bạn, mic/cam từ chối, Live hết phiên/quota, nhắc nghiêm | Review study/privacy/API/test | PASS — ROOM-01–06, FOCUS-01–08, realtime/consent/fallback; 15/11/2026. |
| TC-04 | AC-04 | Mỗi AC mới nối contract/data/test/roadmap/gate; game không khoanh lụi | Traceability review | PASS — P-01–15 map sang ca nghiệm thu và R0–R9; catalog môn đối chiếu chương trình Bộ GD&ĐT; 15/11/2026. |
| TC-05 | AC-05 | Link checker, task checker, diff phạm vi, tài liệu không quảng cáo tính năng chưa chạy | Script + staged diff | PASS — `check_docs_links.py` (351 Markdown), `check_task_records.py`, `git diff --check`; staged diff kiểm trước commit; 15/11/2026. |

Không chạy kiểm Android/Firebase/Gemini Live thật trong task docs; trạng thái đó phải giữ chưa kiểm.
