# Kiểm thử

TC01 ↔ AC01/03: model level/history + UI empty/real/fixture ở 320dp 200%.
TC02 ↔ AC02/03: A trả muộn sau logout/đổi B, pagination/retry/refresh mới.
TC03 ↔ AC04: ledger PostgreSQL/test schema; chưa chạy.

## Kết quả 20/11/2026, Windows

- `flutter test --no-pub test/t067_profile_progress_test.dart`: PASS 9. Khách/fixture/rỗng/lỗi, HTTP query và parse, auth 401, level fraction, retry/dedup/refresh, response A muộn sau login B, response refresh cũ, 320dp chữ 200% Reduce Motion/logout.
- `flutter test --no-pub test/t067_profile_progress_test.dart test/personal_flow_real_service_test.dart`: PASS 13 trước bổ sung hai ca rỗng/fixture; bộ personal_flow có 6 test. Harness HTTP không là Firebase thật/hai điện thoại.
- `flutter analyze --no-pub`: PASS sau sửa lint private test helper; chạy lại cuối trước bàn giao.
- `services/api/.venv/Scripts/python scripts/run_progression_postgres.py` từ services/api: PASS 1 (PostgreSQL 16 Docker). DB tạm tên UUID, Alembic upgrade head, A/B owner, hai TestClient cùng progress, unique ledger chống trùng, pagination/422. DB tạm tự xóa; không sửa DB ứng dụng. Đã chạy lại sau thay URL migration override trực tiếp để tránh settings cache.
- Vòng sửa test: semanticsValue thanh progress phải là số phần trăm theo Flutter, sửa từ chữ sang `20%`; test 401 cần httpStatus=401 theo model; sửa một dấu ngoặc thừa trong test empty. Tất cả đã chạy lại đạt.

Chưa chụp/rà UI Android và chưa đồng bộ hai điện thoại thật. Đây là giới hạn kiểm release, không dùng fixture làm chứng cứ người dùng thật. Pet/ranked/shop online không thuộc nghiệm thu T067.

Kiểm cuối: analyze PASS (No issues found, 2.3s); backend `pytest tests/test_progression.py tests/test_api_v1.py -q` PASS 23; docs links PASS 616 Markdown; task records PASS; staged diff whitespace/secret/asset/config review PASS. Git fetch không dọn worktree dùng --no-auto-maintenance vì `.git/worktrees/wt_t048` cũ bị lỗi quyền, không thay/xóa worktree đó. Push code main đã xác minh remote SHA trong handoff.md.
