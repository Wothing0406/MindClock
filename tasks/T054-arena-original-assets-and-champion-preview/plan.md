# Kế hoạch thực hiện T054

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo bộ asset gốc bằng `image-generator` vào `app/assets/arena/` (1 map, 3 chân dung tướng, 7 icon chiêu) + `manifest.json`, kiểm thị giác chất lượng từng asset và khai báo trong `app/pubspec.yaml` | Đủ 11 ảnh PNG chất lượng cao + `manifest.json` | [x] |
| 2 | Mở rộng `CombatCatalog` (`assetPath`, mô tả chiêu `descriptionVi`, `loreVi`) trong `app/lib/domain/game/combat_catalog.dart` | `flutter analyze` 0 lỗi | [x] |
| 3 | Cập nhật `ArenaScreen` (portrait + modal sheet xem chi tiết từng tướng & nội tại/skill icons trước trận) và `ArenaStageWidget` (map backdrop, portrait, skill icons + fallback an toàn) | Tương thích màn dọc 320dp chữ 200% & Reduce Motion | [x] |
| 4 | Cập nhật/thêm test vào `app/test/solo_arena_widget_test.dart`, chạy full `flutter test`, `flutter analyze --no-pub`, `RAW_COLOR_HITS: 0`, docs checks, commit & push `origin/main` | 100% PASS, SHA khớp `origin/main` | [x] |
