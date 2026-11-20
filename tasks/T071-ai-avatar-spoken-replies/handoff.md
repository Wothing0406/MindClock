# Bàn giao

Trạng thái **verifying**. Có mã TTS native + Flutter controls/state và build, chưa có bằng chứng tiếng Việt phát thành công.

Đã đổi: `StudySpeechBridgeHandler.kt`, MainActivity/Manifest query; domain gateway, MethodChannel gateway, StudySpeechViewModel; nút nghe/dừng theo lượt AI an toàn trong StudySpaceScreen và callback avatar. Không tự đọc, không mic/cam. Native onPause/focus loss/destroy stop; Flutter scope/foreground/session/dispose chặn callback cũ; Học sâu/solo giữ im lặng. Không biến text history thành speaking.

Kiểm: 18 Flutter tests PASS, analyze sạch, Kotlin compile/APK build PASS, 2 native integration tests PASS trên emulator-5554 API37 (đường fallback và version). Native playbackStarted=false, explicitFallback=true: chưa xác nhận nghe tiếng/voice thực. Không có máy thật, Live hay pet ledger/tiến hóa. Chi tiết/log ở tests.md; không lưu user text/token trong log.

Điểm tiếp: kiểm với giọng tiếng Việt offline được cài qua cài đặt hệ thống theo lựa chọn user, chạy lại integration với emulator có audio hoặc Android thật, kiểm started→done, dừng/background/focus loss/thiếu voice. Không tự tải voice hoặc dùng voice online thay lựa chọn offline. Sau đó mới chốt AC05. Pet cần task riêng cho nhóm chính, ledger ngày/cap/idempotency/PostgreSQL và UI tiến hóa; không tăng cấp từ ảnh/local EXP. Auth/AI backend thật và media production còn cổng riêng.

Giữ riêng WIP game/config Firebase, không stage cùng task. Git sẽ ghi SHA sau khi push và xác minh.

APK app bình thường (không phải entrypoint integration): `dist/mindclock-t071-debug.apk`, 208575440 bytes, SHA256 `8e3abadc215d6b6c15774fc33469fd25e4e9ba3f1dca070a7ad355086dc1b851`, API emulator `http://10.0.2.2:8000`. APK gồm WIP game hiện có trong working tree, không là release/commit sạch. Không đưa APK/config Firebase vào Git.
