# Bàn giao T027

- **Trạng thái:** `done` cho đặc tả; chưa có MorningCard/EduSkills adapter chạy trong app/backend.
- **Đã làm:** PRD/UX/luồng sáng/động lực; EduSkills authoring và grading modes; content/AI/API/SQL; test IDs MORNING-01–03, EDU-01–04; AGENTS/backlog/README/truy vết.
- **Kiểm:** TC-01–04 PASS bằng review tài liệu; `python scripts/check_docs_links.py` PASS 358 Markdown; `python scripts/check_task_records.py` PASS; `git diff --check` PASS. Không chạy Android/PostgreSQL/Gemini runtime trong task docs.
- **Rủi ro/cần kiểm khi code:** ngưỡng 5 sai là policy v0.1 phải playtest; hook phải gắn câu và đủ quyền asset; bộ bài đa môn phải có nhãn người dạy; thời điểm kết ngày theo timezone cần migration/test; không dùng Tesseract chấm chữ viết tay.
- **Điểm tiếp tục:** B03 MorningCard/câu đã duyệt và B05 adapter EduSkills/Gemini theo [backlog](../../docs/00-start/05-goi-task-dau-tien.md). Đọc handoff T022/T023 trước khi sửa runtime đang WIP; lập task coding riêng và test Android/PostgreSQL thật.
