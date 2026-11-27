# T094 — Vòng đời phòng học, Heartbeat TTL, chuyển chủ phòng và mã mời có hạn thu hồi được

- **Trạng thái:** `verifying`
- **Mục tiêu:** Chuẩn hóa và kiểm chứng trên PostgreSQL 16 + Flutter máy trạng thái phòng học (`waiting -> active -> closing -> closed | expired`), quản lý heartbeat thành viên & phòng, bảo vệ phòng đang hoạt động hợp lệ, tự động chuyển chủ phòng khi chủ phòng mất kết nối (hoặc đóng phòng theo quy tắc khi chủ phòng chủ động kết thúc/rời), phát hành & thu hồi link/QR mời có hạn không chứa dữ liệu cá nhân, và dọn sạch state phòng đã đóng trên client để mở lại app không bao giờ tự vào phòng cũ.
- **Nguồn yêu cầu:** Task 3 trong đặc tả tái cấu trúc sản phẩm MindClock; `2026-11-27`.
- **Chủ sở hữu/reviewer:** AI Assistant / User.
- **Phạm vi file dự kiến:**
  - `services/api/alembic/versions/0011_study_room_lifecycle_and_invites.py`
  - `services/api/app/db/models.py`
  - `services/api/app/db/backup.py`
  - `services/api/app/schemas.py`
  - `services/api/app/services/community_service.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_t094_study_room_lifecycle_postgres.py`
  - `docs/02-engineering/09-phong-hoc-realtime.md`
  - `app/lib/domain/models/community_models.dart`
  - `app/lib/domain/services/community_repository.dart`
  - `app/lib/data/repositories/remote_community_repository.dart`
  - `app/lib/data/debug/debug_fixture_community_repository.dart`
  - `app/lib/ui/features/study_focus/view_models/study_room_session_view_model.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/test/t069_room_settings_and_refresh_test.dart`
  - `app/test/t094_room_lifecycle_reconnect_test.dart`
- **Liên quan:** Sau `T093` (`fdb8a33` / `70b38cf`); tiền đề trước `T095`.
- **Source refs đã đọc:** `AGENTS.md §3`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/09-phong-hoc-realtime.md`, `docs/02-engineering/03-du-lieu-sql.md`.
- **Điểm tiếp tục:** Chuyển sang `T095` để làm sạch ngôn từ toàn app, mở chế độ báo thức hẹn giờ thường độc lập với lịch ngủ-dậy, giới hạn tối đa 1 báo thức tính hoàn thành/ngày và xuất APK release.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt đầy đủ trên PostgreSQL 16 và Flutter; giữ `verifying` cho phần kiểm trên điện thoại Android thật.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật (`docs/02-engineering/09-phong-hoc-realtime.md`).
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
