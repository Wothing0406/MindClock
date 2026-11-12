# Test T010

| ID | AC | Kiểm tra | Kết quả |
| --- | --- | --- | --- |
| TC-01 | AC-01 | 6 badge khác nhau, SVG hợp lệ, khác 7 khung; kết quả/profile có vị trí và alt/nhãn | Đạt asset/DOM tĩnh: `check_game_assets.py` xác nhận 6 SVG XML khác nhau, khung riêng, kết quả/profile có ảnh và nhãn; chờ xem browser |
| TC-02 | AC-02 | PNG/JPEG/WebP ≤2 MB preview; sai MIME/size từ chối; đổi ảnh thu hồi URL; không có fetch/upload | Đạt rule unit `test_profile_rules.js` và rà code Object URL; chưa thử file picker Android |
| TC-03 | AC-03 | ma trận chủ/khách/ẩn bảng, lịch sử riêng, xóa account/opt-out | Đặc tả ở docs/52; **chưa có backend để test truy cập thật** |
| TC-04 | AC-04 | sai bài/uncertain/dừng khẩn không trừ uy tín; báo cáo xác minh và kháng nghị | Đặc tả docs/52; **chưa có backend để test** |
| TC-05 | AC-05 | quy tắc tên/ảnh, tạm ẩn, báo cáo, kháng nghị và log tối thiểu | Đặc tả docs/53; **chưa có moderation thật để test** |
| TC-06 | AC-06 | README có đủ trục sản phẩm và trạng thái thật, link docs tồn tại | Đạt rà nội dung và `check_docs_links.py` (55 file) |
| TC-07 | AC-07 | task checker, git diff, commit/push remote | Đạt: commit asset/docs `1aa6af70f20496ff41f7c6b36c57b15e283fecbc` trên `origin/main`, GitHub API xác nhận cùng SHA; handoff bổ sung được đẩy ở commit kế tiếp |

**Lệnh đã chạy 12/11/2026 Windows:** `node tasks/T010-ho-so-huy-hieu-va-noi-dung/test_profile_rules.js`, `python scripts/check_game_assets.py`, `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` đều exit 0. Không suy diễn test docs là API/kiểm duyệt đã chạy.
