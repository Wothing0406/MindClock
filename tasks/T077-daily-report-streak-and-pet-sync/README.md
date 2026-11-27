# T077 — Cơ chế giữ Streak theo ngày, Báo cáo ngày & Xem lịch sử Streak/Pet nhóm

- **Trạng thái:** `verifying`
- **Mục tiêu:** Đổi cơ chế giữ streak theo chuẩn tính từng ngày (thử thách sáng, phiên học tập trung đủ điều kiện, hoặc **hoàn thành Báo cáo ngày = 1 ngày streak**), sửa lỗi tính streak nhóm Pet bỏ sót `morning_challenge`, và bổ sung UI xem chi tiết streak + lịch sử báo cáo ngày trực quan theo phong cách trending ngay trên app Flutter.
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa/tạo:**
  - Backend & DB: `services/api/app/{db/models.py,schemas.py,services/progression.py,services/commitment_group_service.py,routes/v1.py}`, `services/api/alembic/versions/0008_add_daily_reports.py`, `services/api/tests/test_daily_report_streak.py`
  - Flutter: `app/lib/domain/{models/personal_flow_models.dart,services/personal_flow_repository.dart}`, `app/lib/data/{repositories/remote_personal_flow_repository.dart,debug/debug_fixture_personal_flow_repository.dart}`, `app/lib/ui/core/widgets/mindclock_icon.dart`, `app/lib/ui/features/personal_flow/{view_models/personal_flow_view_model.dart,views/today_streak_card.dart,views/daily_report_sheet.dart,views/streak_detail_sheet.dart,views/profile_progress_card.dart}`, `app/lib/ui/features/community/views/{today_pet_card.dart,commitment_group_sheet.dart}`, `app/lib/ui/features/guest_shell/views/{today_screen.dart,mindclock_shell_screen.dart}`, `app/test/t077_daily_report_streak_test.dart`
  - Docs chuẩn: `docs/01-product/13-tien-do-va-cong-dong-trien-khai.md`, `docs/02-engineering/{04-hop-dong-api.md,13-nhom-cam-ket-va-pet-ledger.md}`
- **Liên quan:** Kế thừa `T066`, `T067`, `T074`, `T075`, `T076`.
- **Source refs đã đọc:** `AGENTS.md §3–§4`, `docs/01-product/13-tien-do-va-cong-dong-trien-khai.md`, `docs/02-engineering/04-hop-dong-api.md`, `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, `services/api/app/services/progression.py`, `services/api/app/services/commitment_group_service.py`, `services/api/app/routes/v1.py`, `app/lib/ui/features/guest_shell/views/today_screen.dart`.
- **Điểm tiếp tục:** Bật Docker Desktop + chạy `alembic upgrade head` (`0008_add_daily_reports`) và test E2E PostgreSQL 16 + Android Emulator/máy thật trước khi đặt `done` và commit/push.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt trên SQLite API + Flutter widget/HTTP contract tests (còn bước migration/E2E PostgreSQL sống khi Docker chạy).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test chưa chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật đồng bộ.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
