# Kế hoạch và kết quả kiểm thử T063

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Chạy Kotlin native unit tests `:app:testDebugUnitTest` | 0 failures/errors/skipped | Android Studio JBR + `.\gradlew testDebugUnitTest --no-daemon` | **PASS 12/12 tests** (`AlarmOccurrenceCalculatorTest` 3, `AlarmRingPrivacyAndStateTest` 3, `AlarmSoundResolverTest` 4, `MindClockWidgetFormatterTest` 2) — `2026-11-20` |
| TC-02 | AC-02 | Chạy `integration_test/arena_game_e2e_test.dart` (chọn `arena-timer-30` -> `Thời gian còn: 30s`) trên `emulator-5554` | Pass toàn bộ luồng Game E2E trên Android Emulator | `flutter test --no-pub integration_test\arena_game_e2e_test.dart -d emulator-5554` | **PASS (`02:24 +1: All tests passed!`)** — `2026-11-20` |
| TC-03 | AC-03 | Cài `dist/mindclock-debug.apk` (`152.37 MB`), mở app trên `emulator-5554`, kiểm tra UI tab Luyện tập / Đấu trường & chụp 4 ảnh PNG kiểm chứng | Không có chữ Demo/Thử phiên; timer 30s/45s/60s/90s hiển thị cân đối | `adb install -r dist/mindclock-debug.apk` + `adb shell screencap` (`19`..`22`) | **PASS (xác nhận trực quan 4 ảnh PNG `19`→`22`)** — `2026-11-20` |
