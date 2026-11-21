# Kế hoạch và kết quả kiểm thử

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Host kick member active | member left, media false, detail không còn member | pytest SQLite | PASS 21/11/2026; nằm trong 3 test community PASS |
| TC-02 | AC-02 | member kick/host kick self | 403/409, DB không đổi | pytest SQLite | PASS 21/11/2026 |
| TC-03 | AC-03 | host DELETE room | 204; get/list 404/không thấy | pytest SQLite | PASS 21/11/2026 |
| TC-04 | AC-04 | member DELETE room | 403; room vẫn xem được | pytest SQLite | PASS 21/11/2026 |
| TC-05 | AC-01 | kick rồi rejoin | role `removed` chặn rejoin 403 | SQLite + PostgreSQL lock suite | PASS 21/11/2026; PostgreSQL suite 3/3 |
| TC-06 | AC-03 | delete cascade | room/member count 0 | PostgreSQL disposable DB | PASS 21/11/2026; database UUID riêng đã drop |
| TC-07 | AC-05 | VM/repository kick/delete thành công, member bị chặn | state/HTTP contract đúng | Flutter unit | PASS 21/11/2026 |
| TC-08 | AC-05 | host UI 320dp + chữ 200% | kick/delete hiện đúng, có confirm, không overflow | Flutter widget | PASS 21/11/2026 |
| TC-09 | AC-05 | member UI | không thấy host controls | Flutter widget | PASS 21/11/2026 |
| TC-10 | AC-06 | docs/task checker | link/records pass; ma trận không phóng đại | scripts | PASS 654 Markdown; task records OK |

## Cổng theo rủi ro

- Auth/dữ liệu: user A/B, host/member, transaction, cascade.
- UI: vi-VN, xác nhận destructive, chữ lớn, timer local không bị xóa.
- Realtime: task này chỉ REST lifecycle; media hai máy là T076/T077.

## Lệnh và tổng kết

- `flutter test --no-pub test/t073_room_lifecycle_test.dart test/t069_room_settings_and_refresh_test.dart`: **13 PASS**.
- `flutter analyze --no-pub`: **No issues found**.
- `pytest tests/test_community_rooms_and_friends.py tests/test_community_capacity_postgres.py -q`: **3 PASS, 3 skip** khi chưa cấp admin URL; sau đó chạy riêng PostgreSQL với `MINDCLOCK_TEST_POSTGRES_ADMIN_URL` từ `.env`: **3 PASS**.
- `python scripts/check_docs_links.py`: **PASS 654 Markdown**; `check_task_records.py`: **OK**.
- Chưa build APK/máy thật vì T073 không thêm native/media; không dùng kết quả này để tuyên bố mic/cam/loa hoạt động.
