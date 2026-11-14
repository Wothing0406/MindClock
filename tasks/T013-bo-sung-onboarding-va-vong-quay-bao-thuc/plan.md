# Kế hoạch thực hiện T013

## Điểm bắt đầu

- Đã có `docs/54` (`T011`) và `docs/55` (`T012`, commit `ea29e49`).
- Ảnh mẫu 1 (`media_1794620679858_7b86f075.jpg`) đã xem trực tiếp; kết quả tìm plugin marketplace (`flutter`, `android-cli-plugin`, `firebase`) và danh sách skill `.agents/skills/` đã kiểm tra.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T013-bo-sung-onboarding-va-vong-quay-bao-thuc/` (`README.md`, `spec.md`, `plan.md`, `tests.md`) | Đủ cổng trước thay đổi | [x] |
| 2 | Cập nhật `docs/54-kiem-ke-va-backlog-frontend.md`: bổ sung màn hình, component `SleepWakeDial`, asset âm thanh tùy chỉnh, AC/test cho `FE-S02`/`FE-S03`/`FE-S05` và các mâu thuẫn mới | Khớp đủ 5 yêu cầu xuất + giữ nguyên quy tắc MindClock | [x] |
| 3 | Cập nhật `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`: thêm chuỗi chuẩn, icon và quy tắc TalkBack cho `Login/Sign-up`, `Tải TKB`, `SleepWakeDial` 24h | Không mâu thuẫn giữa `docs/54` và `docs/55` | [x] |
| 4 | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check`; cập nhật `tests.md`, `worklog.md`, `handoff.md`, `README.md` | Mọi check exit 0 | [x] |
| 5 | Commit và push lên `origin/main` | Working tree clean, push thành công | [x] |

## Rủi ro và đường lui

- **Rủi ro ép đăng nhập làm hỏng đường khách offline:** nếu biến onboarding login thành bắt buộc sẽ phá quy tắc P0 (`docs/04, 24, 41`). **Đường lui:** giữ rõ nút `Dùng thử không cần tài khoản` ở bước đầu và cho phép đặt chuông local offline bất kỳ lúc nào.
- **Rủi ro copy giao diện Apple hoặc chẩn đoán giấc ngủ:** **Đường lui:** gắn rõ dùng token MindClock (`docs/55`) và câu nhắc theo mục tiêu tự chọn, không nhãn y khoa.
