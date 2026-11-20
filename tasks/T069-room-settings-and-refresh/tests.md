# Kiểm thử

TC01 ↔ AC01: owner/non-owner, input/empty/null, capacity/member invariant.
TC02 ↔ AC02: fetch/refresh, request cũ, lifecycle, offline/closed, leave.
TC03 ↔ AC03: host/editor vs member, lỗi/retry và accessibility.
TC04 ↔ AC04: PostgreSQL race/settings, Flutter regression. Chưa chạy.

## Kết quả 20/11/2026, Windows

- `flutter test --no-pub test/t069_room_settings_and_refresh_test.dart test/t068_community_room_controls_test.dart test/community_friends_and_meet_room_test.dart test/t067_profile_progress_test.dart`: PASS 25 (T069 9, T068 6, T058 1, T067 9). VM poll/no overlap/background/resume/dispose, mutation-vs-poll/leave, đổi room, offline/404/403/self removed, duplicate action, HTTP GET/PATCH, host UI 320dp200% Reduce Motion và member không thấy editor. Hồi quy media test kiểm nút chưa khả dụng/disabled (AC05), không giả media live.
- `pytest tests/test_room_settings.py tests/test_community_request_states.py tests/test_community_rooms_and_friends.py -q`: PASS 5 SQLite API contracts.
- `python scripts/run_progression_postgres.py tests/test_community_capacity_postgres.py`: PASS 2 PostgreSQL 16 trong DB UUID riêng với Alembic head; tranh chỗ cuối và host shrink đồng thời join vẫn giữ invariant. DB test tự xóa, không sửa DB app.
- `flutter analyze --no-pub`: PASS, No issues found (3.0s) sau sửa 2 lint if braces. Các lint đã sửa, không đổi yêu cầu để test pass.

Chưa Android APK mới, ảnh/UI máy thật, 2–8 điện thoại, Live media, host transfer/kick, QR TTL/rotate, outbox leave khi offline hoặc pet. Harness không là Firebase thật. Backend Docker phục vụ app chưa rebuild trong task này; API được kiểm bằng TestClient/migration DB test.
