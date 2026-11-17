# Kế hoạch thực hiện T046

## Điểm bắt đầu

- HEAD `f765841` trên `main` đã track `pvp_match_service.py` và `v1.py`, nhưng 6 file combat/catalog/test của T037 đang untracked và thiếu `services/api/app/game/__init__.py`.
- Môi trường sẵn có: `services/api/.venv/Scripts/python.exe` (Python 3.11 + pytest 8.3.4) và `.local-sdk/flutter/bin/dart.bat` (`dart analyze` + `dart run` chạy được; `flutter_tester.exe` bị Windows WDAC chặn).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Kiểm kê đầy đủ file tracked/untracked và tái hiện lỗi import trên bản export sạch | Có bằng chứng lỗi `ModuleNotFoundError` trước khi track file | [ ] |
| 2 | Thêm `services/api/app/game/__init__.py`, hoàn thiện đồng bộ contract Python↔Dart trong `combat_catalog.dart`, `combat_models.dart`, `test_combat_engine.py`, `combat_catalog_test.dart` | Alias `han_boi_thap`, rule version `solo-three-v0.1`, snake_case/camelCase khớp 2 chiều | [ ] |
| 3 | Chạy test Python (`pytest`), `dart analyze`, kiểm thử runtime Dart VM và ghi rõ kết quả/giới hạn `flutter test` vào `tests.md` | Toàn bộ test khả thi đều PASS, có bằng chứng thật | [ ] |
| 4 | Tạo temporary Git worktree từ commit T046 (hoặc kiểm trên index sạch) để chứng minh bản clone sạch tự import & pass test | Import + pytest + dart analyze PASS trên cây sạch chỉ gồm file tracked | [ ] |
| 5 | Chạy `check_docs_links.py`, `check_task_records.py`, rà `git diff --cached`, commit ID T046, push và xác minh `origin/main` | Không lọt WIP/secret/task khác; SHA ghi vào `handoff.md` | [ ] |

## Rủi ro và đường lui

- **Rủi ro stage nhầm WIP/secret:** Tuyệt đối không dùng `git add .`; chỉ `git add` từng đường dẫn trong danh sách phạm vi và kiểm `git status --short` + `git diff --cached --name-only` trước khi commit.
- **Rủi ro WDAC chặn `flutter_tester.exe`:** Không giả mạo kết quả `flutter test`; chạy `dart analyze` + thực thi kiểm chứng logic bằng `dart run` trên Dart VM và ghi rõ điều kiện chạy `flutter test` trên CI Linux.
- **Đường lui:** Các file đều là module độc lập/bổ sung, có thể `git revert <sha>` nếu cần mà không ảnh hưởng dữ liệu người dùng.
