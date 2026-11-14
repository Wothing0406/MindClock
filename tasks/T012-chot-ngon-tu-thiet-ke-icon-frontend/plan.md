# Kế hoạch thực hiện T012

## Điểm bắt đầu

- Đã có bản kiểm kê `docs/54-kiem-ke-va-backlog-frontend.md` (`T011`, commit `3a82c48`).
- `docs/13` còn dòng tham chiếu cũ tới `docs/37` và cụm `Tắt khẩn cấp`/`Bắt đầu`; chưa có bảng tra chuỗi `AppStrings` và bảng icon chi tiết theo màn cho Flutter.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T012-chot-ngon-tu-thiet-ke-icon-frontend/` (`README.md`, `spec.md`, `plan.md`, `tests.md`) | Đủ cổng trước coding | [x] |
| 2 | Viết `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md` gồm: chốt nhãn mâu thuẫn, từ cấm, tách thuật ngữ, bảng chuỗi theo màn/trạng thái, tokens UI, bảng icon + `semanticLabel` | Đủ 4 AC trong `spec.md` | [x] |
| 3 | Cập nhật `docs/13`, `docs/54`, `docs/README.md` cho nhất quán | Không còn tham chiếu lệch trong `docs/13` | [x] |
| 4 | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check`; cập nhật `tests.md`, `worklog.md`, `handoff.md`, `README.md` | Mọi check exit 0 | [x] |
| 5 | Commit và push lên `origin/main` | Working tree clean, push thành công | [x] |

## Rủi ro và đường lui

- **Rủi ro ghi đè ý nghĩa quy tắc sản phẩm:** khi gộp chuỗi từ nhiều docs có thể làm sai rule chế độ thử thách hoặc quyền riêng tư. **Đường lui:** trích dẫn đúng nguồn `docs/05, 27, 30, 31, 45, 52, 53` cho từng nhóm chuỗi và giữ nguyên toàn bộ ràng buộc an toàn.
