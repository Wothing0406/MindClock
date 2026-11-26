
# Bàn giao T064

- **Trạng thái:** `verifying` (đã qua đầy đủ analyzer/unit/widget/APK/E2E emulator; chưa commit/push theo yêu cầu giữ local chưa commit trừ khi được ủy quyền).
- **Đã làm:**
  - Đóng gói 204 runtime game files từ `assets/game/` vào `app/assets/game/` (đăng ký trong `app/pubspec.yaml`, loại trừ `source/`).
  - Cập nhật `app/lib/domain/game/combat_catalog.dart`, `app/lib/ui/features/arena/views/arena_sprite_stage.dart`, `arena_stage_widget.dart`, `arena_pvp_lobby.dart`, `mindclock_avatar_view.dart`: 3 nhân vật gốc (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Pháp`) với frame sequence `basic`/`skill1`/`skill2`/`victory` (6 frames), `hurt`/`stun`/`heal` (4 frames), `runtime/idle.webp`, `nativeFacingRight` chuẩn (`tuyet-dinh = false`, hai tướng còn lại `true`), nền `study-courtyard.webp` và Reduce Motion fallback tĩnh.
  - Thêm `app/lib/domain/game/arena_lobby_models.dart`, `app/lib/data/repositories/arena_cosmetic_store.dart`, `app/lib/ui/features/arena/views/arena_lobby_panel.dart` và nối vào `ArenaScreen`: Sảnh chờ có avatar + khung + ví Xu MindCoin + xem trước tướng, tab `Bảng xếp hạng` lọc môn/khối không dùng giờ dậy + opt-in ẩn danh, và tab `Daily Shop` xoay vòng ngày chỉ bán mỹ thuật (`0 ST/HP/Giáp`).
- **Kiểm chứng ngày 21/11/2026:**
  - `flutter analyze --no-pub`: **0 issues**.
  - `flutter test --no-pub -j 1`: **160/160 PASS** (gồm `t064_arena_lobby_shop_and_leaderboard_test.dart`, `t065_*_test.dart`, `arena_pvp_and_sprites_test.dart`, `solo_arena_widget_test.dart`).
  - `scripts/build_android_apk.ps1 -Mode debug`: **PASS** (`dist/mindclock-debug.apk`, `163.19 MB`, build từ `lib/main.dart`).
  - `flutter test --no-pub integration_test/arena_game_e2e_test.dart -d emulator-5554`: **PASS** (`01:06 +1: All tests passed!`).
- **Rủi ro & giới hạn còn lại:**
  - Asset `assets/game/` (đặc biệt `ha-nhan`) cần rà quyền thương mại trước khi phát hành Google Play công khai.
  - Bảng xếp hạng hiện dùng cohort cục bộ `0 RP`; E2E PvP 2 tài khoản backend thật trên 2 máy vật lý chưa chạy.
- **Điểm tiếp tục:** Khi được phép commit/push, rà lại diff T064/T065 sạch WIP ngoài phạm vi, commit và push `origin/main`; sau đó tiếp tục `T076` (QR TTL, phòng chờ, block/report) theo `docs/00-start/08-ke-hoach-hoan-thien-product.md`.
