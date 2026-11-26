# Nhật ký làm việc T037

## Vòng 1: Thiết kế & Hiện thực Combat Catalog và Combat Engine thuần túy
- Ngày: 2026-11-16
- Nội dung:
  - Chuẩn hóa ID nhân vật: `ha_nhan`, `tuyet_dinh`, `han_boi_phap`.
  - Giải quyết sai lệch legacy: Ánh xạ tự động `han_boi_thap` và các biến thể slug kebab-case sang `han_boi_phap`.
  - Hiện thực `services/api/app/game/combat_catalog.py` và `services/api/app/game/combat_engine.py` với luật `solo-three-v0.1`.
  - Hiện thực tương ứng trên client Flutter: `app/lib/domain/game/combat_catalog.dart` và `app/lib/domain/game/combat_models.dart`.
  - Viết bộ 8 test cases pytest (`services/api/tests/test_combat_engine.py`) bao phủ toàn diện: sát thương tuần tự ward -> armor -> HP, hồi phục sau sát thương, cấm hồi phục khi đã bị hạ gục (0 HP), cấm chiêu 2 Tuyệt Đỉnh ở round 6, các nội tại tướng, hạ gục đồng thời dẫn đến Hòa (Double KO -> Draw), phân định sau 6 round (HP -> giáp -> Hòa), và điểm năng lượng thưởng ở Secret Round.
  - Viết bộ test cases Flutter (`app/test/combat_catalog_test.dart`) kiểm tra catalog, thông số kỹ năng, và serialize/deserialize JSON.
- Kết quả:
  - Pytest: 8/8 passed in 0.15s.
  - Flutter test: 4/4 passed.
