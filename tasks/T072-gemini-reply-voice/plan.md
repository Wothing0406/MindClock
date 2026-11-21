# Kế hoạch

- [x] Xác định offline voice hiện chưa chạy; kiểm model backend không lộ key.
- [x] API TTS có quota reservation/Auth/owner/consent và kiểm WAV.
- [x] Gateway cloud + native audio + consent UI và callback avatar.
- [x] Theo lựa chọn user: nói→nháp chữ→xác nhận gửi, qua RecognizerIntent, không tự gửi/mở mic liên tục.
- [x] Test API/Flutter/native, provider sample thật và toàn luồng mạng Android; APK app cuối build PASS, hash trong handoff.
- [ ] Test nghe/nhận tiếng Việt bằng mic trên điện thoại vật lý, Firebase E2E và audio focus thực.
- [x] Docs/handoff, rà secret/WIP, commit/push/xác minh main33bb685; giữ verifying cho các cổng máy thật ở trên.
