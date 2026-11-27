# Nhật ký làm việc T094

## 2026-11-27

- Tạo migration `0011_study_room_lifecycle_and_invites.py` (`revision = '0011_room_lifecycle_invites'` vừa khít giới hạn `VARCHAR(32)` của `alembic_version` trên PostgreSQL) và dùng unique index `ix_study_room_invites_token_hash` khớp 1:1 `compare_metadata` của SQLAlchemy.
- Phát hiện và sửa nguyên nhân gốc dưới `sessionmaker(autoflush=False)`: khi `leave_room` gán `member.left_at = now` nhưng chưa `self._db.flush()`, câu lệnh `SELECT` kế tiếp vẫn thấy chủ phòng cũ trong `remaining`. Sau khi thêm `self._db.flush()` tại `_reconcile_room_locked`, `leave_room` và `remove_room_member`, toàn bộ 18 test PostgreSQL 16 + SQLite đều PASS.
- Cập nhật `StudyRoomSessionViewModel`, `StudySpaceScreen` và `MindClockShellScreen` để chấp nhận `waiting`/`active`, từ chối ngay `closing`/`closed`/`expired`/`410`, và xác minh lại khi app `resumed`; toàn bộ 26 test Flutter phòng học PASS, `flutter analyze --no-pub` 0 lỗi.
