# Kế hoạch và kết quả kiểm thử — T030 (B01b)

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Kiểm tra môi trường Flutter/Android/JDK và tải package | `flutter doctor -v` và `flutter pub get` trả kết quả rõ ràng | `.local-sdk\flutter\bin\flutter.bat doctor -v` và `flutter.bat pub get` trong `app/` | Pass (`Flutter 3.50.0 / Dart 3.14.0`, Android SDK `36.0.0`, OpenJDK `25.0.4`, `Got dependencies!`, 16/11/2026) |
| TC-02 | AC-02 | Phân tích tĩnh toàn bộ mã Dart/Flutter (`lib/` và `test/`) | `No issues found!` (exit code 0) | `.local-sdk\flutter\bin\flutter.bat analyze` trong `app/` | Pass (`No issues found! (ran in 12.0s)`, đã sửa toàn bộ 69 lỗi/cảnh báo tĩnh, 16/11/2026) |
| TC-03 | AC-03 | Chạy toàn bộ unit, widget và contract test trong `app/test/` | Tất cả 6 file test đều biên dịch và chạy pass | `.local-sdk\flutter\bin\flutter.bat test -r expanded` trong `app/` | Blocked cục bộ bởi Windows Application Control (`ProcessException: An Application Control policy has blocked this file ... flutter_tester.exe`); mã nguồn test đã pass `flutter analyze` và được cấu hình trong `.github/workflows/ci.yml` (16/11/2026) |
| TC-04 | AC-04 | Chạy Gradle unit test (`testDebugUnitTest`) và đóng gói `assembleDebug` | `AlarmOccurrenceCalculatorTest` (3 ca) và `AlarmSoundResolverTest` (3 ca) pass; tạo được `app-debug.apk` | `gradlew.bat testDebugUnitTest --no-daemon` và `gradlew.bat :app:assembleDebug --no-daemon` với `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr` | Pass (`AlarmOccurrenceCalculatorTest`: 3/3 pass; `AlarmSoundResolverTest`: 3/3 pass; `app/build/app/outputs/flutter-apk/app-debug.apk` tạo thành công `155,263,160` bytes, 16/11/2026) |

## Cổng theo rủi ro

- Phân tích tĩnh Dart/Flutter (`flutter analyze`) và biên dịch AOT/JIT bundle (`compileFlutterBuildDebug`): Pass 100%.
- Kotlin Android unit tests (`AlarmOccurrenceCalculatorTest`, `AlarmSoundResolverTest`) và đóng gói APK debug (`app-debug.apk`): Pass 100%.
- Thực thi `flutter_tester.exe` trên Windows host: Bị chặn bởi Windows Application Control policy (đã dự liệu tại `docs/03-quality/04-moi-truong-chay-thu.md §1`), cần chạy trên GitHub Actions CI hoặc máy đã mở quyền thực thi `flutter_tester.exe`.
