# T046 — Sửa lỗi thiếu theo dõi Git cho nền combat T037

- **Trạng thái:** `done`
- **Mục tiêu:** Đưa toàn bộ mã nguồn combat engine Python, catalog/models Dart và unit tests của T037 vào Git theo dõi sạch, bổ sung package marker `services/api/app/game/__init__.py`, kiểm tra hợp đồng Python↔Dart (`han_boi_thap` → `han_boi_phap`, `solo-three-v0.1`) và xác minh bản clone/worktree sạch từ Git tự import và pass test.
- **Nguồn yêu cầu:** Yêu cầu sửa lỗi T037 (2026-11-17) & điều kiện tiên quyết cho T038 (2026-11-18).
- **Chủ sở hữu/reviewer:** Backend & Flutter Systems Architect.
- **Phạm vi file dự kiến:**
  - `services/api/app/game/__init__.py`
  - `services/api/app/game/combat_catalog.py`
  - `services/api/app/game/combat_engine.py`
  - `services/api/tests/test_combat_engine.py`
  - `app/lib/domain/game/combat_catalog.dart`
  - `app/lib/domain/game/combat_models.dart`
  - `app/test/combat_catalog_test.dart`
  - `tasks/T046-fix-t037-combat-git-tracking/*`
- **Liên quan:** Sửa lỗi Git tracking cho `T037-pvp-combat-engine-and-catalog`; điều kiện chặn trước khi tiếp tục `T038-pvp-database-and-matchmaking`.
- **Source refs đã đọc:** `AGENTS.md §1–§4`, `docs/README.md`, `docs/00-start/01-hien-trang.md`, `docs/00-start/03-quy-trinh-vibe-code.md`, `docs/04-game/01-pvp-gdd.md §1–§4`, `assets/game/manifest.json`, `tasks/T037-pvp-combat-engine-and-catalog/*`, `services/api/app/services/pvp_match_service.py`, `services/api/app/routes/v1.py`.
- **Điểm tiếp tục:** Nền combat T037 đã tracked và tự import/test từ Git sạch; mở khóa `tasks/T038-pvp-database-and-matchmaking/` để sửa kẹt test và hoàn thiện migration PostgreSQL PvP.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
