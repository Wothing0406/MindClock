# Kế hoạch thực hiện T094

## Điểm bắt đầu

- Nhánh `main` tại `70b38cf` (sau khi hoàn tất `T091`, `T092`, `T093`).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T094-*` và rà soát schema `study_rooms`, `CommunityService`, `StudyRoomSessionViewModel`, `MindClockShellScreen` | Đặc tả rõ máy trạng thái `waiting -> active -> closing -> closed \| expired` và quy tắc chủ phòng | [x] |
| 2 | Viết migration `0011_study_room_lifecycle_and_invites.py` (`0011_room_lifecycle_invites`), cập nhật `models.py`, `backup.py`, `schemas.py`, `community_service.py`, `routes/v1.py` và đồng bộ `docs/02-engineering/09-phong-hoc-realtime.md` | Alembic upgrade sạch trên PostgreSQL 16; đủ API heartbeat, close, invite create/revoke/redeem và sweep TTL | [x] |
| 3 | Cập nhật Flutter `community_models.dart`, `community_repository.dart`, `remote_community_repository.dart`, `study_room_session_view_model.dart`, `study_space_screen.dart`, `mindclock_shell_screen.dart` | Client gửi heartbeat, nhận diện `waiting`/`active`, dọn sạch cache phòng đã đóng và không tự vào lại khi resume/restart | [x] |
| 4 | Viết `test_t094_study_room_lifecycle_postgres.py` + `t094_room_lifecycle_reconnect_test.dart`, rebuild Docker API, chạy toàn bộ pytest (PostgreSQL 16) + Flutter tests + check scripts, commit & push | Tất cả test xanh trên PostgreSQL 16 và Flutter, Docker API healthy, push `origin/main` | [x] |

## Rủi ro và đường lui

- Đã bổ sung `self._db.flush()` tại các nhánh cập nhật `StudyRoomMember.left_at` dưới `sessionmaker(autoflush=False)` để truy vấn thành viên kế nhiệm `host` luôn loại trừ người vừa rời.
