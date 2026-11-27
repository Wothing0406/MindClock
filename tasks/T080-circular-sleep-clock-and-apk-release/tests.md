# Kế hoạch và kết quả kiểm thử T080

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Render `CircularSleepClockPicker` & `AlarmConfigScreen` ở `320dp` `200%`, kéo nút wake/bedtime và bấm nút tinh chỉnh giờ | Thời lượng ngủ (`X giờ Y phút`) cập nhật khớp giờ mới, không overflow | `flutter test --no-pub -j 1 test/t080_circular_sleep_clock_test.dart test/alarm_ai_preview_and_candle_test.dart` | PASS (4/4 test, 0 overflow, `dart analyze --fatal-infos` & `flutter analyze` 0 issues) — 27/11/2026 |
| TC-02 | AC-02 | Build APK release trỏ `https://api.ieltsoasis.site` | Sinh `dist/apk/mindclock-android.apk` | `.\scripts\build_release_apk.ps1` | PASS — `Built build\app\outputs\flutter-apk\app-release.apk (66.5MB)`, xuất ra `dist/apk/mindclock-android.apk` — 27/11/2026 |
