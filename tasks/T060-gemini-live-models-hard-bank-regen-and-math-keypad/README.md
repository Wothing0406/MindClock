# T060 — Model Gemini thực tế, Tái tạo câu hỏi khó theo giai đoạn & Hiển thị/Bàn phím công thức Toán

- **Trạng thái:** `planned`
- **Mục tiêu:** Sửa cấu hình model Gemini trong backend về tên model Gemini Developer API thực tế đang hỗ trợ (`gemini-2.5-flash` / `gemini-2.5-flash-lite`), nâng cấp AI sinh & tái tạo câu hỏi thực tế khó theo 3 giai đoạn từ ngân hàng câu đã duyệt (`foundational` / `applied` / `advanced`), kiểm định chấm bài thật với backend + `.env` cục bộ, và xây dựng widget `MathFormulaText` + `MathInputKeypad` cho câu hỏi & ô trả lời (mũ, phân số, `%`, đạo hàm, tích phân, căn, `π`, `Δ`).
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `services/api/app/{config.py,services/gemini_service.py,routes/v1.py}`, `services/api/tests/test_gemini_regen_and_grading.py`
  - `app/lib/ui/core/widgets/{math_formula_text.dart,math_input_keypad.dart}`
  - Màn nhập bài giải / ôn tập / đấu trường dùng `MathFormulaText` & `MathInputKeypad`
  - `app/test/math_formula_and_keypad_test.dart`
  - `docs/00-start/01-hien-trang.md`, `tasks/T060-*/*`.
- **Liên quan:** `T040`, `T053`, `T059`.
- **Source refs đã đọc:** `docs/02-engineering/06-ai-va-cham-bai.md`, `services/api/app/config.py`, `services/api/app/services/gemini_service.py`.
- **Điểm tiếp tục:** Triển khai sau khi T059 đạt và push lên `origin/main`.

## Cổng trước coding

- [x] Đã cập nhật canonical doc `02-engineering/06-ai-va-cham-bai.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [ ] Acceptance đạt và có bằng chứng test thật (`pytest` + live Gemini verification qua `.env` cục bộ không log key + `flutter test`).
- [ ] Push backup lên `origin/main` và ghi SHA vào `handoff.md`.
