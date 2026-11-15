# Dữ liệu, PostgreSQL và migration

**Nguồn sự thật online:** PostgreSQL qua FastAPI. SQLite chỉ local/test một máy; Firestore không lưu nghiệp vụ. **Hiện có:** SQLAlchemy models và Alembic migration đầu trong [`services/api/app/db/`](../../services/api/app/db) và [`alembic/`](../../services/api/alembic). Bảng hiện có **không có PvP/rank**; phần đó ở [game spec](../04-game/01-pvp-gdd.md). Mọi schema mới cần migration + rollback/data migration + test trên PostgreSQL.

## 1. Danh mục bảng hiện có và owner

| Bảng | Khóa/quan hệ/ý nghĩa | Quyền ghi |
| --- | --- | --- |
| `users` | `id`, `auth_subject` unique, alias, khối, môn, mục tiêu, timezone/locale, consent version | Backend sau xác minh Auth. |
| `alarms` | owner, giờ/ngày/mode/revision; **không chứng minh OS máy đã lập lịch** | Owner qua API; mobile schedule local riêng. |
| `timetable_slots` | owner + weekday + position unique, subject/topic | Owner; revision/conflict cần hợp đồng khi đồng bộ. |
| `questions` | subject/grade/topic/difficulty, prompt, answer/rubric server-only, revision/status/provenance cơ bản | Chỉ pipeline nội dung/reviewer; AI draft không tự publish. |
| `alarm_sessions` | owner, `local_session_id` unique theo user, question revision, state/version | Backend từ sự kiện hợp lệ; không tin thời gian thiết bị. |
| `attempts` | `session_id + client_attempt_id` unique, kind, result, feedback/rubric/model revision | Backend sau validate/chấm. |
| `study_sessions` | owner + client session unique, task/subject/elapsed/focus/finish | Backend theo hợp đồng; timer local là nguồn UX. |
| `xp_ledger` | unique `(user_id,source_type,source_id,reason)`, delta | Backend transaction duy nhất. |
| `topic_progress` | user/topic key, lượt/đúng/next review | Backend sau attempt hợp lệ. |
| `idempotency_records` | unique user/route/key + payload/result hash | Backend chống retry/trùng. |
| `consent_events` | lịch sử đồng ý/rút theo user/version/scope | Backend audit; không tự suy consent. |

`rank_ledger` chỉ được thêm khi mở ranked; không tạo `rating_ledger` song song. Avatar/upload/moderation/content pipeline chi tiết chưa nằm đủ trong migration hiện tại; task riêng phải chốt schema và retention trước code.

**Khi mở P-11/P-12:** timetable slot hiện có cần revision/bản ngoại lệ theo ngày, task ngày có owner/due local date/timezone/source/confirmation và notification preference + scheduled-event key để hủy/lập lại không trùng. Public profile phải là projection opt-in chỉ từ trường đã duyệt, tách private progress/alarm history; avatar cần upload metadata/status/reviewer/expiry và object key an toàn. Không tạo bảng trống hàng loạt trước task/migration/retention được duyệt. [Lịch/nhắc](../01-product/05-lich-hoc-nhac-viec.md), [hồ sơ](../01-product/06-ho-so-tien-do-xa-hoi.md).

## 2. Bất biến transaction

- Tạo session theo `(user_id, local_session_id)` và attempt theo `(session_id, client_attempt_id)` idempotent. Cùng key cùng payload trả cùng kết quả; key khác payload 409, không cấp XP hai lần.
- Chấm bài và ghi `attempts`, `xp_ledger`, `topic_progress`, trạng thái session trong một transaction hoặc có cơ chế bù trừ/audit rõ. Không trả success khi commit thất bại.
- Chỉ `published` question có reviewer/rubric/revision/allowed mode hợp lệ mới cho điểm. Câu AI `draft` chỉ luyện không XP/rank; không đưa answer spec/rubric trước reveal.
- `uncertain`, emergency stop, offline metadata, sai bài không trừ/cấp XP sai. AI không ghi bảng trực tiếp. Mọi query theo owner token, deny-all mặc định và test A/B.
- Lịch/khối/môn có revision để đồng bộ hai máy; không đè âm thầm cấu hình báo thức local. Thời điểm DB UTC, ngày học theo timezone IANA.

## 3. Vòng đời dữ liệu

Guest local → đăng nhập/consent → chọn dữ liệu để sync → server xác thực, kiểm revision → học/attempt → tiến độ/ledger → export/xóa. Ảnh bài xử lý tạm trong request, xóa trên mọi nhánh; không vào DB, object storage, log hoặc backup mặc định. Nháp chữ local nếu chọn lưu có TTL 24h, cách ly theo local profile. Retention online/backup cụ thể phải chốt trong [chính sách](../01-product/04-tai-khoan-quyen-rieng-tu.md) trước pilot.

## 4. Migration và môi trường

Dev/test có thể dùng SQLite để chạy nhanh, **không** dùng kết quả đó để chứng minh PostgreSQL. CI/staging: `alembic upgrade head` trên DB trống và DB từ revision trước; kiểm unique/FK/cascade/transaction; thử downgrade hoặc quy trình rollback forward theo migration; seed dữ liệu đội duyệt ở môi trường phù hợp. Production app role chỉ quyền tối thiểu; migration role riêng. `Base.metadata.create_all()` không chạy production. Có backup/restore thử và khả năng tạm dừng endpoint ghi khi rollback.

## 5. Test tối thiểu

`DATA-01` user A/B, anonymous/expired token; `DATA-02` duplicate session/attempt/XP; `DATA-03` payload khác cùng key; `DATA-04` transaction lỗi giữa chừng; `DATA-05` migration PostgreSQL trống/có dữ liệu/rollback; `DATA-06` xóa user/backup/TTL; `DATA-07` conflict timetable revision; `DATA-08` question draft/retired không cấp XP; `DATA-09` ảnh/temp/log không sót. Ghi schema version/DB engine/test môi trường trong task.
