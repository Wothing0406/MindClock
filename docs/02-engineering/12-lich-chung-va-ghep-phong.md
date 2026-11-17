# MultiCal, ghép phòng học và điểm pet nhóm

**Trạng thái:** contract thiết kế P2, chưa có API/SQL migration hay media production. [Hành vi](../01-product/12-lich-chung-ghep-phong-va-pet-nhom.md), [phòng realtime](09-phong-hoc-realtime.md), [SQL](03-du-lieu-sql.md), [API](04-hop-dong-api.md). Flutter Android + FastAPI/PostgreSQL là stack hiện hành. Media có thể dùng SFU/WebRTC sau phép đo hai máy; LiveKit có Flutter SDK và token quyền theo phòng, song **chưa chọn nhà cung cấp**. [Tài liệu LiveKit transport](https://docs.livekit.io/transport/), [token grants](https://docs.livekit.io/frontends/reference/tokens-grants/).

## 1. Miền dữ liệu và quyền sở hữu

| Entity đề xuất | Trường cốt lõi | Bất biến |
| --- | --- | --- |
| `availability_preferences` | owner, timezone IANA, weekday/window, valid_from/to, source, revision | Chỉ owner đọc/đổi; không trả nguyên lịch cho nhóm. |
| `study_groups`/`group_memberships` | group id, owner, role, status, pet id, policy version | Chỉ thành viên đã xác nhận; block cắt quyền. |
| `group_proposals`/`votes` | 3 khung UTC + timezone gốc, duration, expiry, mỗi member 1 vote/slot | Không đặt lịch khi chưa đủ xác nhận; revision để chống vote trên bản cũ. |
| `study_rooms`/`room_memberships` | visibility, subject/curriculum nếu cùng môn, cadence, capacity, state/version | Server chốt membership/capacity; invite TTL; room token ngắn hạn. |
| `match_requests` | mode, hard filters, soft preferences, expiry, state | Không lưu vị trí/trường/lịch riêng; retry idempotent. |
| `group_pet_ledger` | group, source kind/id (`morning_care|study_care`), contributor, local date, delta, rule version | Unique theo source/reason; cap/ngày; chỉ server ghi, không ảnh hưởng PvP. |
| `on_time_morning_days` | owner, local date, challenge schedule/revision, alarm occurrence, attempt, state, policy version | Riêng với chuỗi đúng giờ; unique theo owner/ngày/occurrence, không suy từ giờ máy đơn lẻ. |
| `group_care_days` | group, local date, contributors count, state, rule version | Một ngày chăm nhóm; lỗi hệ thống có grace không cộng điểm. |

Schema này **chưa tồn tại**. Mỗi lát triển khai cần migration PostgreSQL, index theo truy vấn, unique/FK, rollback và retention; không tạo đồng loạt bảng trống. Lịch cá nhân `timetable_slots` vẫn private. API free/busy nội bộ chỉ trả khoảng đủ điều kiện/số người rảnh cho proposal, không trả nguyên nhân bận, giờ ngủ, giờ báo, lớp/trường cụ thể hay `userId` của người chưa vào phòng. UTC cho so khớp; ngày tính điểm theo timezone đã lưu, xử lý đổi timezone và DST có test.

## 2. Thuật toán chọn giờ và ghép phòng

**Lịch:** chuẩn hóa các cửa sổ rảnh đã opt-in sang UTC cho tuần cần xét; trừ quiet hours và các ngoại lệ mà chính user cho phép dùng; cắt giao với khoảng người tạo đề xuất; chia theo thời lượng đã chọn. Chỉ đề xuất khung nếu đủ số người mục tiêu. Sắp theo số người rảnh, độ gần khung mong muốn và thời điểm gần nhất, rồi lấy tối đa ba. Cùng input và revision phải ra cùng kết quả; AI chỉ được diễn đạt lý do, không chốt giờ. Nếu thiếu dữ liệu người nào, ghi `Chưa phản hồi`, không suy họ rảnh.

**Ghép:** lọc cứng `auth_verified ∧ consent ∧ not_blocked ∧ room_open ∧ capacity ∧ overlap ∧ mode_compatible`. `Cùng môn` thêm grade/curriculum version/subject; `Cùng tập trung` không thêm môn. Xếp mềm theo duration/cadence/topic/language; có tie-break ổn định. Không lấy `rank`, EXP, pet level, giờ dậy hoặc AI suy học lực làm điều kiện. Match result là **ứng viên**; người học xin vào và chủ phòng duyệt, backend kiểm lại sức chứa/quyền trong transaction. Không có ứng viên thì trả empty state, không tạo phòng/người giả. Không để client chọn `owner_id` hay sửa `score`.

## 3. Máy trạng thái và sự kiện

`proposal: draft → voting → confirmed | expired | cancelled`; vote stale revision = 409. `room: scheduled → waiting → active → reconnecting → ended`; mỗi thành viên có `invited → requested → approved → joined → left|removed`. `pet_award: pending → confirmed | rejected`; không phát thưởng trong `pending`. Event room có `sequence`, `roomVersion`, server timestamp; reconnect lấy snapshot rồi bù từ sequence, dedupe event và `clientRequestId`. Server là nguồn membership và pet ledger; timer từng máy giữ local, finish idempotent theo owner/session. Rớt mạng/đổi account thu hồi media token, không tự vào lại với account khác. Mất host cho phép chuyển quyền theo rule hoặc kết thúc phòng, nhưng không xóa phiên cá nhân hợp lệ.

## 4. API đề xuất, chưa triển khai

| Route nhóm | Quyền và kết quả |
| --- | --- |
| `PUT/GET /v1/me/availability` | Owner/revision; ghi cửa sổ rảnh, không gửi nguyên lịch nhóm. |
| `POST /v1/study/groups`, `POST /groups/{id}/invites`, `POST /groups/{id}/join` | Auth/consent, invite TTL, block, capacity; idempotency. |
| `POST /v1/study/groups/{id}/proposals`, `POST /proposals/{id}/votes`, `GET /proposals/{id}` | Owner/member; snapshot số người rảnh và trạng thái xác nhận. |
| `POST /v1/study/room-search`, `POST /rooms/{id}/requests`, `POST /requests/{id}/decision` | Feature flag + moderation; tìm ứng viên, xin vào, duyệt lại quyền/sức chứa. |
| `GET /v1/study/rooms/{id}/snapshot`, `WS /rooms/{id}/events` | Chỉ member; roomVersion/sequence; token media cấp riêng. |
| `GET /v1/study/groups/{id}/pet` | Member; level/ledger tổng hợp, không lộ giờ học cá nhân. |

Các route dùng Firebase ID token đã verify, owner từ token, `Idempotency-Key` cho mutation, lỗi 401/403/404/409/429 có nghĩa, pagination và rate limit. Đọc ID phòng không có quyền trả 404 không lộ tồn tại. Room discovery chỉ trả projection đã duyệt. Giao tiếp media và sự kiện lịch/điểm không dùng cùng một kênh làm nguồn sự thật: SFU truyền âm/ảnh; backend/DB chốt lịch, membership, XP, pet. Nếu dùng text stream trong media, nội dung quan trọng vẫn phải lưu/ack theo chính sách riêng; transport realtime không thay transaction. [LiveKit data transport](https://docs.livekit.io/transport/data/).

## 5. AI, EXP, pet và quyền dữ liệu

AI 1–1 dùng policy phòng hiện có: `deep` trả chữ theo yêu cầu, `interval/discussion` mới có voice opt-in. AI nhóm chỉ nhận câu hỏi được tag và nội dung người gửi chọn, không nhận audio/camera mọi người mặc định. Mọi người đồng ý riêng trước khi AI vào; người rút consent làm AI nhóm rời và hủy token, không kết thúc room/timer. Prompt injection trong câu hỏi nhóm không được đổi quyền hoặc đọc mục tiêu riêng của người khác.

EXP cá nhân vẫn theo `study-time-v0.1` và chuỗi ôn sáng hiện hành không đổi. **Chuỗi đúng giờ mới** có rule riêng `on-time-v0.1`: dùng alarm occurrence đã lập lịch local, sự kiện mở lượt trong 15 phút, attempt `correct` đủ bước trong 60 phút, schedule/revision đã chọn từ trước. Backend kiểm key/revision, thời gian bất thường, duplicate và chỉ xác nhận khi dữ liệu đủ tin cậy; không tin một timestamp client hoặc metadata ảnh như chứng cứ tuyệt đối đã tỉnh. Clock drift/OS không phát chuông, offline chưa sync, AI `uncertain`, ngày nghỉ trước lịch là trạng thái `pending|system_grace|planned_rest` phù hợp, không gán `missed` oan. Làm đúng muộn vẫn có thưởng học hiện hành nhưng không có `on_time_day`.

Mỗi `on_time_day` đã xác nhận tạo **một** `morning_care` cho `primary_care_group_id` đã chọn trước ngày đó. Mỗi group/ngày có `group_care_day` khi ít nhất một thành viên đóng góp; từ hai người có mốc hình ảnh `Cùng nhau`. Chuỗi group tính các ngày chăm liên tiếp theo lịch nhóm, `system_grace` giữ độ dài cũ nhưng không tăng. Ngày không ai chăm không cấp ngày mới; không trừ điểm/cấp pet đã có và không gắn lỗi cho một thành viên. Người dùng đổi nhóm chính có hiệu lực ngày kế tiếp, không chuyển một morning event sang hai group.

`study_care` là phần phụ: tối đa 1 điểm/người/ngày từ `finished` study session đã xác nhận với activeSeconds ≥ 1500, một session không cấp lại. Cả `morning_care` và `study_care` có reason/source unique, cap độc lập, server transaction hoặc outbox idempotent, không biến thành RP/EXP. Đây là **mốc thử nghiệm**, cần pilot; timer/camera không chứng minh đã học thật. Xóa/rời nhóm phải có policy giữ ledger tổng hợp nhưng xóa liên kết cá nhân theo yêu cầu được duyệt.

Không lưu audio/video/transcript mặc định. Availability là dữ liệu nhạy về thói quen: dùng projection free/busy, giới hạn retention proposal, xóa/rút chia sẻ, không đưa vào profile công khai hoặc push lock screen. Moderation tên nhóm/pet/phòng, report/block, chống spam lời mời và audit action của moderator là cổng trước room discovery. Không dùng camera hoặc cảm biến để suy “xao nhãng”.

## 6. Test và cổng mở

`GROUP-01` cùng input/revision cho cùng ba giờ; DST/timezone/quiet hours/lịch đổi đúng; không lộ nguyên nhân bận. `GROUP-02` đủ/từ chối/timeout vote, revision stale và hủy hẹn không tạo lịch hoặc nhắc trùng. `GROUP-03` tìm cùng môn khớp catalog; cùng tập trung khác môn; block/consent/capacity loại đúng, không có ứng viên trả rỗng. `GROUP-04` hai yêu cầu vào chỗ cuối chỉ một được duyệt; A/B/ID guess/token hết hạn không vào. `GROUP-05` reconnect/đổi account/mất host/media lỗi không cấp phiên/EXP trùng. `GROUP-06` pet: on-time event hợp lệ cấp morning care cho một nhóm, muộn không cấp, hai thành viên cùng ngày tạo một group care day, retry không nhân; 24:59 study=0, 25:00=1 study care, hai phiên cùng ngày vẫn 1; member vắng/rời không trừ cấp. `GROUP-07` AI nhóm yêu cầu consent mọi người, rút một người dừng AI nhưng room/timer vẫn chạy; deep không phát tiếng. `GROUP-08` mic/cam off mặc định, report/block và nội dung vi phạm được xử lý, dữ liệu riêng không qua room projection. `GROUP-09` tạo nhóm từ link/mã hết hạn, nhóm chính và đổi nhóm ngày sau, lịch/ngày nghỉ/OS lỗi/uncertain, clock drift và offline không thưởng hoặc làm đứt chuỗi oan. Chạy trên PostgreSQL và ít nhất hai máy Android; media/group 4 người cần bốn tài khoản và mạng yếu/reconnect. Test file hoặc demo UI không chứng minh tính năng đã sẵn sàng.
