# Kế hoạch thực hiện T080

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T080-circular-sleep-clock-and-apk-release/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Tạo `CircularSleepClockPicker` dùng `MindClockTheme` và tích hợp vào `AlarmConfigScreen` | Kéo giờ ngủ/dậy hoạt động, giữ đồng bộ nút tinh chỉnh | [x] |
| 3 | Viết widget test `t080_circular_sleep_clock_test.dart` & chạy `flutter analyze` + `flutter test` | 0 lỗi phân tích tĩnh, toàn bộ test pass | [x] |
| 4 | Tạo `scripts/build_release_apk.ps1`, `.github/workflows/android-release-apk.yml`, `docs/download/index.html` và build APK trỏ `https://api.ieltsoasis.site` | Sinh file `.apk` thành công | [x] |
| 5 | Cập nhật `tests.md`, `handoff.md` và chạy `check_task_records.py` / `check_docs_links.py` | Toàn bộ cổng xanh | [x] |
