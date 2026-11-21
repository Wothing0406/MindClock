# Kế hoạch kiểm thử T075

| ID | AC | Kịch bản | Mong đợi | Tầng | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | chọn primary, chọn lại, cross-user | chỉ một primary hợp lệ | API SQLite | Đạt — 21/11/2026, 5 test API cùng T074 |
| TC-02 | AC-02 | hub empty/loading/error | card không dựng số | Flutter widget | Đạt — empty + server card |
| TC-03 | AC-02/03 | group active, đổi primary | dashboard/repository phản ánh đúng | Flutter/API | Đạt — contract + endpoint; concurrency ở TC-08 |
| TC-04 | AC-05 | 320dp, text 200%, Reduce Motion | không overflow | Flutter widget | Đạt — 8/8 T074+T075 |
| TC-05 | AC-04 | render share card | PNG 1080, không lộ private | Widget + emulator export | Đạt — `t075_exported_share_1080.png`, ffprobe 1080×1080 |
| TC-06 | AC-04 | mở Android share sheet | typed image intent, không crash | Emulator API 37 | Đạt — `t075_android_share_sheet.png` |
| TC-07 | AC-04 | file URI/TTL | cache riêng + FileProvider | Build/review/emulator | Đạt — APK debug build; file cache 149822 byte |
| TC-08 | AC-01 | hai select đồng thời PG | một primary cuối cùng | PostgreSQL disposable | Đạt — 1 test; toàn backend 6/6 |
| TC-09 | AC-06 | build/install/walkthrough | PNG + MP4 emulator font thật | emulator-5554 API 37 | Đạt — 3 PNG + MP4 H.264 720×1600, 7.34 giây |

## Lệnh và kết quả

- `flutter test --no-pub -j 1 test/t074_commitment_group_pet_test.dart test/t075_today_pet_share_test.dart` → 8/8 đạt.
- `flutter analyze --no-pub` → `No issues found`.
- `pytest ...test_primary_commitment_pet...` với PostgreSQL disposable → 6/6 đạt.
- `flutter build apk --debug --no-pub` → thành công.
- Chưa thay thế cổng Android thật trước release; bằng chứng này chỉ là emulator.
