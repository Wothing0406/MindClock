# Kế hoạch thực hiện T088

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T088-release-verification-and-github-publish/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Thêm `/download` & `/download/mindclock-android.apk` trong `main.py`, mount read-only trong `docker-compose.yml`, cập nhật `docs/download/index.html`, viết `test_t088_release_gates.py` | `pytest` pass | [x] |
| 3 | Rebuild Docker, chạy live PostgreSQL HTTPS E2E test thật + chạy full verify | Live E2E pass 100% | [x] |
| 4 | Commit & push `main` + `v1.0.0`, xuất bản GitHub Release đính kèm `mindclock-android.apk` và xác minh HTTP download URL thật | GitHub Release hiển thị & tải được thật | [x] |
