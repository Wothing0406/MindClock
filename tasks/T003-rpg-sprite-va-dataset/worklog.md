# Nhật ký T003

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 2026-11-11 | Rà nguồn VNHSGE, VMLU, ViMMRC và skill sprite | Không thể coi repo công khai là quyền nạp corpus | Giữ registry metadata-only; thiết kế staging/duyệt; cài skill đã xác minh | Kiểm tra registry JSON và file skill | Chờ quyền nội dung trước bulk import |
| 2 / 2026-11-11 | Đối chiếu docs cũ còn 3D/kit đồng nhất | Yêu cầu mới đã thay quyết định mỹ thuật và luật nhân vật | Docs/37 làm nguồn mới, sửa docs/22/27/35/36/README/AGENTS | Rà `rg` và `git diff --check` | Cần test task/link rồi bàn giao |
| 3 / 2026-11-11 | `git diff --cached --check` báo whitespace ở 5 file skill vendored | File nguồn có trailing whitespace và dòng trống EOF | Xóa whitespace cuối dòng/EOF, không đổi nội dung chức năng | Restage, `git diff --cached --check` exit 0 | Đạt; tiếp tục commit/push |
