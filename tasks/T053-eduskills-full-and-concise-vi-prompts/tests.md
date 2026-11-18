# Kế hoạch và kết quả kiểm thử T053

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Gọi `build_eduskills_prompt_spec` cho đủ 11 môn GDPT 2018 (`TOAN`, `VAT_LY`, `HOA_HOC`, `SINH_HOC`, `NGU_VAN`, `LICH_SU`, `DIA_LY`, `GDCD`, `TIENG_ANH`, `TIN_HOC`, `CONG_NGHE`) và kiểm `sanitize_pre_reveal_hint` | Trả quy tắc đúng từng môn + văn phong ngắn gọn không lộ đáp án | `POSTGRES_TEST_URL=... pytest ...` (Windows PG 16) | PASS (`test_eduskills_adapter_modes_and_answer_leak_guard` — 2026-11-18) |
| TC-02 | AC-02 | Gọi `generate_socratic_help`, `generate_personalized_question`, `create_live_ephemeral_token`, `grade_photo_attempt` qua `httpx.MockTransport` | `systemInstruction` chứa đúng `EduSkillsMode`, quy tắc bộ môn tương ứng và quy tắc trả lời ngắn 1–2 câu không filler | `POSTGRES_TEST_URL=... pytest ...` (Windows PG 16) | PASS (`test_gemini_service_embeds_eduskills_and_concise_vi_prompts_across_flows` — 2026-11-18) |
| TC-03 | AC-03 | Kiểm tra `.agents/skills/vietnamese-education-copy/SKILL.md`, `.agents/skills/vietnamese-dev/SKILL.md` và docs liên quan | Link nội bộ & cấu trúc skill/task hợp lệ | `python scripts/check_docs_links.py` & `check_task_records.py` | PASS (`PASS local links in 531 Markdown files`, `Task records OK` — 2026-11-18) |
| TC-04 | AC-04 | Chạy toàn bộ 7 file backend tracked trên PostgreSQL 16 | 100% PASS, 0 lỗi | PG 16 `127.0.0.1:5432` | PASS (`51 passed in 20.96s`, 0 skipped — 2026-11-18) |
