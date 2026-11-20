# Kiểm thử

TC01 ↔ AC01: tranh chỗ cuối PostgreSQL/retry/full/leave.
TC02 ↔ AC02: cancel→accept bị chặn, accepted retry không tạo friendship đôi.
TC03 ↔ AC03: chọn maxMembers/nhập code/phòng đầy/navigation.
20/11/2026 Windows:
- `flutter test --no-pub test/t068_community_room_controls_test.dart test/community_friends_and_meet_room_test.dart`: PASS 7 (6 mới + 1 hồi quy). Widget harness: bộ lọc query, từ tab Tôi qua callback vào StudySpaceScreen initialRoom, hủy outgoing, capacity=2, mã normalized, full disabled. Chữ 200%/320dp cho các form. Không là Android thật hoặc live media.
- `pytest tests/test_community_request_states.py tests/test_community_rooms_and_friends.py -q`: PASS 4 (SQLite). Cancel→accept/actor/retry, capacity validation/mã riêng, hồi quy friends/block/rooms.
- `python scripts/run_progression_postgres.py tests/test_community_capacity_postgres.py`: PASS 1, migration PostgreSQL trong DB UUID riêng; hai thread/session tranh chỗ cuối chỉ một thành công, member retry, leave giải phóng chỗ, host đóng phòng không join được. DB test tự xóa, không sửa DB dev.
- Analyze lần trước PASS; chạy lại cuối. Docs/task/secret/staged review trước commit.

Vòng sửa widget test: ensureVisible mặc định đặt chip dưới footer nên tap lệch; dùng Scrollable.ensureVisible alignment=0.5 + unfocus trước tap. Kiểm onPressed của MindClockButton theo key thay vì tìm key ở Pressable con. Đã chạy lại PASS.

Chưa kiểm 2–8 Android thật, audio/video/voice AI nhóm, TTL QR/link, moderation, rate limit, host setting sau tạo, pet hoặc share. Không mở ranked.
