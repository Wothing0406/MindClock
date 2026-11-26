# T064 — Khôi phục bộ 3 nhân vật gốc (idle/basic/skill1/skill2/hurt/stun/heal/victory), Sảnh chờ, Bảng xếp hạng & Daily Shop mỹ thuật

- **Trạng thái:** `in_progress`
- **Mục tiêu:** Theo yêu cầu trực tiếp của chủ dự án (`2026-11-20`): khôi phục & đóng gói trọn bộ **3 nhân vật gốc ban đầu từ git (`assets/game/` — Hà Nhân gấu trúc nón lá, Tuyệt Đỉnh kiếm sĩ tóc trắng, Hàn Bối Pháp cõng tháp nhỏ)** kèm animation từng frame (`idle`, `basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`), map `study-courtyard.webp`, 6 avatar linh vật & tài nguyên UI từ `assets/game/`; nâng cấp giao diện Đấu trường thành **Sảnh chờ (Lobby) có tướng chuyển động + Bảng xếp hạng theo môn/khối + Daily Shop chỉ bán mỹ thuật (khung, avatar, hào quang)**.
- **Nguồn yêu cầu:** Tin nhắn người dùng + 3 ảnh sprite sheet gốc tải lên ngày `2026-11-20`.
- **Chủ sở hữu/reviewer:** Chủ dự án MindClock.
- **Phạm vi file dự kiến:** `app/pubspec.yaml`, `app/assets/game/*`, `app/lib/domain/game/*`, `app/lib/data/repositories/*`, `app/lib/ui/features/arena/**`, `app/test/*`, `docs/00-start/01-hien-trang.md`.
- **Liên quan:** Nối tiếp `T054`, `T061`, `T063`.
- **Source refs đã đọc:** `AGENTS.md §3–§4`, `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `docs/04-game/03-rank-mua-va-kinh-te.md`, `docs/04-game/04-che-do-don-doi-va-asset-gap.md`, `assets/game/manifest.json`, commit `1aa6af7` (`demo/arena-renderer.js`).
- **Điểm tiếp tục:** Copy runtime assets vào `app/assets/game/`, nối `CombatCatalog` + `ArenaSpriteActor` frame animator, dựng Sảnh chờ / Bảng xếp hạng / Daily Shop, test Flutter + APK + Emulator E2E & screenshots rồi push lên `origin/main`.

## Cổng trước coding

- [x] Đã lục git (`1aa6af7`, `215cd22`) và kiểm định toàn bộ 204 runtime files trong `assets/game/` (`check_game_assets.py` PASS, `9.73 MB`).
- [x] Chủ dự án đã xác nhận dùng lại đúng bộ 3 nhân vật gốc ban đầu trong `assets/game/` và làm thêm Sảnh chờ, Bảng xếp hạng, Daily Shop.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
