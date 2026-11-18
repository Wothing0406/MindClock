# Bàn giao nhiệm vụ T053

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Nâng cấp `services/api/app/services/eduskills_adapter.py` lên `eduskills-vn-adapter-v2.0` bao phủ đủ **11 môn THPT GDPT 2018** từ `EduSkills-VN` (thêm `LICH_SU`, `DIA_LY`, `GDCD`/KTPL, `CONG_NGHE`) + kiểm chứng CoVe + `HUMAN_CONCISE_EDUCATION_STYLE_VI` (chắt lọc từ `vietnamese-education-copy` & `vietnamese-dev`: 1–2 câu ngắn gọn người-với-người, cấm rào đón máy dịch).
  2. Nối trực tiếp `build_eduskills_prompt_spec` + `sanitize_pre_reveal_hint` vào tất cả 4 luồng AI trong `services/api/app/services/gemini_service.py` (`generate_socratic_help`, `generate_personalized_question`, `create_live_ephemeral_token`, `grade_photo_attempt`) và truyền `subject_code`/`grade_level` từ `routes/v1.py`.
  3. Tạo 2 skill nhẹ chuẩn MIT trong `.agents/skills/vietnamese-education-copy/SKILL.md` và `.agents/skills/vietnamese-dev/SKILL.md`, cập nhật `docs/02-engineering/11-eduskills-vn-tich-hop.md` và `docs/00-start/07-quy-tac-skills-va-ai-agent.md`.
- **File/code/docs thay đổi:**
  - `services/api/app/services/eduskills_adapter.py`
  - `services/api/app/services/gemini_service.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_api_v1.py`
  - `.agents/skills/vietnamese-education-copy/SKILL.md`
  - `.agents/skills/vietnamese-dev/SKILL.md`
  - `docs/02-engineering/11-eduskills-vn-tich-hop.md`
  - `docs/00-start/07-quy-tac-skills-va-ai-agent.md`
  - `tasks/T053-eduskills-full-and-concise-vi-prompts/*`
- **Test đã chạy (2026-11-18, Windows 11, PostgreSQL 16):**
  - Toàn bộ 7 file backend tracked trên PG 16: **51 passed in 20.96s** (0 skipped)
  - `python scripts/check_docs_links.py`: **PASS local links in 531 Markdown files**
  - `python scripts/check_task_records.py`: **Task records OK**
- **Rủi ro còn lại:** Phản hồi thực tế của Gemini Live/Text trên model `gemini-3.8-flash` cần đánh giá tiếp bằng bộ eval mẫu thực tế khi bật `GEMINI_API_KEY` thật (`R4`).
- **Điểm tiếp tục chính xác:** Kiểm thử thực tế trên thiết bị Android vật lý (`R6`) hoặc chạy evaluation Gemini thật với `GEMINI_API_KEY`.
- **Git:** Đang chuẩn bị commit & push lên `origin/main`.
