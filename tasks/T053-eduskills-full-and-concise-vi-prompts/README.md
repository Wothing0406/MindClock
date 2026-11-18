# T053 — Tích hợp đủ 11 skill môn EduSkills-VN & phong cách trả lời ngắn gọn chuẩn tiếng Việt (`vietnamese-education-copy` + `vietnamese-dev`)

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. **Mở rộng [`eduskills_adapter.py`](../../services/api/app/services/eduskills_adapter.py) lên `eduskills-vn-adapter-v2.0`:**
     - Bao phủ đủ **11 môn THPT GDPT 2018** từ `Wothing0406/EduSkills-VN` (bổ sung `LICH_SU`, `DIA_LY`, `GDCD`/KTPL, `CONG_NGHE` bên cạnh 7 môn đã có).
     - Nhúng quy tắc kiểm tra bẫy nhận thức theo môn & Chain-of-Verification (CoVe) nội bộ (điều kiện xác định, đơn vị SI, bảo toàn, không bịa tư liệu) mà không in checklist dài dòng.
     - Thêm quy tắc **trả lời ngắn gọn người-với-người** (`HUMAN_CONCISE_EDUCATION_STYLE_VI`) chắt lọc từ `trussary/vietnamese-language-skill` (`vietnamese-education-copy`) và `DevLungTung/vietnamese-dev`: bỏ rào đón máy dịch, 1–2 câu/lượt (`<=180` ký tự cho gợi mở/feedback, `<=120` ký tự cho câu hỏi tiếp theo), đúng xưng hô giáo dục VN và không lặp lại đề.
  2. **Nối `eduskills_adapter` vào mọi runtime prompt của [`gemini_service.py`](../../services/api/app/services/gemini_service.py):**
     - `generate_socratic_help` (`HINT_ONE_STEP`), `generate_personalized_question` (`AUTHOR_DRAFT` + `sanitize_pre_reveal_hint`), `create_live_ephemeral_token` (`HINT_ONE_STEP`), `grade_photo_attempt` (`GRADE_CANDIDATE` + `sanitize_pre_reveal_hint`).
  3. **Thêm 2 workspace skills chuẩn nguồn & license MIT vào `.agents/skills/`:**
     - `.agents/skills/vietnamese-education-copy/SKILL.md` (từ `trussary/vietnamese-language-skill`)
     - `.agents/skills/vietnamese-dev/SKILL.md` (từ `DevLungTung/vietnamese-dev`)
  4. **Cập nhật tài liệu chuẩn:** [`11-eduskills-vn-tich-hop.md`](../../docs/02-engineering/11-eduskills-vn-tich-hop.md) và [`07-quy-tac-skills-va-ai-agent.md`](../../docs/00-start/07-quy-tac-skills-va-ai-agent.md).
- **Nguồn yêu cầu:** Yêu cầu người dùng 2026-11-18, [Wothing0406/EduSkills-VN](https://github.com/Wothing0406/EduSkills-VN), [trussary/vietnamese-language-skill](https://github.com/trussary/vietnamese-language-skill), [DevLungTung/vietnamese-dev](https://github.com/DevLungTung/vietnamese-dev), `docs/02-engineering/11-eduskills-vn-tich-hop.md`, `docs/00-start/07-quy-tac-skills-va-ai-agent.md`.
- **Chủ sở hữu/reviewer:** Senior AI/Backend & Agentic Systems Architect.
- **Phạm vi file dự kiến:**
  - `services/api/app/services/eduskills_adapter.py`
  - `services/api/app/services/gemini_service.py`
  - `services/api/tests/test_api_v1.py`
  - `.agents/skills/vietnamese-education-copy/SKILL.md`
  - `.agents/skills/vietnamese-dev/SKILL.md`
  - `docs/02-engineering/11-eduskills-vn-tich-hop.md`
  - `docs/00-start/07-quy-tac-skills-va-ai-agent.md`
  - `services/api/app/routes/v1.py`
  - `tasks/T053-eduskills-full-and-concise-vi-prompts/*`
- **Source refs đã đọc:** `services/api/app/services/eduskills_adapter.py`, `services/api/app/services/gemini_service.py`, `docs/02-engineering/11-eduskills-vn-tich-hop.md`, `docs/00-start/07-quy-tac-skills-va-ai-agent.md`, các file gốc từ `Wothing0406/EduSkills-VN`, `trussary/vietnamese-language-skill`, `DevLungTung/vietnamese-dev`.
- **Điểm tiếp tục:** Đã hoàn tất AC-01..AC-04 (`51/51` backend tests PG 16 PASS, `PASS local links in 531 Markdown files`, `Task records OK`). Chưa có phát sinh ngoài dev.

## Cổng trước coding

- [x] Đã đối chiếu trực tiếp các repo `Wothing0406/EduSkills-VN`, `trussary/vietnamese-language-skill` (`vietnamese-education-copy`) và `DevLungTung/vietnamese-dev`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-04).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có kết quả thực chạy trên PostgreSQL 16 + kiểm docs/links.
- [x] `handoff.md` ghi rõ SHA remote và điểm tiếp tục.
