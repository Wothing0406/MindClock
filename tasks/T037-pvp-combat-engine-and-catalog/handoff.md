# Biên bản bàn giao T037

- **Trạng thái:** `done`
- **Mã task:** `T037-pvp-combat-engine-and-catalog`
- **Tiêu đề:** Combat Engine thuần & Chốt Catalog Tướng PvP 1v1
- **Kết quả đạt được:**
  1. Chốt định danh chính thức của 3 tướng: `ha_nhan`, `tuyet_dinh`, `han_boi_phap`.
  2. Giải quyết dứt điểm sai lệch ID legacy: Ánh xạ tự động `han_boi_thap` và slug kebab-case (`han-boi-phap`) sang `han_boi_phap` trên cả backend Python và client Flutter Dart.
  3. Xây dựng Combat Engine thuần túy Server-Authoritative (`services/api/app/game/combat_engine.py`) theo phiên bản luật `solo-three-v0.1` với đầy đủ logic:
     - Khởi tạo ward và kích hoạt buff phòng thủ trong round.
     - Trừ sát thương đồng thời theo thứ tự bất biến: `ward -> armor -> HP`.
     - Hồi phục HP/giáp sau sát thương; cấm hồi phục cứu mạng khi đã về 0 HP.
     - Kích hoạt nội tại 3 tướng (Kiên Định, Tập Trung Đột Phá, Bích Chướng Cổ Giới).
     - Kiểm soát năng lượng Qi: chỉ câu trả lời đúng mới được xuất chiêu và tích lũy Qi cho round sau (tối đa 3); thưởng +1 Qi ở Secret Round.
     - Cơ chế kết thúc: Double KO -> Hòa; hết 6 round so HP -> so giáp -> Hòa.
  4. Xây dựng domain models và JSON parser tương ứng trên Flutter client (`app/lib/domain/game/combat_catalog.dart`, `app/lib/domain/game/combat_models.dart`).
- **Kiểm thử thực tế:**
  - `& "services\api\.venv\Scripts\python.exe" -m pytest services\api\tests\test_combat_engine.py` (8/8 PASS).
  - `cd app; flutter test test/combat_catalog_test.dart` (4/4 PASS).
  - `python scripts/check_task_records.py` (PASS).
  - `python scripts/check_docs_links.py` (PASS).
- **Điểm tiếp tục chính xác:** Mở task `T038-pvp-database-and-matchmaking` để triển khai bảng dữ liệu PvP trong PostgreSQL (`matches`, `match_players`, `match_rounds`, `round_submissions`, `round_actions`, `match_events`, `match_results`), dịch vụ hàng đợi ghép giao hữu theo môn/khối/chương trình và kiểm định ngân hàng câu đã duyệt.
