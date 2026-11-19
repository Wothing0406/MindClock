# T059 — Study Space theo Profile, Đốt nến / Đếm giờ tự do (>120p) & Báo thức AI tạo sẵn câu hỏi cá nhân

- **Trạng thái:** `done`
- **Mục tiêu:** Lọc môn trong Không gian học đúng theo `StudyProfile.selectedSubjectCodes`, bỏ trần 120 phút bằng cách thêm chế độ **Đốt nến · Đếm giờ tự do** (count-up kèm ngọn nến cháy trực quan) và mốc thời gian dài hơn (`5–360p`), đồng thời hiển thị **bản xem trước câu thử thách AI cá nhân hóa theo TKB + Profile** ngay trên màn cài báo thức (`AlarmConfigScreen`).
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `app/lib/domain/models/study_focus_models.dart`, `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`, `app/lib/ui/features/study_focus/views/{study_space_screen.dart,study_candle_timer.dart}`
  - `app/lib/ui/features/guest_shell/views/{alarm_config_screen.dart,mindclock_shell_screen.dart}`, `services/api/app/schemas.py`
  - `app/test/{study_focus_local_test.dart,alarm_ai_preview_and_candle_test.dart}`
  - `docs/00-start/01-hien-trang.md`, `tasks/T059-*/*`.
- **Liên quan:** `T052`, `T056`, `T058`.
- **Source refs đã đọc:** `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/07-khong-gian-hoc.md`.
- **Điểm tiếp tục:** Đã xong T059; chuyển sang **T060** (`tasks/T060-gemini-live-models-hard-bank-regen-and-math-keypad/`).

## Cổng trước coding

- [x] Đã cập nhật canonical docs `08-phong-hoc-ai-va-ban-be.md`, `09-giac-ngu-va-bao-thuc.md`, `02-engineering/07-khong-gian-hoc.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [x] Acceptance đạt và test xanh (`flutter test` `91/91`, `flutter analyze` `No issues found!`, `RAW_HEX_COLOR_HITS: 0`, PG16 `pytest` `62/62`).
- [ ] Push backup lên `origin/main` và ghi SHA vào `handoff.md`.
