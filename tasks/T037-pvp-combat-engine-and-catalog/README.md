# T037: Combat Engine thuần & Chốt Catalog Tướng PvP 1v1

- **Trạng thái:** `done`
- **Mục tiêu:**
  - Chốt chuẩn catalog nhân vật và giải quyết dứt điểm sự lệch ID giữa `han_boi_phap` và `han_boi_thap`.
  - Xây dựng Combat Engine thuần túy (pure Python backend + Dart models) thực hiện đúng 100% luật `solo-three-v0.1` theo `docs/04-game/01-pvp-gdd.md`.
  - Đảm bảo tính toán hoàn toàn Server-Authoritative, có test coverage đầy đủ cho mọi trường hợp sát thương, hồi phục, cạn năng lượng, nội tại và hòa.
- **Nguồn yêu cầu:** `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `assets/game/manifest.json`.
- **Chủ sở hữu/reviewer:** Senior Mobile & Backend Systems Architect.
- **Phạm vi file:**
  - `services/api/app/game/combat_catalog.py`
  - `services/api/app/game/combat_engine.py`
  - `services/api/tests/test_combat_engine.py`
  - `app/lib/domain/game/combat_catalog.dart`
  - `app/lib/domain/game/combat_models.dart`
  - `app/test/combat_catalog_test.dart`
  - `docs/04-game/01-pvp-gdd.md`
- **Source refs đã đọc:** `docs/04-game/01-pvp-gdd.md §1-§6`, `docs/04-game/02-nhan-vat-asset.md §1-§5`, `assets/game/manifest.json`.
- **Điểm tiếp tục:** Mở task T038 để thiết kế bảng dữ liệu PvP và matchmaking API.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt 100%.
- [x] Các bước `plan.md` đã hoàn thành và đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả thực tế.
- [x] Docs chuẩn `01-pvp-gdd.md` được cập nhật đồng bộ.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục chính xác.
