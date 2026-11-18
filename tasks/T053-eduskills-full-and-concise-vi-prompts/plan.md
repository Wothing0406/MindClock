# Kế hoạch thực hiện T053

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Nâng cấp `services/api/app/services/eduskills_adapter.py` lên `v2.0`: đủ 11 môn THPT EduSkills-VN + CoVe + quy tắc ngắn gọn người-với-người (`vietnamese-education-copy` + `vietnamese-dev`) | Đủ 11 môn & `HUMAN_CONCISE_EDUCATION_STYLE_VI` | [x] |
| 2 | Tích hợp `build_eduskills_prompt_spec` + `sanitize_pre_reveal_hint` + giới hạn output ngắn gọn vào `services/api/app/services/gemini_service.py` cho cả 4 luồng (`Socratic`, `Personalized`, `Live`, `Photo Grade`) & truyền `subject_code`/`grade_level` từ `routes/v1.py`, thêm test ở `test_api_v1.py` | Pytest `test_api_v1.py` & full suite PG 16 PASS | [x] |
| 3 | Tạo `.agents/skills/vietnamese-education-copy/SKILL.md` và `.agents/skills/vietnamese-dev/SKILL.md` (MIT attribution), cập nhật `docs/02-engineering/11-eduskills-vn-tich-hop.md` & `docs/00-start/07-quy-tac-skills-va-ai-agent.md` | `check_docs_links.py` & `check_task_records.py` PASS | [x] |
| 4 | Chạy full backend PostgreSQL 16, kiểm tra docs/task records, stage đúng file T053, commit & push `origin/main` | 100% PASS, SHA khớp `origin/main` | [x] |
