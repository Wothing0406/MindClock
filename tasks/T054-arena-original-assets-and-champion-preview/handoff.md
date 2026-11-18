# Bàn giao nhiệm vụ T054

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Tạo đủ bộ 11 asset ảnh **gốc 100%** trong `app/assets/arena/` + `manifest.json` (`status: team_generated_original`): `map_courtyard.png` (`960x540`), `champ_{ha_nhan,tuyet_dinh,han_boi_phap}.png` (`512x512`), và 7 skill icons `skill_{basic,ha_nhan_1,ha_nhan_2,tuyet_dinh_1,tuyet_dinh_2,han_boi_phap_1,han_boi_phap_2}.png` (`256x256`).
  2. Khai báo `assets/arena/` trong `app/pubspec.yaml`, mở rộng `CombatCatalog` thêm `portraitAssetPath`, `loreVi`, `iconAssetPath`, `descriptionVi`.
  3. Cập nhật `ArenaScreen` (chân dung tướng + nút `arena-champion-detail-<id>` mở bottom sheet xem chi tiết nội tại & toàn bộ kỹ năng trước khi vào trận + icon từng skill khi chọn chiêu) và `ArenaStageWidget` (map nền Võ đường Bình minh + chân dung 2 bên + `errorBuilder` fallback về vector khi lỗi/chế độ dự phòng).
- **File/code/docs thay đổi:**
  - `app/assets/arena/*` (11 PNG + `manifest.json`)
  - `app/pubspec.yaml`
  - `app/lib/domain/game/combat_catalog.dart`
  - `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/lib/ui/features/arena/views/arena_stage_widget.dart`
  - `app/test/solo_arena_widget_test.dart`
  - `tasks/T054-arena-original-assets-and-champion-preview/*`
- **Test đã chạy (2026-11-18):**
  - `flutter analyze --no-pub`: **No issues found!**
  - `flutter test`: **78/78 All tests passed!**
  - Quét `Color(0x` ngoài `MindClockTheme`: **RAW_COLOR_HITS: 0**
- **Rủi ro còn lại:** Đồ họa đã chạy sạch qua asset bundle trong widget test; cần xem thực tế trên APK máy Android vật lý ở G1/R6.
- **Điểm tiếp tục chính xác:** Chuyển sang `T055` (tạo bộ avatar học sinh minh họa + chức năng chọn avatar ảnh/nhạc nền cục bộ).
- **Git:** Đang chuẩn bị commit & push `origin/main`.
