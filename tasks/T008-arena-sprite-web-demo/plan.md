# Kế hoạch T008

Repo có `demo/index.html` prototype và docs/46, chưa có sprite/runtime PvP. Ảnh tham chiếu nằm ngoài repo.

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo master/pose sprite 2D, manifest và prompt | File xem được, ghi giới hạn quyền | [x] |
| 2 | Dựng `demo/arena.html`, CSS/JS và điều khiển | Chọn nhân vật, chạy các action | [x] |
| 3 | Tạo 9 action sheet, 3 state sheet, 5 VFX sheet; cắt/khử nền/xuất WebP+MP4 và gắn vào web | Chuyển động nhiều frame thật, QC trên nền tối | [x] |
| 4 | Bổ sung docs luật/asset và hướng dẫn | Kit, FX, giới hạn demo rõ | [x] |
| 5 | Test trình duyệt, responsive, task gate, diff | Test tự động đạt; browser QA còn chờ máy người dùng | [ ] |

## Rủi ro/đường lui

Ảnh có thể thuộc IP bên thứ ba: không đóng gói ảnh gốc, asset AI chỉ nghiên cứu/demo tới khi kiểm quyền. Frame tự động có thể lệch: ghi prototype và dùng fallback tĩnh. Không đổi luật combat authoritative bằng demo.
