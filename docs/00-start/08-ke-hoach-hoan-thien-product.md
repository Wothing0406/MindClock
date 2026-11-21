# Kế hoạch hoàn thiện MindClock thành product

**Mốc kiểm chứng:** 21/11/2026. Tài liệu này là ma trận thực thi, không phải tuyên bố phát hành. Một hàng chỉ được chuyển sang `đạt pilot` khi có bằng chứng đúng cột cổng; tên màn hình, mock, ảnh hoặc test đơn vị không thay cổng máy thật/nhiều tài khoản.

## Hiện trạng theo lát sản phẩm

| Lát | Có thể dùng trong dev | Chưa phải product hoàn chỉnh | Task/cổng kế tiếp |
| --- | --- | --- | --- |
| Auth/onboarding | Email/password UI, profile lớp/môn/avatar, plan xác nhận, API user/consent | Chưa E2E Firebase A/B trên máy thật, quên mật khẩu/xác minh email/staging | T084; 2 tài khoản Firebase, xóa account và dữ liệu thật |
| Alarm/ngủ | Alarm Android local, emergency stop, challenge/normal, TKB chọn môn | Chưa đủ ma trận kill/reboot/Doze/màn khóa/quyền trên 2 máy thật | T084; AD/SLEEP trên thiết bị vật lý |
| Todo/lịch nhắc | Todo/timeline local, widget và receiver Android có mã/test | Chưa có nguồn server đa thiết bị, lịch hẹn nhóm, quiet-hours/idempotency/Doze máy thật | T074 |
| Học một mình | Timer đếm ngược/đếm tiến, deep/interval, pause/finish/recap, EXP server | Chưa E2E resume/notification/EXP đa thiết bị trên staging | T074, T080, T084 |
| Học cùng AI | Text Socratic, Gemini TTS theo lượt, nhận giọng Android thành bản nháp, avatar trạng thái | Chưa kiểm mic tiếng Việt máy thật; không full-duplex/camera live; deep mode vẫn phải im lặng | T076/T077/T084 |
| Bạn bè/phòng REST | Tìm/kết bạn, public/invite-code, capacity 2–8, settings, polling; T073 thêm kick/xóa/cascade | Không có signaling/media/chat/QR TTL/waitlist/lịch hẹn/presence socket; mic/cam hiện không truyền dữ liệu | T075–T078 |
| Pet nhóm | Art pet Mầm 4 stage + reaction tĩnh | T074 đang làm membership/ledger/EXP; chưa có dashboard/share/moderation đã kiểm | T074–T075 |
| PvP/game | G1 luyện đơn và asset game đang WIP/verifying | Chưa chứng minh G2 hai máy, networking event/FX/audio/reconnect; chưa ranked/cân bằng/quyền release | T081–T083 |
| Vận hành | Docker local, PostgreSQL migration/test, APK debug nội bộ | Chưa staging production-like, monitoring, backup drill, privacy/release signing/pilot | T084 |

## Thứ tự task bắt buộc

### T073 — Vòng đời phòng REST

Host kick, chặn tự vào lại, xóa phòng/cascade member, client clear state, UI xác nhận. Không bật media giả. Đây là điều kiện trước invite/media.

### T074 — Nền nhóm cam kết và pet

Nhóm kín tối đa 4 người; một user tối đa 3 nhóm; owner mời/duyệt/kick/delete. Ledger server nhận phiên học đủ 5 phút và thử thách sáng đúng, phát care/EXP cho từng group active, chống trùng theo source/group. Pet là phép chiếu từ ledger. Không chứa share, chat hay media.

### T075 — Pet trên dashboard và chia sẻ

Thẻ pet/chuỗi/EXP trên màn Hôm nay; chọn pet chính. Share card 1080 opt-in không lộ tên/lịch/giờ dậy thành viên; Android share sheet, provenance, Reduce Motion và dọn file tạm.

### T076 — Lời mời phòng, QR, phòng chờ và lịch hẹn

Invite token ngẫu nhiên có TTL/số lượt/thu hồi; QR chỉ chứa HTTPS link; phòng `invite_only` có request/waitlist/approve/reject. Rate-limit, block/report, host kick/unban và log moderation tối thiểu có retention. Không dùng room code vĩnh viễn làm link public.

### T077 — Chat phòng và `@MindClock`

Chat người thật có phân trang/retention/report; ảnh có preview và xóa; chỉ nội dung được tag `@MindClock` mới gửi AI. Câu AI lưu text; voice là bản dựng lại theo consent/quota, không giả là lời người thật. Người ngoài/phòng đã xóa không đọc được.

### T078 — Audio realtime 1v1

Chọn media provider/signaling; token ngắn hạn từ backend, object authorization, mic tắt mặc định. Nút mic, loa, audio route thật; reconnect/background/audio focus/permission từ chối. Cổng: hai điện thoại Android/tài khoản khác nhau nghe được nhau, tắt mic/loa có tác dụng, không ghi âm mặc định.

### T079 — Camera/lưới 2–4 người

Camera opt-in, preview trước join, đổi camera, adaptive bitrate, participant presence, reconnect và Reduce Motion. Cổng 2–4 máy; mất mạng/một người rời/host xóa không làm timer local mất dữ liệu.

### T080 — Lịch cá nhân, todo và nhắc đúng giờ

Event/task server có owner, timezone, recurrence/exception, version/idempotency; Android lập lịch local từ bản xác nhận. Test quiet hours, timezone, reboot/Doze và hai máy; khóa màn hình ẩn môn mặc định.

### T081 — Phiên học nhóm đồng bộ

Room schedule/start/pause/end, goal riêng/goal chung, deep/interval, timer theo server epoch nhưng vẫn chạy local khi mất mạng; recap và EXP ledger không cộng trùng. Hẹn bạn học tạo local notification sau xác nhận, cho từ chối/đổi giờ/múi giờ.

### T082 — Pilot nền tài khoản/alarm/phòng

Firebase A/B, staging PostgreSQL, secrets, backup/restore, account delete, thiết bị Android mục tiêu và kiểm Doze. Media chỉ bật feature flag khi cổng hai máy đạt.

### T083–T085 — Game thật

- T083 G2 giao hữu 1v1: queue, loading, select tướng, question/action window, authoritative events, FX/audio/HP, reconnect/appeal trên hai máy.
- T084 G3 2v2: party/invite, bốn submission/action, target, team resolve, bốn máy và AFK/uncertain.
- T085 ranked: chỉ mở khi ngân hàng/rubric/eval/cân bằng/anti-farm/quyền asset đạt; không bán sức mạnh.

### T086 — Pilot Android cuối

Firebase thật A/B, staging PostgreSQL, backup/restore, secrets, monitoring, account export/delete, thiết bị Android mục tiêu, release signing và checklist rollback. iOS vẫn là nhánh sau Android.

## Definition of Product Ready

Chỉ gọi MindClock `pilot-ready` khi happy path đăng ký → onboarding → lịch/alarm → câu sáng → phiên học → recap/EXP chạy trên máy Android thật; dữ liệu A/B cô lập; alarm/emergency stop không phụ thuộc API; notification đúng giờ qua reboot/Doze; phòng chỉ quảng bá media sau test hai máy; xóa account/room xóa đúng dữ liệu; không còn route `/demo`/`/product` trong build phát hành; game/ranked bị feature flag nếu chưa qua cổng.
