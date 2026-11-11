# Kế hoạch T004

## Điểm bắt đầu

Repo docs-only, registry metadata; chưa có importer/app/backend. Nguồn ngoài cần xác minh giấy phép, không suy quyền từ việc tải được.

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Xác minh nguồn, tải nghiên cứu riêng tư nếu được, ghi manifest | VNHSGE 406 JSON/17.054 mục; VMLU mirror 3 JSONL/10.880 mục, hash/commit ghi lại | [x] |
| 2 | Viết đặc tả trình bày/chấm, PvP/nhân vật/map, adaptive/wake | docs/39–40 và docs/32 có công thức, state, ví dụ và copy UI | [x] |
| 3 | Đồng bộ docs chuẩn, registry, nguồn đọc | docs/07/09/14/21/22/28/31/34/35/36/37/38/README và registry cập nhật | [x] |
| 4 | Kiểm tra link/JSON/git diff/task records, bàn giao | bằng chứng thật trong tests/handoff; chạy lại task checker sau tạo handoff | [x] |

## Rủi ro và đường lui

Nguồn đề có quyền chưa rõ: chỉ staging nghiên cứu không commit/không phát hành; nếu tải bị chặn giữ metadata và ghi rõ. Chấm trình bày thiếu tin cậy: giữ giao hữu, ranked off. Kỹ năng mất cân bằng: feature flag tắt thẻ riêng trong ranked và giữ thẻ chung. AI wake suggestion sai: yêu cầu người dùng xác nhận và luôn cho sửa tay.
