# Bàn giao T008

**Lưu ý 12/11/2026:** T009 đã thay thế toàn bộ asset `demo/assets/arena` bằng `demo/assets/game/characters/{slug}`, map/FX/âm riêng và sân dọc. Exporter/checker cũ đã bỏ; các đường dẫn/test dưới đây là hồ sơ lịch sử, không phải trạng thái repo hiện tại. Dùng `scripts/check_game_assets.py` và test T009. Chủ dự án xác nhận có quyền đăng ảnh tham chiếu và sprite phát sinh lên repo công khai.

- **Trạng thái cuối:** `verifying`, chưa gắn done vì chưa kiểm thao tác bằng trình duyệt thật và chưa xác minh quyền ảnh tham chiếu.
- **Đã làm:** ba master theo thứ tự ảnh người dùng, 18 pose cắt, 9 chuỗi đòn sáu frame, 9 chuỗi trạng thái bốn frame, 5 FX sáu frame; web sân tập phát Animated WebP và MP4 xem lại, có HP/giáp/chắn/khí và nhật ký tiếng Việt.
- **File chính:** `demo/arena.html`, `demo/arena.css`, `demo/arena.js`, `demo/assets/arena/manifest.json`, `demo/assets/arena/motion/*`, `docs/49-sprite-ba-nhan-vat-va-web-demo.md`, `scripts/export_arena_motion.py`, `scripts/check_arena_motion.py`.
- **Test đã chạy:** `node --check demo/arena.js`, `node tasks/T008-arena-sprite-web-demo/test_arena_logic.js`, `python scripts/check_arena_motion.py`, `python scripts/check_task_records.py`, `git diff --check` đều đạt ngày 12/11/2026 Windows. Đã xem `qc-motion-contact.jpg` và `qc-mp4-contact.jpg`.
- **Chưa chạy:** tương tác browser/viewport/mobile thật: CUA timeout ở localhost và cấm file:; không thử đường vòng. Chưa test Android runtime hay cân bằng trận thật.
- **Rủi ro:** ảnh người dùng cung cấp có quyền chưa rõ, không đưa ảnh gốc vào repo; generated asset vẫn chỉ nghiên cứu/demo. MP4 là sprite frame đóng gói, không phải video AI image-to-video; 2-frame state còn ngắn, cần họa sĩ chỉnh baseline/biểu cảm. Web sandbox không có server.
- **Điểm tiếp tục:** trên máy của đội mở `http://localhost:8000/demo/arena.html` sau `python -m http.server 8000`; chạy TC-01/02/04 trên Chrome/Edge desktop và viewport điện thoại, ghi kết quả vào `tests.md`; nếu đạt thì mới chuyển trạng thái `done`. Trước khi public/push asset, xác minh quyền hình tham chiếu hoặc thay art gốc.
