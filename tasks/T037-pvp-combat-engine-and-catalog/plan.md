# Kế hoạch T037: Combat Engine thuần & Chốt Catalog Tướng PvP 1v1

- [x] 1. Khởi tạo module catalog tướng và combat models trong backend Python (`services/api/app/game/combat_catalog.py`, `combat_engine.py`).
- [x] 2. Hiện thực hóa logic resolution pipeline thuần túy: validation, ward, simultaneous damage, post-damage heal, passive triggers, qi accumulation, secret round bonus, match completion.
- [x] 3. Viết bộ unit test toàn diện cho backend Python (`services/api/tests/test_combat_engine.py`):
  - Test 3 tướng, nội tại, dùng chiêu khi đủ/thiếu qi, giới hạn 1 lần/trận.
  - Test sát thương theo thứ tự ward -> armor -> HP.
  - Test hồi máu sau sát thương; nếu HP về 0 không được hồi cứu.
  - Test đồng thời hạ gục (Double KO -> Draw).
  - Test phân định thắng/thua sau 6 round (so sánh HP, rồi so giáp, rồi hòa).
  - Test ánh xạ legacy ID `han_boi_thap` -> `han_boi_phap`.
- [x] 4. Hiện thực hóa combat models và contract trong Flutter Dart (`app/lib/domain/game/combat_catalog.dart`, `combat_models.dart`) để client parse chính xác snapshot và event stream từ server.
- [x] 5. Viết unit test cho Flutter client (`app/test/combat_catalog_test.dart`).
- [x] 6. Cập nhật tài liệu canonical `docs/04-game/01-pvp-gdd.md` phản ánh quyết định chốt ID `han_boi_phap` và rule version `solo-three-v0.1`.
- [x] 7. Chạy test suites Python và Flutter, xác nhận 100% xanh.
