# Kế hoạch và kết quả kiểm thử T008

| ID | AC | Kịch bản | Kỳ vọng | Cách chạy | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Mở web, đổi 3 nhân vật | Đúng ảnh/tên/vai/kit | Trình duyệt desktop | Chưa chạy: công cụ trình duyệt từ chối localhost/file ngày 12/11/2026 |
| TC-02 | AC-02 | Bấm từng trạng thái và chiêu | FX/log tương ứng, không kẹt | Trình duyệt desktop | Chưa chạy trực quan; JS logic và asset kiểm riêng ngày 12/11/2026 |
| TC-03 | AC-03 | Damage qua giáp, heal gần cap, reset | Chỉ số trong khoảng, đúng thứ tự | `node tasks/T008-arena-sprite-web-demo/test_arena_logic.js` | PASS, Windows/Node, 12/11/2026; kiểm Đánh thường, Bước Vững, nội tại Hà Nhân/Hàn Bối Pháp, hết hạn chắn, Dựng Tháp, Kiếm Ý, Đường Kiếm Cuối Trang |
| TC-04 | AC-04 | Viewport hẹp, chữ lớn, reduced motion | Không tràn/flash/emoji | Trình duyệt + CSS | Chưa chạy viewport thật; CSS có media 650px/reduced-motion, cần kiểm máy 12/11/2026 |
| TC-05 | AC-05 | So docs/manifest/file/kit | Prompt, quyền, hướng dẫn nhất quán | Rà file, `python scripts/check_task_records.py` | PASS cấu trúc task, manifest/đường dẫn rà bằng script media, 12/11/2026 |
| TC-06 | AC-06 | Kiểm 9 chuỗi đòn, 9 chuỗi trạng thái, 5 FX | Frame khác nhau, alpha hợp lệ, Animated WebP/MP4 đọc được, không đen mặt | `python scripts/check_arena_motion.py`; xem `qc-motion-contact.jpg`, `qc-mp4-contact.jpg` | PASS: 18 Animated WebP, 18 MP4, 5 FX; 512×512, MP4 24 fps, 12/11/2026 |

Không kiểm PvP online/Android vì demo cục bộ; không suy kết quả cân bằng thật.

`node --check demo/arena.js` và `git diff --check` PASS ngày 12/11/2026. Công cụ browser UI từ chối cả `http://localhost:8000` (timeout) và `file:` (chính sách URL). Không dùng đường vòng. Người trong đội cần mở trang trên Chrome/Edge để hoàn tất TC-01/02/04 trước demo giám khảo.
