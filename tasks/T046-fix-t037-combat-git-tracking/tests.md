# Kế hoạch và kết quả kiểm thử T046

Viết ca kiểm thử từ `spec.md` trước coding. Điền **lệnh thực và kết quả thực**, không ghi “pass” nếu chưa chạy.

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Xuất/tạo bản Git worktree sạch chỉ gồm file tracked và import `app.main`, `app.game.combat_catalog`, `app.game.combat_engine`, `app.services.pvp_match_service` | Trước sửa: fail `ModuleNotFoundError: No module named 'app.game'`. Sau commit T046: import thành công và pytest combat PASS trên worktree sạch | `git worktree add` + `services/api/.venv/Scripts/python.exe -m pytest` | Chưa chạy |
| TC-02 | AC-02 | Chạy bộ unit test combat engine Python (`test_combat_engine.py`) kiểm tra `han_boi_thap` → `han_boi_phap`, `solo-three-v0.1`, sát thương `ward→armor→HP`, không hồi cứu HP 0, nội tại 3 tướng, Double KO, tie-break round 6, secret round qi | 100% test PASS | `services/api/.venv/Scripts/python.exe -m pytest services/api/tests/test_combat_engine.py -vv` | Chưa chạy |
| TC-03 | AC-03 | Kiểm tra phân tích tĩnh và chạy thực thi logic `combat_catalog.dart` + `combat_models.dart` (alias `han_boi_thap`/`han-boi-thap`/`han-boi-phap`, `solo-three-v0.1`, parse cả camelCase & snake_case JSON xuất từ Python engine) | `dart analyze` 0 issues; kịch bản đối chiếu Python→JSON→Dart PASS | `.local-sdk/flutter/bin/dart.bat analyze` + `dart.bat run` (Windows local) | Chưa chạy |
| TC-04 | AC-03 | Chạy `flutter test test/combat_catalog_test.dart` trên máy Windows local | Xác nhận chạy được hoặc ghi nhận giới hạn thật nếu bị Windows WDAC chặn `flutter_tester.exe` | `.local-sdk/flutter/bin/flutter.bat test --no-pub test/combat_catalog_test.dart` | Chưa chạy |
| TC-05 | AC-04 | Chạy kiểm tra docs/task records và rà staged diff | `check_docs_links.py` PASS, `check_task_records.py` PASS, `git diff --cached --name-only` chỉ gồm file T046/combat, push & xác minh `origin/main` | `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git ls-remote origin main` | Chưa chạy |

## Cổng theo rủi ro

- Điểm/thi đấu: Kiểm tra contract Python↔Dart đồng nhất `combat_rule_version = solo-three-v0.1`, không tự tính HP/result ở client, alias `han_boi_thap` → `han_boi_phap` hoạt động ở cả 2 phía.
- Bảo mật/Git: Không stage `google-services.json`, dữ liệu cá nhân, web WIP hay task khác.
