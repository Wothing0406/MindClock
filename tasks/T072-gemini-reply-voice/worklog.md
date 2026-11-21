# Nhật ký

21/11/2026: cấu hình backend has_key=true, mock=false, PostgreSQL; không in key/URL chứa credential. GET models thật status200, có gemini-3.8-flash-tts và flash-lite-tts. T071 vẫn verifying, không gọi fallback là phát tiếng thành công. Chọn voice theo lượt trước để không làm UI giả Live.

User xác nhận Gemini, nói và nghe theo lượt. Thêm RecognizerIntent có consent và bản nháp không tự gửi; không giả thành Gemini Live. Provider sample thật270748byte; HTTP API local hỏi→voice200, tài khoản test xóa202; native sample/cache test1PASS; integration toàn màn học qua RemoteStudyAiGateway thật1PASS, events started→done. Những test này dùng dev principal, không Firebase login. API27PASS + PostgreSQL quota concurrency; Flutter22PASS và lượt cuốiT071/T07212PASS.

Lỗi môi trường build cuối: mergeDebugNativeLibs AccessDenied trong app/build; tương tự ReadOnly cache T071. Giữ verifying, kiểm path cache trước khi gỡ ReadOnly, không đổi source/SDK hay xóa workspace. Lint if/break của integration mới đã xác định, sửa trước analyze cuối. Không dùng APK cũ như chứng cứ build cuối thành công.

Sau sửa: analyze cuối sạch, APK bình thường build PASS32.8s, SHA trong handoff. Test cloud toàn màn học35s PASS, không chỉ phát mẫu dựng sẵn. Native sample/cache23s PASS. Giữ verifying cho lời nói mic người thật/điện thoại và Firebase E2E, không cho kết quả dev Auth thay cổng đó.
