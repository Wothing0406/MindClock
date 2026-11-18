# Nhật ký thực hiện và vòng sửa T054

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 2026-11-18 | Sinh 11 asset ảnh gốc via `image-generator` (1 map `960x540`, 3 chân dung `512x512`, 7 skill icons `256x256`), kiểm tra từng ảnh bằng `read_file`, khai báo `assets/arena/` trong `app/pubspec.yaml`, mở rộng `CombatCatalog`, `ArenaScreen`, `ArenaStageWidget` và thêm test trong `solo_arena_widget_test.dart`. | `find.textContaining('Một Nét Thành Chiêu')` trùng cả thẻ chọn tướng lẫn sheet chi tiết; `build/unit_test_assets` từng bị khóa thư mục cũ. | Xóa `build/unit_test_assets`, scope matcher theo `find.descendant(of: detailSheet, ...)`. | `flutter analyze --no-pub`: `No issues found!`; `flutter test`: `78/78` PASS; `RAW_COLOR_HITS: 0`. | Đạt 100% AC-01..AC-04; commit & push `origin/main`. |
