# Đặc tả kiểm nhận T054

| ID | Tiêu chí chấp nhận | Cách kiểm |
| --- | --- | --- |
| AC-01 | `app/assets/arena/` có đủ 1 map (`map_courtyard.png`), 3 chân dung tướng (`champ_*.png`), 7 skill icons (`skill_*.png`) và `manifest.json` (`team_generated_original`), ảnh mở kiểm bằng công cụ đọc ảnh thấy rõ nét, đúng chủ đề, không chữ lỗi; được khai báo trong `app/pubspec.yaml`. | Kiểm tệp ảnh tồn tại, đọc kiểm thị giác các ảnh vừa tạo & `flutter test`. |
| AC-02 | Màn chọn tướng trước trận (`Thiết lập Luyện đơn`) hiển thị chân dung từng tướng, tên + mô tả Nội tại, tóm tắt Chiêu 1/Chiêu 2 và nút xem chi tiết từng tướng (`arena-champion-detail-<id>`) để học sinh xem đầy đủ thông số/mô tả + icon từng skill trước khi vào đánh. | Widget test `solo_arena_widget_test.dart`. |
| AC-03 | `ArenaStageWidget` và bảng chọn chiêu trong trận hiển thị map nền, chân dung 2 bên, và icon từng skill với `errorBuilder` fallback an toàn về vector khi asset lỗi hoặc bật `assetFallbackMode`, không làm gãy layout 320dp chữ 200% hay chế độ `Reduce Motion`. | Widget test `solo_arena_widget_test.dart` (`320dp`, chữ 200%, fallback mode & Reduce Motion). |
| AC-04 | `flutter analyze --no-pub`, full `flutter test`, `RAW_COLOR_HITS: 0`, `check_docs_links.py`, `check_task_records.py` PASS 100%, commit & push `origin/main`. | Chạy lệnh kiểm tra sau sửa cuối. |
