# Đặc tả nhiệm vụ T046 — Đưa nền combat T037 vào Git và xác minh bản clone sạch

## Vấn đề và kết quả mong muốn

### Hành vi hiện tại (lỗi)
- Task `T037-pvp-combat-engine-and-catalog` được ghi trạng thái `done` cục bộ, nhưng toàn bộ 6 file mã nguồn & test combat (`services/api/app/game/combat_catalog.py`, `services/api/app/game/combat_engine.py`, `services/api/tests/test_combat_engine.py`, `app/lib/domain/game/combat_catalog.dart`, `app/lib/domain/game/combat_models.dart`, `app/test/combat_catalog_test.dart`) đang **untracked** trong Git.
- Đồng thời, các file đã được **tracked** trong Git là `services/api/app/routes/v1.py` (dòng 47) → `services/api/app/services/pvp_match_service.py` (dòng 22–32) trực tiếp import:
  - `from app.game.combat_catalog import ActionType, ChampionId, COMBAT_RULE_VERSION, normalize_champion_id`
  - `from app.game.combat_engine import PlayerCombatState, RoundActionInput, settle_combat_round`
- Trên một bản clone sạch từ `origin/main`, toàn bộ backend API (`create_app()`, `app.routes.v1`, `app.services.pvp_match_service`) và mọi suite pytest đều sập ngay lúc import với `ModuleNotFoundError: No module named 'app.game'`. Phía Flutter cũng không có `package:mindclock_app/domain/game/combat_catalog.dart` và `combat_models.dart`.
- Ngoài ra `services/api/app/game/__init__.py` chưa tồn tại (khác quy ước package chuẩn ở `app/auth/`, `app/db/`, `app/repositories/`, `app/routes/`, `app/services/`).

### Kết quả mong muốn
- Một bản clone sạch (hoặc Git worktree sạch) chỉ chứa các file được Git theo dõi có thể import `app.main`, `app.game.combat_catalog`, `app.game.combat_engine`, `app.services.pvp_match_service` và chạy pass test engine Python + kiểm tra tĩnh/runtime Dart.
- Contract Python↔Dart khớp 100% về `COMBAT_RULE_VERSION = "solo-three-v0.1"`, 3 tướng (`ha_nhan`, `tuyet_dinh`, `han_boi_phap`), ánh xạ alias `han_boi_thap` / `han-boi-thap` / `han-boi-phap` → `han_boi_phap`, và parse được cả payload camelCase lẫn snake_case (`player_a_delta` / `delta_a`).

## Kiểm kê file Git (trước sửa, tại HEAD `f765841`)

### File đã được Git theo dõi (tracked) liên quan combat
- `services/api/app/main.py` (import `app.routes.v1`)
- `services/api/app/routes/v1.py` (dòng 47 import `PvpMatchService`)
- `services/api/app/services/pvp_match_service.py` (dòng 22–32 import `app.game.combat_catalog` và `app.game.combat_engine`)
- `services/api/app/db/models.py` (các bảng `MatchQueue`, `Match`, `MatchPlayer`, `MatchRound`, `MatchEvent`)
- `docs/04-game/01-pvp-gdd.md` (chốt `han_boi_phap`, alias `han_boi_thap`, `combat_rule_version=solo-three-v0.1`)
- `assets/game/manifest.json` (slugs `['ha-nhan', 'han-boi-phap', 'tuyet-dinh']`)

### File combat/catalog/test đang untracked (gây hỏng clone sạch)
- `services/api/app/game/combat_catalog.py`
- `services/api/app/game/combat_engine.py`
- `services/api/tests/test_combat_engine.py`
- `app/lib/domain/game/combat_catalog.dart`
- `app/lib/domain/game/combat_models.dart`
- `app/test/combat_catalog_test.dart`
- (Thiếu hoàn toàn: `services/api/app/game/__init__.py`)

### File ngoài phạm vi tuyệt đối không stage
- `app/google-services.json`, `app/android/app/google-services.json`
- Web WIP (`services/api/app/mobile.html`, `product.*`, `run_product.py`, `test_product_mobile.py`)
- Task khác (`tasks/T022*`, `T023*`, `T035*`, `T036*`, `T037*`, `T038*`) và file riêng của task khác (`auth_screen.dart`, `morning_question_selector*`, `test_auth_jwt.py`, `test_pvp_matchmaking.py`, `.idea/`, `START-MINDCLOCK.cmd`, `mp3/`).

## Phạm vi

- **Trong phạm vi:** `services/api/app/game/__init__.py`, `combat_catalog.py`, `combat_engine.py`, `services/api/tests/test_combat_engine.py`, `app/lib/domain/game/combat_catalog.dart`, `combat_models.dart`, `app/test/combat_catalog_test.dart`, `tasks/T046-fix-t037-combat-git-tracking/*`.
- **Ngoài phạm vi:** Migration/API matchmaking T038, Flutter Arena UI (G1/G2), asset release (G4), web WIP.
- **Dữ liệu/role/quyền liên quan:** Thuần logic combat server-authoritative và model read-only trên client; không chứa secret, dữ liệu cá nhân hay ảnh bài làm.
- **Tài liệu chuẩn:** `docs/04-game/01-pvp-gdd.md §2, §4`, `assets/game/manifest.json`, `AGENTS.md §4`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Bản clone/worktree sạch chỉ chứa file tracked trong Git | Import thành công `app.game`, `app.game.combat_catalog`, `app.game.combat_engine`, `app.services.pvp_match_service`, `app.main` và không phát sinh `ModuleNotFoundError` | TC-01 |
| AC-02 | Chạy test Python trên nền combat engine | Toàn bộ unit test combat engine (3 tướng, `han_boi_thap` → `han_boi_phap`, `solo-three-v0.1`, thứ tự sát thương `ward → armor → HP`, không hồi cứu khi HP 0, nội tại, Double KO hòa, tie-break round 6, secret round +1 qi) PASS | TC-02 |
| AC-03 | Kiểm tra hợp đồng Python↔Dart | `combat_catalog.dart` và `combat_models.dart` khớp 100% hằng số, 3 tướng, rule version `solo-three-v0.1`, alias `han_boi_thap` / `han-boi-thap` / `han-boi-phap` → `hanBoiPhap`, và parse được cả JSON camelCase lẫn snake_case từ server (`player_a_delta` và `delta_a`) | TC-03, TC-04 |
| AC-04 | Kiểm soát sạch Git staging & quy chuẩn repo | `git diff --cached` chỉ chứa đúng file combat/catalog/test & T046; không có secret/WIP/task khác; `check_docs_links.py` và `check_task_records.py` PASS; push lên `origin/main` và xác minh SHA | TC-05 |

## Hợp đồng và trường hợp biên

- `RoundSettleSnapshot.fromJson` trong `app/lib/domain/game/combat_models.dart` hỗ trợ cả `playerADelta` / `player_a_delta` / `deltaA` / `delta_a` để tương thích với cả `RoundSettleResult` của engine lẫn payload event `round_settled` trong `pvp_match_service.py`.
- `ChampionId.fromCode` trong Dart chuẩn hóa cả khoảng trắng (`' '`) và gạch nối (`'-'`) sang `'_'` để đồng nhất với `normalize_champion_id` của Python.

## Quyết định/mâu thuẫn

- Không có mâu thuẫn với `docs/04-game/01-pvp-gdd.md`: GDD §2 đã chuẩn hóa `han_boi_phap` (alias `han_boi_thap`) và `combat_rule_version=solo-three-v0.1`.
- Ghi nhận giới hạn môi trường Windows local: `flutter_tester.exe` bị Windows Smart App Control (WDAC) chặn (đã nêu ở `docs/00-start/01-hien-trang.md`); vì vậy xác minh Dart bằng `dart analyze` + chạy trực tiếp mã kiểm thử qua `dart run` trên Dart VM (không bị WDAC chặn), đồng thời ghi rõ giới hạn `flutter test` cần chạy trên CI Linux runner.
