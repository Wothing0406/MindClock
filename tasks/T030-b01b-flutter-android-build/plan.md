# Kế hoạch thực hiện — T030 (B01b)

## Điểm bắt đầu

- Code hiện tại: `app/lib/*`, `app/test/*`, `app/android/app/src/*`.
- Hiện trạng: Đã có Flutter SDK `3.50.0` (Dart `3.14.0`) tại `.local-sdk/flutter/bin/flutter.bat`, Android SDK `36.0.0` tại `C:\Users\QuangDev\AppData\Local\Android\sdk` và Android Studio JBR (`OpenJDK 25.0.4`), nhưng `app/` còn 69 lỗi/cảnh báo tĩnh và `app/android/` thiếu bộ file cấu hình Gradle.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chạy `flutter doctor -v`, `flutter pub get`, `flutter analyze`, `flutter test` trong `app/` | Ghi nhận đầy đủ kết quả và lỗi (nếu có) | [x] |
| 2 | Sửa toàn bộ 69 cảnh báo/lỗi `flutter analyze` trong `app/lib/`, `app/test/`, `pubspec.yaml`, `analysis_options.yaml` và bổ sung cấu hình Gradle chuẩn trong `app/android/` + `.github/workflows/ci.yml` | `flutter analyze` đạt `No issues found!`, `app/android/` đủ cấu hình Gradle | [x] |
| 3 | Chạy Gradle unit test (`testDebugUnitTest`) và `assembleDebug` để kiểm chứng Kotlin unit test và tạo `app-debug.apk` | `testDebugUnitTest` pass 6/6 ca; `app-debug.apk` được tạo thành công | [x] |
| 4 | Cập nhật `docs/00-start/01-hien-trang.md`, `docs/03-quality/03-truy-vet-yeu-cau.md`, `docs/03-quality/04-moi-truong-chay-thu.md`, chạy `check_docs_links.py` + `check_task_records.py` và điền `handoff.md` | Hồ sơ và tài liệu khớp thực tế | [x] |

## Rủi ro và đường lui

- **Rủi ro:** `flutter_tester.exe` trong `.local-sdk/flutter` bị Windows Application Control (WDAC) chặn thực thi trên máy Windows hiện tại.
- **Đường lui:** Ghi nhận trung thực lỗi WDAC trên `flutter_tester.exe`, giữ trạng thái `T030` là `verifying`, đảm bảo `flutter analyze` + `compileFlutterBuildDebug` + `testDebugUnitTest` + `assembleDebug` pass 100% trên máy local và cấu hình `.github/workflows/ci.yml` để chạy `flutter test` trên Ubuntu CI.
