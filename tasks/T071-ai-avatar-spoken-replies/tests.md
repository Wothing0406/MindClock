# Kiểm thử

TC01 ↔ AC01: không tự đọc; click Nghe, Học sâu/solo/auth chặn.
TC02 ↔ AC02: queued không speaking, started đúng id, done/error/stop, callback stale.
TC03 ↔ AC03: init pending/stop/background/scope đổi, dispose không hồi âm.
TC04 ↔ AC04: voice unavailable/throw/timeout; timer và text còn hoạt động.
TC05 ↔ AC05: analyze/build và kiểm thiết bị khả dụng, ghi giới hạn thật.

## Kết quả 20/11/2026 — Windows / Flutter Android

- TC01–04: `flutter test --no-pub test/t071_study_speech_test.dart test/t070_companion_assets_test.dart test/study_room_modes_and_exp_test.dart test/community_friends_and_meet_room_test.dart --reporter expanded`: **18 PASS**. Cầu nối phát là fake trong widget/controller tests, không phải bằng chứng nghe tiếng thật. `flutter-tests.log` lưu lượt cuối.
- `flutter analyze --no-pub`: **No issues found**, sau sửa import integration/test.
- `gradlew :app:compileDebugKotlin --no-daemon --console=plain`: **BUILD SUCCESSFUL**, Android Studio JBR. Cảnh báo AGP/Kotlin legacy có sẵn, chưa migrate trong task này.
- `flutter build apk --debug --no-pub --dart-define=MINDCLOCK_API_BASE_URL=http://10.0.2.2:8000`: **PASS**. APK build từ working tree có cả game WIP không thuộc T071, không coi là APK tái tạo đúng một commit sạch/release.
- `flutter test --no-pub integration_test/study_speech_android_test.dart -d emulator-5554 --reporter expanded`: **2 PASS**, AVD Medium_Phone_API_37.0; native `VERSION` rejection và đường fallback thật. `nativePlaybackStarted=false, explicitFallback=true, eventStates=[error], noMicrophoneUsed=true`. **Không có bằng chứng giọng Việt phát thành công**, không chứng minh lip-sync/độ tự nhiên/độ trễ máy thật. Emulator khởi động với no-audio nên cũng không dùng để chứng nhận nghe loa.
- `python scripts/check_docs_links.py`: PASS 641 Markdown; `python scripts/check_task_records.py`: PASS. Rà diff bỏ blank EOF trong phần T071; WIP khác giữ nguyên.

AC05 còn verifying cho tiếng phát thành công và máy thật. Toàn bộ sản phẩm, Auth backend thật, Live hai chiều, media nhiều người và pet ledger không thuộc bằng chứng trên.
