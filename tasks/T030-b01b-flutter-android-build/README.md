# T030 — B01b: Ổn định Flutter analyze/test, cấu hình Android Gradle và build APK debug

- **Trạng thái:** `verifying`
- **Mục tiêu:** Chạy và xác nhận `flutter doctor`, `flutter analyze`, hoàn thiện cấu hình Android Gradle project (`settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts`, `gradle.properties`, wrapper) cho `com.mindclock.app`, chạy pass Kotlin unit test (`testDebugUnitTest`), đóng gói thành công `app-debug.apk` và tạo pipeline CI `.github/workflows/ci.yml`.
- **Nguồn yêu cầu:** Yêu cầu người dùng ngày 16/11/2026; `docs/00-start/05-goi-task-dau-tien.md` (B01b); `docs/00-start/02-lo-trinh.md` (R0/B01).
- **Chủ sở hữu/reviewer:** AI Coding Agent.
- **Phạm vi file dự kiến:** `app/pubspec.yaml`, `app/analysis_options.yaml`, `app/lib/*`, `app/test/*`, `app/android/*`, `.github/workflows/ci.yml`, `.gitignore`, `docs/00-start/01-hien-trang.md`, `docs/03-quality/03-truy-vet-yeu-cau.md`, `docs/03-quality/04-moi-truong-chay-thu.md`, `tasks/T030-b01b-flutter-android-build/*`.
- **Liên quan:** Tiếp nối `T029-b01a-on-dinh-backend-test`; mở khóa biên dịch Android bị thiếu ở `T014`–`T020`.
- **Source refs đã đọc:** `AGENTS.md §1–5`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/05-goi-task-dau-tien.md`, `docs/02-engineering/02-bao-thuc-android.md`, `docs/03-quality/01-ke-hoach-kiem-thu.md`, `docs/03-quality/04-moi-truong-chay-thu.md`, `.agents/skills/mindclock-android-native/SKILL.md`.
- **Điểm tiếp tục:** Chạy `flutter test -r expanded` trên GitHub Actions CI (`.github/workflows/ci.yml`) hoặc sau khi thêm ngoại lệ Windows Application Control (WDAC) cho `.local-sdk\flutter\bin\cache\artifacts\engine\windows-x64\flutter_tester.exe`.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
