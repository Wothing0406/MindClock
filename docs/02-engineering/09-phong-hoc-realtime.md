# Kiến trúc phòng học realtime và avatar AI

**Trạng thái:** mục tiêu P2, chưa có room networking/video call production. [Hành vi](../01-product/08-phong-hoc-ai-va-ban-be.md); [AI policy](06-ai-va-cham-bai.md). Không coi endpoint `/study/live-token` hiện có là phòng Meet đã hoạt động.

## Tách ba dịch vụ

1. **Phiên học local:** Dart domain giữ timer/việc/nhịp, tồn tại khi API/Live rớt; server chỉ đồng bộ summary idempotent.
2. **AI voice:** backend xác thực user/consent/quota, cấp ephemeral Live token giới hạn session; client kết nối tới provider hoặc qua gateway theo kiến trúc đã kiểm. Backend giữ rate/usage/feature flag; không đưa server Gemini key vào APK. Bắt đầu bằng push-to-talk STT/text/TTS theo lượt trước khi làm full duplex.
3. **Phòng bạn:** signaling/Auth/room membership server; media WebRTC/SFU hoặc dịch vụ tương đương được chọn theo chi phí; không dùng Gemini Live như kênh truyền hình hai người. Hai user có quyền tắt mic/cam riêng. Room socket event có sequence/room version để reconnect; session timer không dựa vào socket làm nguồn duy nhất.

## Máy trạng thái

`created → waiting_invite → joining → active → reconnecting | paused → ended`; token/membership hết hạn → `left`, không tự join lại tài khoản khác. Server kiểm invite TTL, capacity, blocked users, owner, idempotency và giới hạn tạo phòng. Client dùng local timer cả khi `reconnecting`. Khi media không sẵn có, hiển thị `Chỉ âm thanh` hoặc `Chỉ chữ`, không render hình người/AI giả đang tham gia.

## Camera/voice và quyền dữ liệu

Mic/cam chỉ sau thao tác user và quyền OS, indicator trong app, stop ngay khi tắt hoặc rời phòng. Không lưu video/audio mặc định; frame gửi AI chỉ khi user bấm `Hỏi về trang này`, review frame trước gửi, xử lý tạm và xóa. Không dùng camera để chấm lơ là, đọc biểu cảm hoặc phát hiện điện thoại thứ hai. Nếu dùng transcription để người học xem lại, phải có consent, TTL và xóa riêng; không mặc định bật. Với người chưa thành niên, mở Live và phòng bạn sau review độ tuổi/quyền/nhà cung cấp, không bằng một flag client.

## Avatar AI

Avatar là nhân vật 2D gốc, nhãn `MindClock AI`, animation `idle/listening/speaking/thinking` theo **trạng thái kết nối và audio thật**; không giả đang nhìn user. Miệng theo âm lượng nếu chưa có viseme; không tạo ảnh mặt người thật từ video học sinh. Giới hạn frame/memory, fallback ảnh tĩnh khi Reduce Motion/pin yếu. SFX/nhạc phòng tách âm báo thức. Không cho avatar nói khi mic/cam tắt mà UI không giải thích nguồn phản hồi.

## Chi phí và vận hành

Mỗi session có max phút/turn/token theo môi trường, budget/ngày và kill switch server; UI báo `Còn X phút AI` theo quota thật, không hứa miễn phí vô hạn. Live API tài liệu hiện hành nêu giới hạn kết nối/phiên và cần quản lý nối lại, vì vậy task phải kiểm model/quota/SDK/giá lúc code. Telemetry chỉ duration, status, bytes/token ước tính, lỗi; không log âm thanh/bản chép/lời giải. Kiểm mạng yếu, reconnect, tai nghe/Bluetooth, app background, cuộc gọi đến, hai thiết bị, tài khoản đổi, xóa dữ liệu. [Nguồn Live](https://ai.google.dev/gemini-api/docs/live-api/session-management), [ephemeral token](https://ai.google.dev/gemini-api/docs/live-api/ephemeral-tokens), [giá](https://ai.google.dev/gemini-api/docs/pricing/).

## Contract đề xuất, chưa triển khai

`POST /v1/study/rooms` tạo private room; `POST /rooms/{id}/invites`, `POST /rooms/{id}/join`, `POST /rooms/{id}/leave`, `GET /rooms/{id}/snapshot`, WebSocket `/rooms/{id}/events` cho membership/state. `POST /v1/study/live-token` chỉ nếu consent/quota và scope session/voice đúng. Các payload cần `clientRequestId`, `roomVersion`, auth subject, hạn TTL; 401/403/404/409/429 có ý nghĩa, không lộ existence phòng người khác. Migration/contract test/anti-abuse và delete/export trước khi mở route. [API hiện hành](04-hop-dong-api.md).
