# T061 — Đấu trường PvP thật, Sprite gốc nhiều frame, 6 Avatar gốc & Quay lại Video Demo

- **Trạng thái:** `planned`
- **Mục tiêu:** Đưa đúng bộ 6 avatar hồ sơ (`ca-chep`, `cao-giay`, `cu-meo`, `may-nho`, `rua-xanh`, `tho-so`), map sân đấu, bộ sprite animation từng frame (`idle`, `basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`) + FX + SFX (sau cổng xác nhận quyền dùng cho app) vào Flutter Đấu trường; triển khai cơ chế trả lời 1 câu = đánh thường & tích đủ `qi` dùng Chiêu 1–2; nối màn **PvP 1v1 trực tuyến** qua `/v1/pvp/*`; và quay lại đầy đủ bộ ảnh/video demo mới trong `test_demo_android/`.
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `app/pubspec.yaml`, `app/assets/` (sau xác nhận quyền ở bước trước khi đóng gói)
  - `app/lib/domain/models/arena_models.dart`, `app/lib/domain/services/pvp_gateway.dart`, `app/lib/data/repositories/remote_pvp_gateway.dart`
  - `app/lib/ui/features/arena/views/{arena_screen.dart,arena_sprite_stage.dart,arena_pvp_lobby.dart}`
  - `app/test/arena_pvp_and_sprites_test.dart`, `test_demo_android/*`
  - `docs/00-start/01-hien-trang.md`, `docs/04-game/*`, `tasks/T061-*/*`.
- **Liên quan:** `T038`, `T047`, `T054`, `T056`, `T060`.
- **Source refs đã đọc:** `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `assets/game/manifest.json`.
- **Điểm tiếp tục:** Triển khai sau khi T060 đạt & xác nhận quyền đóng gói asset `assets/game/`.

## Cổng trước coding

- [x] Đã cập nhật canonical doc `04-game/01-pvp-gdd.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [ ] Chủ dự án xác nhận quyền sử dụng thương mại/đóng gói sprite & 6 avatar trong `assets/game/`.
- [ ] Acceptance đạt, 2 tài khoản đối đầu PvP pass, `flutter test` + E2E emulator PASS, quay mới `test_demo_android/` & push SHA lên `origin/main`.
