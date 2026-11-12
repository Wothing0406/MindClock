# Nhật ký T010

| Vòng/ngày | Tái hiện và nguyên nhân | Sửa | Test lại/kết luận |
| --- | --- | --- | --- |
| 1 / 12-11-2026 | Khung rank trong T009 bị dùng như huy hiệu; chưa có biểu trưng kết quả/profile. | Tạo 6 badge SVG riêng folder `ui/rank/badges`, bộ chọn badge và thẻ kết quả mẫu. | Asset checker xác nhận 6 SVG hợp lệ/khác nhau; chưa xem trên browser thật. |
| 2 / 12-11-2026 | Docs/52 dự thảo tạo bảng `profiles` thứ hai trong khi docs/28 có `users`; mô tả bậc Roman cũng lệch công thức docs/37. | Mở rộng `users`, dùng `competition_profiles` là projection; bậc số 1–5; đồng bộ docs/07/28/44. | Kiểm docs/52 thủ công và `check_docs_links.py` đạt. |
| 3 / 12-11-2026 | Upload profile chưa có giới hạn rõ, dễ bị hiểu là lưu thật. | Preview Object URL local, nút về avatar mặc định, MIME/size/dimension gate, nhãn không upload; docs/52–53 mô tả backend pending/duyệt/xóa. | `test_profile_rules.js` đạt; cần thử file picker trên Chrome Android thật. |

Chủ dự án xác nhận có quyền đăng công khai ảnh tham chiếu và sprite phát sinh ngày 12/11/2026. Quyền thương mại/phát hành app là quyết định riêng.
