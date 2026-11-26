# Ma trận kiểm thử T037

## Ma trận AC ↔ TC

| Tiêu chí chấp nhận (AC) | Ca kiểm thử (TC) | Môi trường / Lệnh chạy | Kết quả thực tế |
| :--- | :--- | :--- | :--- |
| **AC-01:** Catalog chuẩn hóa 3 tướng và ánh xạ `han_boi_thap` -> `han_boi_phap` | `test_catalog_champions_and_legacy_id_mapping` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-02:** Sát thương trừ tuần tự `ward -> armor -> HP` và không vượt giới hạn | `test_damage_order_ward_armor_hp` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-03:** Hồi máu / giáp sau sát thương; nếu HP về 0 không được hồi cứu | `test_heal_after_damage_and_zero_hp_no_revive` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-04:** Kích hoạt chiêu thức khi đủ qi, cấm dùng lại lần 2 và cấm chiêu 2 Tuyệt Đỉnh ở round 6 | `test_skill_usage_cost_and_round_6_restriction` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-05:** Nội tại Hà Nhân, Tuyệt Đỉnh, Hàn Bối Pháp kích hoạt đúng điều kiện | `test_champion_passives` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-06:** Đồng thời hạ gục (Double KO) tính là Hòa | `test_simultaneous_ko_results_in_draw` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-07:** Phân định kết quả sau 6 round (HP -> Giáp -> Hòa) | `test_round_6_completion_and_tie_breakers` | `pytest services/api/tests/test_combat_engine.py` | PASS (0.15s, 2026-11-16) |
| **AC-08:** Contract models Dart ánh xạ 100% khớp schema backend | `combat_catalog_test.dart` | `flutter test test/combat_catalog_test.dart` | PASS (4/4 passed, 2026-11-16) |
