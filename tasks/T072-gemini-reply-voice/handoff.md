# Bàn giao

Trạng thái **verifying** cho kiểm mic trên máy thật. Luồng giọng Gemini đã chạy thật, không còn chỉ fallback offline TTS.

Đã đổi: API speech Auth/owner/consent/nonce/quota, validate WAV và no-store; Gemini interactions model3.8-flash-tts/Kore, source/cloud gateway/timeout riêng, native MediaPlayer/cache cleanup/focus/lifecycle, callback avatar; dialog nghe và nút nhập nói→nháp→gửi chủ động. Nhận giọng qua RecognizerIntent của thiết bị (có thể online), không quảng cáo Gemini đang nghe mic trực tiếp. Không mở mic/cam nền, không auto-send/auto-play, Học sâu/solo không có nút nói/nghe. Có icon mic vector.

Bằng chứng 21/11/2026: provider thật tạo WAV; API Docker local đã rebuild/recreate, HTTP help→voice thật200 và cleanup user test; Flutter22 PASS/analyze sạch; 27 API tests và PostgreSQL quota tranh slot riêng đạt; native sample started→done/cache rỗng; integration mạng toàn màn học RemoteStudyAiGateway→Gemini→audio/avatar **1 PASS**, dev principal test riêng được xóa. Tests.md phân biệt tất cả harness/dev Auth với Firebase E2E/máy thật. Không dùng sample generic làm fallback câu trả lời.

Còn cần kiểm: nói tiếng Việt thật với mic/dịch vụ nhận giọng trên Android vật lý, tắt/đổi app/audio focus/camera riêng trên máy thật; cohort/privacy/provider review trước phát hành. Chưa là Live/full-duplex hoặc pet online. Giọng offline T071 vẫn chưa có positive test riêng; cloud T072 không chứng minh offline engine hoạt động.

Điểm tiếp chính xác: cài dist/mindclock-voice-debug.apk cho emulator API10.0.2.2:8000, đăng nhập→học cùng AI→ngắt quãng→bắt đầu→Nói câu hỏi→cho phép dịch vụ hệ thống/xem lại bản chữ→Gửi→Nghe giọng AI→consent; kiểm hủy/rời màn/Học sâu. APK cho máy thật cần build với URL backend truy cập được, không dùng10.0.2.2. Không gọi app phát hành hoàn thành.

Git sẽ ghi SHA sau push. Chỉ stage file voice; giữ WIP game/web/Firebase ngoài commit. Task T071 metadata đã push riêng ở135212c.

APK cuối app bình thường (không entrypoint test): dist/mindclock-voice-debug.apk, 208575556bytes, SHA256 `d40d82e7bccd9cb26b84552f93bbca124b80087ac792cbf5f55d7a6edcabe4c5`. Analyze cuối No issues found; build cuối PASS sau gỡ ReadOnly cache. API Docker đã recreate bản cuối, giữ nguyên PostgreSQL. APK chứa game WIP hiện có, không là bản release từ checkout sạch. Không commit APK hoặc file .env/google-services.
