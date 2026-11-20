# T063 — Kiểm chứng Android Gradle Kotlin, Emulator E2E sau T062 & kết nối live APK với Docker API

- **Trạng thái:** `done`
- **Mục tiêu:** Xác minh toàn bộ code sau T062 chạy thật trên Android: (1) Chạy pass Gradle `:app:testDebugUnitTest` cho toàn bộ lớp Kotlin báo thức/receiver/widget; (2) Chạy pass `integration_test/arena_game_e2e_test.dart` trên `emulator-5554` (bao gồm kiểm tra chọn timer 30s ở Setup); (3) Cài đặt `dist/mindclock-debug.apk` (`152.37 MB`) lên `emulator-5554`, kiểm chứng kết nối mạng thật từ emulator tới Docker API `http://10.0.2.2:8000/v1/health`, kiểm tra TKB/Offline Bank/Arena Timer/Không còn nhãn demo trên UI sống và cập nhật screenshot/video bằng chứng trong `test_demo_android/`.
- **Nguồn yêu cầu:** Tiếp tục quy trình kiểm chứng & bàn giao sau T062 (`2026-11-20`).
- **Chủ sở hữu/reviewer:** Chủ dự án MindClock.
- **Phạm vi file dự kiến:** `app/integration_test/arena_game_e2e_test.dart`, `test_demo_android/*`, `docs/00-start/01-hien-trang.md`, `tasks/T063-*/*`.
- **Liên quan:** Nối tiếp `T061`, `T062`.
- **Source refs đã đọc:** `AGENTS.md §4`, `docs/03-quality/01-ke-hoach-kiem-thu.md`, `scripts/build_android_apk.ps1`, `app/integration_test/arena_game_e2e_test.dart`.
- **Điểm tiếp tục:** Chạy Kotlin Gradle tests, Android E2E trên `emulator-5554`, verify live APK với Docker API, chụp ảnh màn hình mới và push `origin/main`.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định phạm vi kiểm chứng thực tế sau T062.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
