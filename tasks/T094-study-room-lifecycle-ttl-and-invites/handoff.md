# Bàn giao nhiệm vụ T094

- **Trạng thái cuối:** `verifying` (đã PASS 100% trên PostgreSQL 16 thật, Docker `api` và Flutter VM; giữ `verifying` cho bước kiểm nối nhiều máy Android vật lý).
- **Git commit & nhánh:** `22c23a7` trên nhánh `main` (đã push và xác nhận trên `origin/main`).
- **Đã thay đổi:**
  - `services/api/alembic/versions/0011_study_room_lifecycle_and_invites.py`, `services/api/app/db/models.py`, `services/api/app/db/backup.py`: bổ sung `expires_at`, `last_heartbeat_at`, `closed_at` trên `study_rooms`, `last_heartbeat_at` trên `study_room_members`, và bảng `study_room_invites` lưu SHA-256 `token_hash`.
  - `services/api/app/services/community_service.py`, `services/api/app/schemas.py`, `services/api/app/routes/v1.py`: hiện thực máy trạng thái `waiting -> active -> closing -> closed | expired`, heartbeat thành viên/phòng, chuyển chủ phòng tự động khi mất mạng (hoặc `transferHost=true`), thu hồi & kiểm hạn mã mời không chứa PII, và bảo toàn lịch sử cá nhân khi dọn phòng.
  - `app/lib/domain/models/community_models.dart`, `app/lib/domain/services/community_repository.dart`, `app/lib/data/repositories/remote_community_repository.dart`, `app/lib/ui/features/study_focus/view_models/study_room_session_view_model.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`: đồng bộ heartbeat, dọn ngay state phòng đóng và chặn tự vào phòng đã đóng khi mở lại ứng dụng.
  - `docs/02-engineering/09-phong-hoc-realtime.md`, `services/api/tests/test_t094_study_room_lifecycle_postgres.py`, `app/test/t094_room_lifecycle_reconnect_test.dart`: tài liệu hóa và kiểm thử đầy đủ.
- **Bằng chứng kiểm thử (`2026-11-27`, PostgreSQL 16 + Flutter VM):**
  - `pytest tests/test_t094_study_room_lifecycle_postgres.py tests/test_community_capacity_postgres.py tests/test_community_rooms_and_friends.py tests/test_room_settings.py tests/test_community_request_states.py tests/test_migrations_and_data_invariants.py` -> **`18/18` PASSED** trên PostgreSQL 16 thật.
  - `docker compose up -d --build api` -> container `api-api-1` chạy migration `0011` và lên trạng thái healthy.
  - `cd app && flutter analyze --no-pub` -> `No issues found! (ran in 5.3s)`.
  - `cd app && flutter test --no-pub -j 1 test/t094_room_lifecycle_reconnect_test.dart test/t069_room_settings_and_refresh_test.dart test/t073_room_lifecycle_test.dart test/t068_community_room_controls_test.dart test/community_friends_and_meet_room_test.dart test/t093_study_space_three_flows_test.dart` -> **`26/26` PASSED**.
- **Rủi ro & giới hạn còn lại:**
  - Chưa nối truyền thông WebRTC/SFU âm thanh/video trực tiếp.
- **Điểm tiếp tục chính xác:**
  1. Thực hiện `T095` để dọn sạch toàn bộ từ ngữ kỹ thuật (`local`, `máy chủ`, `GDPT 2018`, `chuẩn quy tắc`), mở tùy chọn báo thức hẹn giờ thường độc lập với lịch ngủ-dậy, giới hạn tối đa 1 báo thức tính hoàn thành/ngày và đóng gói file APK release.
