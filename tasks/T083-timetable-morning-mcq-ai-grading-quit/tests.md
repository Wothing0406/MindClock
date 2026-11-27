# Kế hoạch và kết quả kiểm thử T083

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | User đặt TKB Thứ 6 có Tiếng Anh & Ngữ văn -> `GET /v1/challenges/next?subject=auto&date=2026-11-27&difficulty=basic|advanced` | Chọn đúng môn TKB hôm đó, trả ABCD / Mini-quiz 4 câu `>= 70%`, cập nhật `SubjectMemory` | `pytest -q tests/test_t083_subject_memory_and_mcq.py tests/test_gemini_regen_and_grading.py` | PASS (4/4 passed) — 27/11/2026 |
| TC-02 | AC-03 | Render `PracticeSessionScreen` với câu ABCD, nguồn TKB, nút `Bỏ cuộc` và ẩn bước chụp ảnh ở `320dp 200%` | Chạm 1 đáp án ABCD chấm được, bấm `Bỏ cuộc` gọi abandon immediate | `flutter test --no-pub -j 1 test/t083_morning_mcq_and_quit_test.dart` | PASS (1/1 passed) — 27/11/2026 |
| TC-03 | All | Full regression suite Backend + Flutter + repo scripts | 0 lỗi phân tích tĩnh, toàn bộ test SQLite & Flutter xanh | `pytest -q`, `dart analyze --fatal-infos`, `flutter test --no-pub -j 1`, `check_docs_links.py`, `check_task_records.py` | Kiểm tra ở lượt cuối — 27/11/2026 |
