# Kế hoạch thực hiện T061

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Xác nhận cổng quyền & chuẩn bị asset sprite frames + 6 avatar + FX/SFX theo `docs/04-game/02-nhan-vat-asset.md` | Pass script kiểm asset & `pubspec.yaml` | [ ] |
| 2 | Viết `ArenaSpriteStage` (phát sequence `idle/basic/skill1/skill2/hurt/stun/victory` + Reduce Motion fallback) + luật tích `qi` dùng chiêu | Widget test sprite & skill gating xanh | [ ] |
| 3 | Tích hợp client PvP 1v1 (`/v1/pvp/*`) vào `ArenaScreen` + E2E 2 user đối đầu trên API PG16 | `pytest` + Flutter E2E test xanh | [ ] |
| 4 | Build APK mới, chạy kiểm trên `emulator-5554`, cập nhật toàn bộ ảnh/video `test_demo_android/`, push `origin/main` | Test pass 100%, ghi SHA vào `handoff.md` | [ ] |
