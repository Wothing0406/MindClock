# Đặc tả nhiệm vụ — T030 (B01b: Flutter/Android build và test)

## Vấn đề và kết quả mong muốn

Trong các task `T014`–`T020`, mã Flutter (`app/lib/`, `app/test/`) và mã Kotlin (`app/android/app/src/main/kotlin/com/mindclock/app/`, `app/android/app/src/test/kotlin/com/mindclock/app/`) đã được viết nhưng chưa được xác nhận bằng `flutter analyze` và `flutter test`. Ngoài ra, thư mục `app/android/` hiện thiếu các tệp cấu hình Gradle gốc (`settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `app/build.gradle.kts`, Gradle wrapper) khiến dự án Android không thể chạy `./gradlew testDebugUnitTest` hoặc `flutter build apk --debug`.

Sau task này:
1. Chạy `flutter doctor -v`, `flutter pub get`, `flutter analyze` và `flutter test` trên toàn bộ test suite Dart/Flutter trong `app/test/`, sửa dứt điểm mọi lỗi phân tích tĩnh hoặc lỗi test nếu phát sinh.
2. Bổ sung đầy đủ cấu hình Gradle chuẩn Flutter Android (`com.mindclock.app`, Kotlin + JUnit4 cho `testDebugUnitTest`) trong `app/android/` mà không làm mất `AndroidManifest.xml`, Kotlin sources, `res/raw/alarm_bermuda.mp3` hay unit test hiện có.
3. Kiểm tra thực tế khả năng chạy Gradle unit test và build APK debug trên máy hiện tại; ghi nhận chính xác kết quả hoặc điều kiện môi trường còn thiếu (Android SDK / JDK) theo quy tắc trung thực của `AGENTS.md`.

## Phạm vi

- **Trong phạm vi:**
  - Chạy và sửa lỗi (nếu có) cho `flutter analyze` và `flutter test` trong `app/`.
  - Khởi tạo/bổ sung bộ file Gradle cho `app/android/` (`settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `app/build.gradle.kts`, `gradle/wrapper/*`, `gradlew`, `gradlew.bat`).
  - Kiểm tra thực thi Gradle (`testDebugUnitTest` / `flutter build apk --debug`) và ghi nhận bằng chứng thực tế.
  - Cập nhật `docs/00-start/01-hien-trang.md` và `docs/03-quality/04-moi-truong-chay-thu.md`.
- **Ngoài phạm vi:**
  - Kiểm thử báo thức trên 2 máy vật lý Android thật (thuộc `B02`).
  - Thay đổi tính năng sản phẩm hoặc API backend.
- **Dữ liệu/role/quyền liên quan:**
  - Giữ nguyên cấu hình biến môi trường an toàn trong `app/.env.example` (không nhúng Gemini API key vào client, `MINDCLOCK_DEBUG_FIXTURE=false` mặc định).
- **Tài liệu chuẩn:**
  - `AGENTS.md §3, §4, §5`
  - `docs/00-start/01-hien-trang.md`
  - `docs/00-start/02-lo-trinh.md` (R0/B01)
  - `docs/00-start/05-goi-task-dau-tien.md` (B01b)
  - `docs/02-engineering/02-bao-thuc-android.md`
  - `docs/03-quality/01-ke-hoach-kiem-thu.md`
  - `docs/03-quality/04-moi-truong-chay-thu.md`

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi chạy `flutter doctor -v` và `flutter pub get` trong `app/` | Xác định rõ phiên bản Flutter/Dart, trạng thái Android SDK/JDK/device trên máy hiện tại và tải đủ dependencies | TC-01 |
| AC-02 | Khi chạy `flutter analyze` trong `app/` | Kết thúc với `No issues found!` (exit code 0) | TC-02 |
| AC-03 | Khi chạy `flutter test` trong `app/` | Toàn bộ 6 file unit/widget/contract test trong `app/test/` chạy pass 100% | TC-03 |
| AC-04 | Khi kiểm tra cấu hình `app/android/` và chạy Gradle unit test / `flutter build apk --debug` | Có đủ `settings.gradle.kts`, `build.gradle.kts`, `app/build.gradle.kts` (`namespace = "com.mindclock.app"`, JUnit 4 test dependency), `gradle.properties`, wrapper; chạy thử Gradle/build APK và ghi nhận kết quả thực | TC-04 |

## Hợp đồng và trường hợp biên

- Giữ nguyên 100% hợp đồng MethodChannel (`mindclock/alarm_scheduler`, `mindclock/camera_capture`, `mindclock/study_focus`) và `package com.mindclock.app`.
- Không thêm Hilt, Jetpack Compose, Flutter Driver extension hoặc dependency ngoài phạm vi.

## Quyết định/mâu thuẫn

- Nếu máy Windows hiện tại chưa cài Android SDK (`ANDROID_HOME`) hoặc JDK 17+ cho Gradle, tuyệt đối không giả lập build APK thành công; phải hoàn thiện cấu hình Gradle chuẩn để sẵn sàng chạy ngay khi có Android SDK/CI, đồng thời xác nhận 100% `flutter analyze` và `flutter test` chạy thật.
