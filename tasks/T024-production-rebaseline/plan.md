# Kế hoạch T024

| Bước | Việc | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Kiểm kê Git, hai demo, app/API và link; chốt đường di chuyển an toàn | Không đụng WIP T022/T023 | [x] |
| 2 | Chuyển game asset sang `assets/game`, sửa script, xóa `demo/` và `demo_video/` | AC-01 | [x] |
| 3 | Viết docs production và cấu trúc repo; sửa README/docs index/AGENTS và các link hiện hành | AC-02–03 | [x] |
| 4 | Chạy asset QA, docs links, task checker, API tests phù hợp, rà diff và bàn giao | AC-04, test có bằng chứng | [ ] API runtime treo; các check khác đạt |

## Rủi ro và đường lui

- `demo_video/` chưa được Git theo dõi nên xóa không khôi phục từ Git; người dùng đã yêu cầu xóa đúng hai demo. Kiểm tra resolved path trước recursive delete.
- Art có thể thiếu giấy phép phát hành hoặc trùng phong cách IP; chuyển để bảo toàn nguồn, không mặc định đóng gói app.
- T022/T023 còn sửa chưa commit; không checkout/reset hoặc stage toàn bộ repo.
