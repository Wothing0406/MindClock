# Kế hoạch thực hiện T061

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chuẩn bị 6 avatar linh vật gốc đội tự tạo hợp lệ bản quyền (`sunrise`, `cu_meo`, `cao_giay`, `ca_chep`, `rua_xanh`, `may_nho`) vào `app/assets/avatars/` & cập nhật `MindClockAvatarCatalog`; giữ riêng `assets/game/` chưa đóng gói | Bộ avatar PNG 256×256 + `manifest.json` sạch quyền thương mại | [x] |
| 2 | Viết `ArenaSpriteActor` & `_ArenaVfxOverlayPainter` + `ArenaQiGuideStrip` + luật tích `qi` dùng chiêu (`Reduce Motion` an toàn) | Widget test sprite & skill gating xanh | [x] |
| 3 | Tích hợp client PvP 1v1 (`/v1/pvp/*`: `PvpGateway`, `RemotePvpGateway`, `DebugFixturePvpGateway`, `PvpArenaViewModel`, `ArenaPvpLobby`) vào `ArenaScreen` | `arena_pvp_and_sprites_test.dart` & `solo_arena_widget_test.dart` xanh (`94/94` Flutter + PG16 PvP backend) | [x] |
| 4 | Build APK mới (`152.35 MB`), chạy `arena_game_e2e_test.dart` trên `emulator-5554`, cập nhật ảnh/video `test_demo_android/`, push `origin/main` | Test pass 100%, ghi SHA vào `handoff.md` | [x] |
