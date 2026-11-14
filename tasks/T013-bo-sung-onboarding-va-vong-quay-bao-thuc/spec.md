# Đặc tả nhiệm vụ T013 — Bổ sung luồng Onboarding cá nhân hóa, Vòng quay 24h & Âm thanh Android

## Vấn đề và kết quả mong muốn

Người dùng bổ sung yêu cầu luồng frontend gồm:
1. Quy trình đăng ký/đăng nhập đơn giản (`tên / mật khẩu / xác nhận mật khẩu mạnh`) để AI cá nhân hóa lịch học → chọn trình độ và môn học tương ứng → tải TKB có sẵn lưu vào hệ thống → chọn avatar có sẵn đã lưu.
2. Dashboard có tùy chọn **vòng quay giờ ngủ – giờ dậy 24h** theo mẫu ảnh 1 (`media_1794620679858_7b86f075.jpg`), kèm lựa chọn **thêm báo thức tùy chọn giờ**.
3. Khi đến giờ, hiện lên màn hình Android (lock-screen/full-screen) với âm thanh tùy chỉnh tạo hứng thú cho người dùng.
4. Gợi ý skill/plugin phù hợp (`/find-skills`).

Task này cập nhật bảng màn hình, 3 phạm vi, component (`SleepWakeDial`), backlog lát cắt dọc (AC ↔ test), ngôn từ/icon chuẩn và các mâu thuẫn/quyết định mới vào `docs/54` và `docs/55` mà **không** phá vỡ các quy tắc cốt lõi của MindClock (báo thức local không bắt buộc login, không chẩn đoán giấc ngủ y khoa, TKB tải lên phải qua xác nhận người học, `Dừng khẩn cấp` luôn sẵn sàng, `Đấu trường` cohort-gated, không đưa roster cũ vào kế hoạch).

## Phạm vi

- **Trong phạm vi:** cập nhật `docs/54-kiem-ke-va-backlog-frontend.md`, `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`, hồ sơ `tasks/T013-*`.
- **Ngoài phạm vi:** chưa viết code Flutter/Kotlin/FastAPI, chưa tự cài plugin marketplace hoặc thay đổi `demo/`.
- **Dữ liệu/role/quyền liên quan:** tách rõ đường `Khách local` (dùng chuông offline không cần login) với đường `Tài khoản online` (Firebase Auth + đồng bộ cá nhân hóa lịch/TKB); kiểm quyền `SCHEDULE_EXACT_ALARM` và `USE_FULL_SCREEN_INTENT` trên Android.
- **Tài liệu chuẩn:** `AGENTS.md`, `docs/04, 05, 13, 16, 23, 24, 27, 30, 31, 32, 41, 45, 47, 48, 52, 53, 54, 55`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi tài liệu phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi bổ sung luồng Login/Onboarding cá nhân hóa vào `docs/54` | Bổ sung đủ màn `A01–A02`, `S03a–S03c` (trình độ/môn, tải TKB có sẵn + duyệt nháp, chọn 1/6 avatar mặc định) và giữ song song đường `Khách local` | TC-01 |
| AC-02 | Khi bổ sung Dashboard vòng quay Giờ ngủ – Giờ dậy 24h theo ảnh 1 | Thêm component `SleepWakeDial` + chế độ `Thêm báo thức tùy chọn giờ` vào bảng màn hình (`S04`/`S06`), component inventory và lát cắt `FE-S02`, tuân thủ token MindClock và không chẩn đoán giấc ngủ | TC-02 |
| AC-03 | Khi bổ sung màn hình báo thức Android full-screen + âm thanh mới | Cập nhật `FE-S02` và bảng asset cho âm thanh chuông tùy chỉnh (`assets/audio/`) + quyền `USE_FULL_SCREEN_INTENT` / fallback notification + `Dừng khẩn cấp` | TC-03 |
| AC-04 | Khi rà ngôn từ & mâu thuẫn mới | Cập nhật `docs/55` (chuỗi UI cho `SleepWakeDial`, đăng ký mật khẩu mạnh, tải TKB) và `docs/54 §5` (nêu rõ mâu thuẫn `tên` vs `Email` Firebase Auth, sao chép giao diện Apple Health, cảnh báo giấc ngủ) | TC-04 |
| AC-05 | Khi hoàn tất & backup | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check` exit 0 và push lên `origin/main` | TC-05 |

## Hợp đồng và trường hợp biên

- Mật khẩu mạnh không được log hoặc lưu ở PostgreSQL (`docs/24 §2`).
- Tải TKB có sẵn (`parse-preview` hoặc file) phải cho xem bản nháp và bấm `Lưu lịch` trước khi AI gợi ý (`docs/32 §1, §4`).
- Vòng quay ngủ–dậy 24h phải xử lý trường hợp qua nửa đêm (`22:30 → 05:30 = 7 giờ`) và hỗ trợ nhập số trực tiếp cho TalkBack/accessibility (không chỉ kéo vòng tròn bằng tay).

## Quyết định/mâu thuẫn

1. Yêu cầu ghi `tên / mật khẩu / xác nhận mật khẩu` trong khi `docs/24` chốt Firebase Auth dùng `Email + Mật khẩu` và biệt danh `3–20` ký tự riêng: giữ `Email + Biệt danh + Mật khẩu mạnh` trong backlog chuẩn và ghi vào mục cần xác nhận nếu muốn thêm username alias.
2. Ảnh 1 là giao diện iOS Apple Health/Bedtime (`Sức khỏe`): chỉ lấy mô hình tương tác vòng quay 24h, không dùng nhãn `"Sửa lịch trình ngủ trong Sức khỏe"` hay kết luận y khoa giấc ngủ (`docs/04, 32, 41`).
