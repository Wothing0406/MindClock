# Kiểm thử

TC01 ↔ AC01: Auth A/B, session không tồn tại/kết thúc, consent false, input/UUID, retry/quota.
TC02 ↔ AC02: HTTP fixture lỗi/timeout/malformed/base64/WAV, provider thật câu chung không dữ liệu học sinh.
TC03 ↔ AC03: pending không speaking, response muộn sau stop/scope/dispose, Học sâu/solo, consent cancel không network.
TC04 ↔ AC04: lỗi API/giọng vẫn text, phát xong cleanup, foreground-only.
TC05 ↔ AC05: PostgreSQL quota concurrency, Flutter analyze/test, Kotlin compile, Android audio harness và APK.

## Kết quả 21/11/2026 — Windows / API Docker / Android API37

- GET models provider thật status200 có model TTS; `synthesize_reply` thực tạo 270748byte WAV24kHz/mono/PCM16, 5.48giây; không model mock, không dữ liệu học sinh. Prompt/hash trong audio-provenance.json.
- TC01/02: `.venv/Scripts/python -m pytest tests/test_reply_speech.py tests/test_api_v1.py -q`: 27 PASS. Sau thêm ca cap ngày, chạy cùng test PostgreSQL riêng: 9 PASS (8 speech API/service + 1 PostgreSQL). Warnings Starlette anyio alias có sẵn, không lỗi.
- Sau thông báo lỗi thân thiện: test_reply_speech.py cuối9 PASS, thêm ca thiếu key không lộ tên biến cấu hình vào thông báo cho học sinh. Ca test đầu dùng nhầm message_vi thay message của contract lỗi; sửa test theo API hiện hành rồi chạy lại đạt.
- PostgreSQL TC01: database ngẫu nhiên fixture isolated_pg, Alembic head, hai session tranh quota cuối: một200/một429, đúng5 reservation. Đã chạy thật, không skipped; fixture không chạm database app.
- TC03/06: Flutter22 PASS gồm T071/T072/assets/room modes/community, transcript fake chỉ xác minh bản nháp/consent và không auto-send. Analyze sạch; sau icon mic mới testT0724 PASS/analyze sạch. Race cloud trả muộn sau stop/dispose không gọi playWav. Native playback callback mới là speaking.
- TC04: `flutter test --no-pub integration_test/gemini_voice_playback_test.dart -d emulator-5554`: 1 PASS, Google Gemini sample phát qua MediaPlayer, events started→done, avatar trở về nghỉ, directory cache sau phát rỗng. Android audio enabled; đây là kiểm engine/callback, không là kiểm thẩm âm/chất lượng giọng trên máy vật lý. android-playback.log giữ kết quả.
- API Docker đã build/recreate cục bộ (không reset PostgreSQL). HTTP thật tạo user development test tạm, session200 → Gemini help200 → speech200/491548byte/147ký tự; DELETE me trả202 với handler xóa dữ liệu và commit. Không phải Firebase login E2E. Audio đáp án là đề mẫu tự tạo, không dữ liệu cá nhân.
- Kiểm toàn luồng trên màn học Android: `integration_test/gemini_voice_network_test.dart` **1 PASS**, RemoteStudyAiGateway/PersonalApiClient thật→API Docker→Gemini help→user thao tác consent→Gemini TTS→MediaPlayer, UI avatar observed speaking rồi nghỉ, native events started→done. Test dùng dev principal riêng (không Firebase login), user test được xóa trong finally. Không fake audio/text response trong ca này. `android-network.log` lưu kết quả.
- Native nhận giọng: query-activities có GoogleTTSActivity xử lý RecognizerIntent. Chưa cho người nói tiếng Việt vào mic máy thật, không coi service tồn tại hoặc fake transcript là đã kiểm nhận giọng thành công.
- Build APK debug app bình thường đã đạt; API define10.0.2.2:8000 cho emulator. Build chứa WIP game đang có trong working tree, không phải release/commit sạch. Hash bản cuối ở handoff.
- Cài APK cuối adb install -r: Success; mở MainActivity: Status ok/LaunchState COLD. Không dùng startup này làm bằng chứng login/nhận mic thành công.
- Docs links PASS647 Markdown, task records PASS; asset structural check PASS19tiles, T070 raw findings vẫn giữ13, không bị đổi trong voice task.

Lỗi đã sửa: tên pytest parameter bốnMiB sinh node-id quá dài trên Windows; đặt ids ngắn, không giảm ca oversize. Lint builder dùng trùng `_` với SDK hiện tại và if braces đã sửa. Không đổi SDK/framework để bỏ kiểm tra.

Chưa nghiệm thu production: human mic/STT, foreground/background/âm ưu tiên trên máy thật, Firebase login thật, quota/load nhiều user và nội dung/voice phù hợp cohort. Không bật Live/full-duplex/nhóm cam/mic.
