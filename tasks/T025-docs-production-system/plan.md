# Kế hoạch T025

| Bước | Việc | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Kiểm kê docs/code/trạng thái, chốt taxonomy và nguồn chuẩn | Bản đồ tài liệu, không sửa WIP | [x] |
| 2 | Viết bộ docs canonical từ sản phẩm → kỹ thuật → test/release và workflow vibe coding | AC-02, nội dung có thể giao task | [x] |
| 3 | Chuyển docs cũ sang archive, viết index, cập nhật link/AGENTS/README, checker đệ quy | AC-01, AC-03 | [x] |
| 4 | Audit link, mâu thuẫn, command, trạng thái Git; sửa rồi bàn giao/push | TC-01–04 có kết quả thực | [x] |

## Rủi ro và đường lui

Di chuyển nhiều docs làm gãy link lịch sử, nên dùng mapping + kiểm đệ quy và giữ nội dung archive. Docs WIP T023 phải được giữ nguyên nội dung. Mã app/API có thay đổi chưa commit; không stage hoặc reset chúng.
