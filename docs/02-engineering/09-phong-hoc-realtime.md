# Kiến trúc phòng học realtime và avatar AI

**Trạng thái:** mục tiêu P2, chưa có room networking/video call production. [Hành vi](../01-product/08-phong-hoc-ai-va-ban-be.md); [AI policy](06-ai-va-cham-bai.md). Không coi endpoint `/study/live-token` hiện có là phòng Meet đã hoạt động.

## Tách ba dịch vụ

1. **Phiên học local:** Dart domain giữ timer/việc/nhịp, tồn tại khi API/Live rớt; server chỉ đồng bộ summary idempotent.
2. **AI voice:** backend xác thực user/consent/quota, cấp ephemeral Live token giới hạn session; client kết nối tới provider hoặc qua gateway theo kiến trúc đã kiểm. Backend giữ rate/usage/feature flag; không đưa server Gemini key vào APK. Bắt đầu bằng push-to-talk STT/text/TTS theo lượt trước khi làm full duplex.
3. **Phòng bạn:** signaling/Auth/room membership server; media WebRTC/SFU hoặc dịch vụ tương đương được chọn theo chi phí; không dùng Gemini Live như kênh truyền hình hai người. Hai user có quyền tắt mic/cam riêng. Room socket event có sequence/room version để reconnect; session timer không dựa vào socket làm nguồn duy nhất.

## Máy trạng thái

`created → waiting_invite → joining → active → reconnecting | paused → ended`; token/membership hết hạn → `left`, không tự join lại tài khoản khác. Server kiểm invite TTL, capacity, blocked users, owner, idempotency và giới hạn tạo phòng. Client dùng local timer cả khi `reconnecting`. Khi media không sẵn có, hiển thị `Chỉ âm thanh` hoặc `Chỉ chữ`, không render hình người/AI giả đang tham gia.

**QR/deep link:** backend tạo invite token opaque đủ entropy, lưu hash/token metadata (`room_id`, inviter/đích nếu có, expiry, max uses, revoked, room version); link HTTPS mở app qua Android App Link hoặc web fallback chỉ giải thích cách cài/mở app, không là web client phòng học. QR là biểu diễn của link, không lưu ảnh QR trên server. Khi redeem, xác minh Auth/tuổi/consent/block/capacity/expiry/revocation trong transaction; token không tự là quyền vào media. Tạo request hoặc membership rồi mới cấp room/media token ngắn hạn, scope đúng người/phòng. Rate limit quét/redeem, không log token thô; cùng `clientRequestId` trả cùng kết quả. Xóa/thu hồi link ngăn join mới, không tự đuổi người đã được chấp nhận nếu chưa có hành động kick riêng.

## Camera/voice và quyền dữ liệu

Mic/cam chỉ sau thao tác user và quyền OS, indicator trong app, stop ngay khi tắt hoặc rời phòng. Không lưu video/audio mặc định; frame gửi AI chỉ khi user bấm `Hỏi về trang này`, review frame trước gửi, xử lý tạm và xóa. Không dùng camera để chấm lơ là, đọc biểu cảm hoặc phát hiện điện thoại thứ hai. Nếu dùng transcription để người học xem lại, phải có consent, TTL và xóa riêng; không mặc định bật. Với người chưa thành niên, mở Live và phòng bạn sau review độ tuổi/quyền/nhà cung cấp, không bằng một flag client.

## Avatar AI

T070 tạo art mentor gốc 2D và nền góc học; 9 biểu cảm UI nằm tại [asset companions](../../assets/companions/README.md). Flutter chọn frame theo neutral/listening/thinking/encouraging/focused; blink dùng ảnh nhắm mắt riêng. Mouth frame chỉ chạy khi caller cung cấp isSpeaking từ audio đang phát; có audioLevel thì đổi độ mở miệng theo mức âm, chưa là lip sync theo âm vị. Text chat không tự phát tiếng; T072 cấp speaking từ playback sau thao tác Nghe, không suy từ việc đã có tin nhắn. Reduce Motion/animate=false/TickerMode tắt đều giữ ảnh tĩnh. Chưa có Live media từ việc thêm avatar.

Avatar là nhân vật 2D gốc, nhãn `MindClock AI`, animation `idle/listening/speaking/thinking` theo **trạng thái kết nối và audio thật**; không giả đang nhìn user. Miệng theo âm lượng nếu chưa có viseme; không tạo ảnh mặt người thật từ video học sinh. Giới hạn frame/memory, fallback ảnh tĩnh khi Reduce Motion/pin yếu. SFX/nhạc phòng tách âm báo thức. Không cho avatar nói khi mic/cam tắt mà UI không giải thích nguồn phản hồi.

Asset rig 2D tối thiểu có lớp đầu/thân, mắt/chớp, chân mày và các hình miệng; timeline của miệng lấy từ clock phát audio (viseme nếu pipeline trả được, nếu không dùng biên độ đã làm mượt), dừng khi audio pause/stop/buffer. Các trạng thái `idle|thinking|speaking|error` do event thật điều khiển; không chạy vòng miệng giả trong lúc model chờ. Khi mất frame budget, giảm chuyển động rồi chuyển ảnh tĩnh, không làm timer/chat giật. Ở `deep`, phản hồi AI chữ và avatar không phát cử động nói cho đến khi người dùng tự bấm `Nghe`.

## Chat người thật, ảnh hỏi AI và voice trả lời

Backend tách `group_message` khỏi `ai_turn`: AI không subscribe toàn bộ room event/chat. `POST` hỏi AI nhận `selected_message_ids`/text/ảnh **do người gửi chọn**, kiểm owner/membership/quyền xem từng message và consent AI của mọi người nếu dùng trong nhóm; không gửi ảnh của người khác sang AI chỉ vì có trong phòng. Ảnh chọn/chụp → preview/crop/che → xác nhận đích `nhóm|AI` → upload tạm; kiểm MIME/magic bytes/size/EXIF, quét nội dung nhạy cảm theo policy rồi xử lý, xóa khi xong/lỗi/timeout. Chat P2 đầu không lưu lịch sử sau phiên mặc định; server chỉ giữ state tối thiểu để đồng bộ trong phiên, TTL, audit moderation tách nội dung. Sau phiên, user có thể mở `Hỏi AI` từ recap và tự chọn ảnh mới/ghi chú được phép dùng, không mặc định chuyển chat nhóm cũ.

AI trả text trước; voice là artifact/stream riêng với `voiceRequested` và consent. Ở `deep`, không autoplay, chỉ phát sau nút `Nghe`; ở nhịp thảo luận có thể bật autoplay sau lựa chọn riêng. Lỗi TTS/Live không xóa text; tắt/rời phòng hủy audio và trạng thái avatar. Reconnect có message ID/sequence để không hiển thị hoặc phát lại câu trả lời hai lần. Không lưu audio/transcript mặc định; nếu cần lịch sử sau này, chốt retention, export/delete và quyền mọi thành viên trước code.

## Chi phí và vận hành

Mỗi session có max phút/turn/token theo môi trường, budget/ngày và kill switch server; UI báo `Còn X phút AI` theo quota thật, không hứa miễn phí vô hạn. Live API tài liệu hiện hành nêu giới hạn kết nối/phiên và cần quản lý nối lại, vì vậy task phải kiểm model/quota/SDK/giá lúc code. Telemetry chỉ duration, status, bytes/token ước tính, lỗi; không log âm thanh/bản chép/lời giải. Kiểm mạng yếu, reconnect, tai nghe/Bluetooth, app background, cuộc gọi đến, hai thiết bị, tài khoản đổi, xóa dữ liệu. [Nguồn Live](https://ai.google.dev/gemini-api/docs/live-api/session-management), [ephemeral token](https://ai.google.dev/gemini-api/docs/live-api/ephemeral-tokens), [giá](https://ai.google.dev/gemini-api/docs/pricing/).

## Contract đề xuất, chưa triển khai

`POST /v1/study/rooms` tạo private room; `POST /rooms/{id}/invites`, `POST /rooms/{id}/join`, `POST /rooms/{id}/leave`, `GET /rooms/{id}/snapshot`, WebSocket `/rooms/{id}/events` cho membership/state. `POST /v1/study/live-token` chỉ nếu consent/quota và scope session/voice đúng. Các payload cần `clientRequestId`, `roomVersion`, auth subject, hạn TTL; 401/403/404/409/429 có ý nghĩa, không lộ existence phòng người khác. Migration/contract test/anti-abuse và delete/export trước khi mở route. [API hiện hành](04-hop-dong-api.md).

Task triển khai cần thêm contract riêng cho `POST /rooms/{id}/invites` trả link/expiry/uses nhưng không trả hash token; `POST /invites/redeem`, `POST /rooms/{id}/messages`, `POST /rooms/{id}/ai-turns`, upload ảnh tạm và `POST /ai-turns/{id}/voice` nếu voice theo lượt. QR tạo ở client từ link đã nhận. Group AI membership/consent là state server, không chỉ nút UI. Route/payload này **chưa có trong API** và phải có migration, OpenAPI, test A/B/TTL trước khi client gọi.
## T071 — Đọc câu trả lời theo thao tác trên Android

Phòng AI nhịp ngắt quãng có nút `Nghe câu trả lời` dưới lượt assistant an toàn và `Dừng giọng đọc`. Không tự đọc khi backend trả text, không xin mic/cam. Chỉ đọc khi đã đăng nhập và phiên đang running; solo/Học sâu không có nút phát. Giọng này là **TTS của thiết bị**, không phải Gemini Live hoặc hội thoại full-duplex.

Bridge `mindclock/study_speech` version 1: `speak {id,text}` (tối đa 2000 ký tự), `stop`; callback `speechState {id,state:started|done|stopped|error,messageVi?}`. Android khởi tạo lười, chọn voice tiếng Việt không cần mạng và đã cài, khai báo query TTS_SERVICE; thiếu voice trả lỗi và giữ text/timer. Không tự tải voice, không ghi file/log text. Theo [Android TextToSpeech](https://developer.android.com/reference/android/speech/tts/TextToSpeech) và [UtteranceProgressListener](https://developer.android.com/reference/android/speech/tts/UtteranceProgressListener).

Controller bỏ callback không khớp utterance hiện hành; queued chưa là speaking. Init quá 15 giây hoặc playback thiếu terminal quá 3 phút thì stop. Khi dừng/đổi scope, vô hiệu id trước await để không có giọng muộn. Native hủy pending init khi stop, dừng onPause/audio focus loss, shutdown khi destroy. Không tự phát tiếp khi resume. Flutter dừng thêm khi màn bị dispose/đổi account/phiên/không còn quyền đọc; Reduce Motion chỉ làm tĩnh hình, không đổi quyết định nghe chủ động. Frame miệng dùng cadence UI trong khoảng engine callback started–terminal, không đo âm lượng hay lip-sync âm vị và không chứng minh loa có tiếng nếu hệ thống đang mute.

Pet Mầm vẫn chỉ là bộ art T070, chưa có nhóm/ledger/tiến hóa trên server; chức năng TTS này không cấp pet level/EXP. Cổng máy thật, voice availability, audio focus và end-to-end backend thật phải kiểm riêng, xem task T071.

## T072 — Giọng Gemini và nhập câu hỏi theo lượt

Client thật `RemoteStudyAiGateway` hỗ trợ nguồn WAV qua backend. Nút `Nghe giọng AI` hỏi consent mỗi lần: gửi đúng text câu trả lời đã chọn tới Google; không mic/cam. Không tự chuyển từ offline TTS sang cloud sau lỗi. Giọng tạo theo [Gemini TTS REST interactions](https://aistudio.google.com/docs/speech-generation), mặc định `gemini-3.8-flash-tts`/`Kore`, cấu hình chỉ ở backend. Đã kiểm model hiện hữu và tạo WAV thật, không dùng file mẫu làm câu trả lời fallback.

Native bridge thêm `playWav {bridgeVersion:1,id,wav:Uint8List}`. MediaPlayer chuẩn bị bất đồng bộ, lấy audio focus rồi start, callback started/done/error mới điều khiển avatar. WAV riêng trong cache/mindclock_speech, xóa khi stop/done/error/dispose và quét file riêng lúc bridge khởi tạo; không URI chia sẻ/album. Response cloud trễ sau stop/dispose/scope đổi bị bỏ, không tự phát khi quay lại. Client HTTP voice timeout50s, controller chờ65s; backend provider45s, không thay timeout các route khác.

`Nói câu hỏi` dùng Android [RecognizerIntent](https://developer.android.com/reference/android/speech/RecognizerIntent) vi-VN, sau dialog giải thích dịch vụ thiết bị có thể dùng mạng/mic. Mic do activity hệ thống quản lý; app không thêm RECORD_AUDIO hoặc giữ recording. Trả về tối đa600 ký tự chỉ điền ô nháp, không gửi AI; user xem/sửa rồi bấm Gửi. Hủy/không có service vẫn nhập chữ. Không gắn nhãn AI đang nghe khi app nhường sang activity nhận giọng nói, không gọi đây là Live. Camera luôn độc lập. Học sâu/solo không có nút nói/nghe.

Test T072 phân biệt: provider thật + HTTP local thật qua tài khoản development test; Android phát sample Gemini gốc và dọn cache thật; widget test consent/STT chỉ là fake transcript. Chưa có kiểm nhận tiếng Việt từ mic trên máy vật lý, Firebase E2E hoặc hội thoại full-duplex.
