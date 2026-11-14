# Kế hoạch và kết quả kiểm thử T020

| ID | Liên kết AC | Kịch bản kiểm thử | Kết quả dự kiến | Kết quả thực |
| --- | --- | --- | --- | --- |
| `SND-TC-01` | `SND-AC-01` | Kiểm tra `AlarmSoundOption.fromId('bermuda_alarm')`, `AlarmConfig.toJson`/`fromJson`, và `AlarmConfigScreen` chip `sound-bermuda_alarm` | Giữ nguyên `'Nhạc chuông Bermuda'` sau lưu và khôi phục | `blocked` (đã thêm vào `app/test/domain_and_persistence_test.dart`; chưa chạy `flutter test` do thiếu Flutter SDK trên máy) |
| `SND-TC-02` | `SND-AC-02` | Unit test Kotlin `AlarmSoundResolverTest`: kiểm tra `resolveSoundTarget(soundEnabled, soundOption)` cho `bermuda_alarm`, `gentle_dawn`, `clear_bell`, `vibrate_only` | Đúng target `BUNDLED_BERMUDA`/`SYSTEM_DEFAULT`/`SILENT` | `blocked` (đã viết `AlarmSoundResolverTest.kt`; chưa chạy `./gradlew test` do thiếu Gradle/Android SDK trên máy) |
| `SND-TC-03` | `SND-AC-03` | Kiểm tra trực tiếp file MP3 trong `app/android/app/src/main/res/raw/alarm_bermuda.mp3`, `check_docs_links.py`, `check_task_records.py`, `git diff --check` | Asset hợp lệ (`313,344` bytes), task records & diff clean | Đạt kiểm tra file & `check_docs_links.py` / `check_task_records.py` / `git diff --check`; phát loa thực tế trên Android chưa chạy |
