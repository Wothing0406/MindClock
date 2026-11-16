# Kế hoạch và kết quả kiểm thử — T032 (B02)

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Kiểm tra `LockScreenPrivacyFormatter` khi `isKeyguardLocked = true` và `showLockScreenDetails = false` | Trả về tiêu đề `"Báo thức 06:00"`, phụ đề `"Mở để xem kế hoạch hôm nay"`, không chứa `"TOAN"` hay `"Ôn phương trình"` | `gradlew.bat :app:testDebugUnitTest` (`AlarmRingPrivacyAndStateTest.lockScreenHidesSubjectAndCustomLabelByDefaultWhenLocked`) | Pass (16/11/2026) |
| TC-02 | AC-02 | Kiểm tra `LockScreenPrivacyFormatter` khi `isKeyguardLocked = false` hoặc `showLockScreenDetails = true` | Trả về nhãn đầy đủ kèm mã môn `"Ôn định luật Ôm • VAT_LY"` | `gradlew.bat :app:testDebugUnitTest` (`AlarmRingPrivacyAndStateTest.unlockedScreenOrOptInShowsFullLabelAndSubject`) | Pass (16/11/2026) |
| TC-03 | AC-03 | Kiểm tra chuyển trạng thái `RingPayloadRecord` khi bấm `Mở câu` (`markSoundStoppedForReview`) và cấu hình `AlarmRingService` | `ringState` chuyển từ `ringing` sang `sound_stopped_review_active`; JSON serialize/deserialize bảo toàn trạng thái | `gradlew.bat :app:testDebugUnitTest` (`AlarmRingPrivacyAndStateTest.openingQuestionTransitionsPayloadToSoundStoppedReviewActive`) | Pass (16/11/2026) |
| TC-04 | AC-04 | Chạy `flutter analyze` và `gradlew.bat :app:testDebugUnitTest` | `flutter analyze` 0 lỗi; Kotlin unit test 9/9 pass (3 file test) | Windows 11 + Flutter 3.50 + OpenJDK 25.0.4 + Android SDK 36 | Pass (`No issues found!`, `9/9` Kotlin tests pass, 16/11/2026) |
| TC-05 | AD01–AD07 | Kiểm thử vật lý trên 2 máy Android thật (khóa màn hình, kill app, offline, từ chối quyền, Dừng khẩn cấp, reboot) | Chuông reo/dừng đúng hạn, màn khóa ẩn môn, `Mở câu` tắt âm trước cảnh | `adb devices` + 2 máy Android vật lý khác OEM/API level | Chưa chạy (0 thiết bị vật lý đang kết nối ADB; giữ `verifying`) |

## Cổng theo rủi ro

- Báo thức: Unit test logic đạt 9/9 trên máy phát triển; bắt buộc kiểm AD01–AD07 trên ít nhất 2 máy Android thật trước khi chuyển `T032` sang `done`.
