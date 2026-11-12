# Kế hoạch và kết quả kiểm thử T009

| ID | AC | Kịch bản | Kỳ vọng | Cách chạy | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | So alpha bbox/foot/scale 3 master và frame; actor trái/phải | cùng baseline/height; không cắt chân | script geometry + ảnh sân | Đạt baseline/tỉ lệ tĩnh; nhận định hướng ngày 12/11 bỏ sót Hàn Bối Pháp khi ở slot trái. Đã mở TC-09 để sửa và kiểm lại. Chưa xem motion trên máy thật |
| TC-02 | AC-02 | 3×3 đòn; tự buff/hồi; projectile hai hướng | đúng loại VFX, origin/impact/target | JS unit + asset QA | Đạt logic: `test_arena_renderer.js` kiểm target hai phía; 9 FX SVG khác nhau. Chờ xem hình động Android |
| TC-03 | AC-03 | hurt/stun/win/mute/skip | âm chỉ sau click, đúng tướng/hành động, số đúng | JS + manual audio | Đạt cấu trúc: 21 clip, 17 WAV có format/peak hợp lệ; code bật/tắt/bỏ qua. Chưa nghe trên thiết bị |
| TC-04 | AC-04 | 320/360/390px portrait, desktop | không tràn, đề/nút luôn dùng được | browser/manual hoặc static fallback | Đã kiểm CSS/logic và ảnh stage 360×380; **chưa đạt kiểm browser/Android thật** vì công cụ UI không mở localhost/file |
| TC-05 | AC-05 | xem mọi tướng, khóa thiếu khí | mô tả đầy đủ, tiếng Việt rõ | DOM/JS | Đạt kiểm ID/field và JS syntax; cần thao tác tay trên Android |
| TC-06 | AC-06 | kiểm map/avatar/rank/folder/manifest | file tồn tại/ảnh đọc được/size đúng | Python asset QA | Đạt `python scripts/check_game_assets.py`, 12/11/2026 Windows; rebuild lại source/scripts thành công |
| TC-07 | AC-07 | rà README/docs và link | trạng thái thật/đường dẫn đúng | docs audit | Đạt `python scripts/check_docs_links.py`: 55 file, README đầy đủ các trục; không gọi mock là live |
| TC-08 | AC-08 | task gate/diff/git push | commit+remote SHA đúng, không lộ ảnh gốc | checker/git | Đạt: commit asset/docs `1aa6af70f20496ff41f7c6b36c57b15e283fecbc` trên `origin/main`, GitHub API xác nhận cùng SHA; ảnh gốc không nằm trong repo. Handoff bổ sung được đẩy ở commit kế tiếp |

Không coi web demo là test PvP online/Android/iOS.

## Hồi quy hướng nhìn ngày 13/11/2026

| ID | AC | Kịch bản | Kỳ vọng | Cách chạy | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-09 | AC-09 | Hàn Bối Pháp ở slot trái và phải, cặp với Tuyệt Đỉnh/Hà Nhân; mọi action dùng cùng quy tắc lật | Cặp tướng nhìn nhau, chân/size không đổi | Xem hai ảnh `stage-han-boi-phap-vs-tuyet-dinh.png` và `stage-ha-nhan-vs-han-boi-phap.png`; chạy unit facing và asset manifest | Đạt phần tĩnh/logic: source `basic.png` gốc nhìn phải, hai ảnh preview cho thấy mặt quay vào nhau; `test_arena_renderer.js` và `check_game_assets.py` đạt. Chưa xem motion trên Android thật. |

**Lệnh đã chạy:** `node --check demo/arena.js`, `node --check demo/arena-renderer.js`, `node tasks/T009-arena-doc-va-asset/test_arena_rules.js`, `node tasks/T009-arena-doc-va-asset/test_arena_renderer.js`, `python scripts/check_game_assets.py`, `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check`. Tất cả exit 0 ngày 12/11/2026. `git diff --check` chỉ báo chuyển LF/CRLF của Windows, không có lỗi whitespace.

**Chạy lại 13/11/2026 sau sửa TC-09:** `node --check demo/arena-renderer.js`, `node tasks/T009-arena-doc-va-asset/test_arena_renderer.js`, `python scripts/check_game_assets.py`, `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` đều exit 0. `git diff --check` chỉ in cảnh báo LF/CRLF, không có lỗi whitespace.
