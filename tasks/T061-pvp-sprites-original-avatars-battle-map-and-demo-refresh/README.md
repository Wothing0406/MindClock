# T061 — Đấu trường PvP thật, Sprite gốc nhiều frame, 6 Avatar gốc & Quay lại Video Demo

- **Trạng thái:** `verifying`
- **Mục tiêu:** Đưa đủ bộ **6 avatar gốc mới đội tự tạo** (`sunrise`, `cu_meo`, `cao_giay`, `ca_chep`, `rua_xanh`, `may_nho`) + 3 chân dung tướng, map sân đấu, hoạt cảnh 2D `ArenaSpriteActor` + VFX/Qi (`Đánh thường` +1 Qi -> `Chiêu 1` / `Chiêu 2`), nối màn **Đấu đơn PvP 1v1 giao hữu** qua `/v1/pvp/*`, chạy E2E & build APK debug, và cập nhật demo `test_demo_android/`. *(Không tự ý đóng gói sprite thô từ `assets/game/` khi chưa có xác nhận bản quyền thương mại theo `AGENTS.md §3`.)*
- **Nguồn yêu cầu:** Người dùng 19/11/2026 (`AGENTS.md §2–4`).
- **Chủ sở hữu/reviewer:** Agent & User MindClock.
- **Phạm vi file dự kiến:**
  - `app/assets/avatars/{avatar_cu_meo.png,avatar_cao_giay.png,avatar_ca_chep.png,avatar_rua_xanh.png,avatar_may_nho.png,manifest.json}`, `app/lib/ui/core/widgets/mindclock_avatar_view.dart`
  - `app/lib/app.dart`, `app/lib/domain/game/pvp_models.dart`, `app/lib/domain/services/pvp_gateway.dart`, `app/lib/data/{repositories/remote_pvp_gateway.dart,debug/debug_fixture_pvp_gateway.dart}`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/ui/features/arena/{view_models/pvp_arena_view_model.dart,views/arena_screen.dart,views/arena_stage_widget.dart,views/arena_sprite_stage.dart,views/arena_pvp_lobby.dart}`
  - `app/test/{arena_pvp_and_sprites_test.dart,solo_arena_widget_test.dart}`, `test_demo_android/*`
  - `docs/00-start/01-hien-trang.md`, `tasks/T061-*/*`.
- **Liên quan:** `T038`, `T047`, `T054`, `T056`, `T060`.
- **Source refs đã đọc:** `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `assets/game/manifest.json`, `services/api/app/services/pvp_match_service.py`, `app/lib/domain/game/solo_combat_engine.dart`.
- **Điểm tiếp tục:** Chờ chủ dự án xác nhận quyền sử dụng/đóng gói sprite frame trong `assets/game/` (nếu muốn thay thế hoạt cảnh `ArenaSpriteActor` gốc hiện có) & playtest PvP 1v1 trên 2 máy Android thật.

## Cổng trước coding

- [x] Đã cập nhật canonical doc `04-game/01-pvp-gdd.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có AC ↔ TC đầy đủ.

## Cổng kết thúc

- [ ] Chủ dự án xác nhận quyền sử dụng thương mại/đóng gói sprite & 6 avatar trong `assets/game/` (hiện tại đã thay bằng 6 avatar gốc đội tự tạo hợp lệ bản quyền).
- [x] Acceptance kỹ thuật đạt (`flutter test` **94/94**, `flutter analyze` `No issues found!`, `RAW_HEX_COLOR_HITS: 0`, `integration_test/arena_game_e2e_test.dart` trên `emulator-5554` PASS, `dist/mindclock-debug.apk` `152.35 MB`, cập nhật `test_demo_android/` & push SHA lên `origin/main`).
