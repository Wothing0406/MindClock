# T054 — G1/Art: Bộ Asset Đấu Trường Gốc (Map, 3 Tướng, 7 Skill Icons) & Xem Chi Tiết Tướng/Nội Tại Trước Trận

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. Tạo bộ asset đồ họa **gốc 100% do đội sở hữu** đặt trong `app/assets/arena/` kèm `manifest.json` (`rights_status: team_generated_original`, không dùng `assets/game/` vốn gắn `research_demo_only`):
     - 1 hình nền Map đấu trường (`map_courtyard.png`)
     - 3 chân dung tướng (`champ_ha_nhan.png`, `champ_tuyet_dinh.png`, `champ_han_boi_phap.png`)
     - 7 biểu tượng kỹ năng (`skill_basic.png`, `skill_ha_nhan_1.png`, `skill_ha_nhan_2.png`, `skill_tuyet_dinh_1.png`, `skill_tuyet_dinh_2.png`, `skill_han_boi_phap_1.png`, `skill_han_boi_phap_2.png`)
  2. Khai báo `app/assets/arena/` trong `app/pubspec.yaml`.
  3. Mở rộng `CombatCatalog` (`ChampionSpec` / `SkillSpec` / asset path helpers + `descriptionVi` cho từng chiêu và cốt truyện ngắn từng tướng).
  4. Cập nhật `ArenaScreen` & `ArenaStageWidget`:
     - Màn chọn tướng (`Thiết lập Luyện đơn`) hiện **ảnh chân dung từng tướng**, **thẻ Nội tại** kèm nút **"Xem chi tiết tướng & chiêu thức"** (`arena-champion-detail-<id>`) mở modal/panel xem đầy đủ Nội tại, Đánh thường, Chiêu 1, Chiêu 2 kèm hình ảnh icon từng skill & chỉ số rõ ràng trước khi vào trận.
     - Màn trận (`ArenaStageWidget` & bảng chọn chiêu) dùng **hình Map nền riêng** + **ảnh chân dung hai tướng** + **icon từng chiêu** (có `errorBuilder` fallback về vector `MindClockTheme` khi asset lỗi, tôn trọng `assetFallbackMode` và `Reduce Motion`).
- **Nguồn yêu cầu:** Yêu cầu người dùng 2026-11-18; `AGENTS.md §3, §4`; `docs/04-game/01-pvp-gdd.md`; `docs/04-game/04-che-do-don-doi-va-asset-gap.md`.
- **Chủ sở hữu/reviewer:** Senior Flutter & Game Systems Architect.
- **Phạm vi file dự kiến:**
  - `app/assets/arena/*` (mới)
  - `app/pubspec.yaml`
  - `app/lib/domain/game/combat_catalog.dart`
  - `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/lib/ui/features/arena/views/arena_stage_widget.dart`
  - `app/test/solo_arena_widget_test.dart`
  - `tasks/T054-arena-original-assets-and-champion-preview/*`
- **Source refs đã đọc:** `app/pubspec.yaml`, `app/lib/domain/game/combat_catalog.dart`, `app/lib/ui/features/arena/views/arena_screen.dart`, `app/lib/ui/features/arena/views/arena_stage_widget.dart`, `assets/game/manifest.json`.
- **Điểm tiếp tục:** Hoàn tất AC-01..AC-04 (`78/78` Flutter tests PASS, `flutter analyze` 0 lỗi, `RAW_COLOR_HITS: 0`). Tiếp tục `T055` cho bộ avatar minh họa + tải avatar/nhạc nền cục bộ.

## Cổng trước coding

- [x] Xác nhận `app/pubspec.yaml` chưa khai báo `assets:` và `assets/game/` đang là `research_demo_only` nên cần tạo bộ asset gốc sạch.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-04).
- [x] `plan.md`, `tests.md`, `handoff.md` cập nhật đầy đủ với test pass thật.
