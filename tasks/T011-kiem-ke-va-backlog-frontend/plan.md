# Kế hoạch thực hiện T011

## Điểm bắt đầu

- Repo hiện có tài liệu `docs/01–53`, bản xem thử web `demo/index.html`, `demo/arena.html` và asset tại `demo/assets/game/`.
- Chưa có Flutter app (`pubspec.yaml`), chưa có Kotlin native hay backend FastAPI đang chạy; máy hiện tại có Python 3.11 và Node.js, chưa có `flutter` và `adb` trong `PATH`.
- T009 và T010 đang ở trạng thái `verifying` (chưa kiểm trên Chrome/Android thật).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Đọc đầy đủ các docs theo yêu cầu, handoff T009/T010 và toàn bộ file `demo/` + `manifest.json` | Đọc hết nguồn, ghi nhận đủ số liệu/mâu thuẫn thực tế | [x] |
| 2 | Tạo hồ sơ task `tasks/T011-kiem-ke-va-backlog-frontend/` (`README.md`, `spec.md`, `plan.md`, `tests.md`) trước khi viết docs | Có đủ hồ sơ trước khi tạo `docs/54` | [x] |
| 3 | Viết `docs/54-kiem-ke-va-backlog-frontend.md` đủ 5 mục kiểm kê & backlog lát cắt dọc; cập nhật chỉ mục `docs/README.md` | Đủ 5 mục, không sót màn/luồng, không dùng roster cũ | [x] |
| 4 | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check`; hoàn thiện `tests.md`, `worklog.md`, `handoff.md`, `README.md` | Mọi script check pass, kết quả ghi trung thực | [x] |
| 5 | Commit và push lên `origin/main` để backup theo yêu cầu | Push thành công, working tree clean | [x] |

## Rủi ro và đường lui

- **Rủi ro nhầm trạng thái:** người đọc có thể hiểu nhầm backlog/kiểm kê là app đã sẵn sàng chạy. **Đường lui:** gắn rõ trạng thái `đặc tả kiểm kê, chưa có code Flutter/APK` ở đầu `docs/54`, `handoff.md` và trong câu trả lời cuối.
- **Rủi ro sai lệch dẫn chứng:** trích nhầm tên màn, endpoint, số XP hoặc file asset. **Đường lui:** mọi đường dẫn và ký hiệu chỉ viết từ file đã đọc trực tiếp trong phiên.
