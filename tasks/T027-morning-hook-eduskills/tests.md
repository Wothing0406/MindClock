# Kiểm chứng T027

| ID | AC | Cách kiểm | Kết quả |
| --- | --- | --- | --- |
| TC-01 | AC-01 | Review PRD/UX/morning/card schema/MORNING-01 | PASS — cùng câu khi bỏ hook, fallback chữ, không màn hỏi bắt đầu; 15/11/2026. |
| TC-02 | AC-02 | Review state/count/ledger/API/AC MORNING-02/03 và Dừng cục bộ | PASS — 3/5 `incorrect`, abandon/incomplete/system grace, Dừng độc lập; 15/11/2026. |
| TC-03 | AC-03 | Review EduSkills repo, prompt mode/reviewer/rights/OCR/eval EDU-01–04 | PASS — adapter spec và ranh giới Tesseract/chấm đã đối chiếu; 15/11/2026. |
| TC-04 | AC-04 | Link checker, task checker, staged diff chỉ docs/rules/T027 | PASS — link/task/diff checker; staged diff kiểm trước commit; 15/11/2026. |

Không chạy Android, PostgreSQL, Gemini hoặc EduSkills integration runtime trong task docs này.
