# Nhật ký T024

| Vòng/ngày | Phát hiện | Quyết định | Kiểm chứng |
| --- | --- | --- | --- |
| 1 / 15-11-2026 | Có Flutter/Android và FastAPI thực tế, nhưng README/docs 06/48/50 nói chưa có; hai demo folder ở gốc. WIP T022/T023 chưa commit. | Chuyển art tái dùng sang `assets/game`, xóa hai demo, giữ WIP, viết rebaseline production. | Chờ test TC-01–04. |
| 2 / 15-11-2026 | Sau khi chuyển art, `check_game_assets.py` còn đọc `arena.html` đã xóa; `build_game_assets.py` còn ghi path demo cũ. | Bỏ QA DOM web khỏi checker art; sửa mọi script sang `assets/game/`. | Builder, preview và asset QA đạt; 228 file art còn đủ. |
| 3 / 15-11-2026 | `pytest -q` không in kết quả sau >90 giây; test health riêng treo trong TestClient. Diff toàn repo báo trailing whitespace trong `demo_ui.py` WIP T022. | Không sửa mã T022/T023 khi chưa xác định nguyên nhân; ghi giới hạn và bàn giao. | Collection 14 tests đạt; diff phạm vi T024 sạch; API runtime chưa xác minh. |
