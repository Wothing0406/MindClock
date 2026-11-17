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

MultiCal/phòng nhóm/pet **chưa có bảng**; khi mở R7b, thiết kế migration theo [đặc tả lịch chung và ghép phòng](12-lich-chung-va-ghep-phong.md): availability riêng từng owner, proposal/vote có revision, membership/capacity server, chuỗi đúng giờ tách chuỗi ôn sáng, pet ledger unique theo `morning_care|study_care` và trần ngày. Một người chỉ có một nhóm chăm pet chính/ngày; đổi nhóm có hiệu lực ngày sau. Không sao chép TKB hoặc giờ ngủ vào room projection; test A/B, Android alarm thật và PostgreSQL trước mở.

**Khi mở P-01/P-11/P-12/P-13/P-14:** user profile cần `onboarding_state`, lớp THPT, `curriculum_version`, môn/tổ hợp/mức tự đánh giá riêng từng môn, avatar default/pending; không lưu mật khẩu. Catalog chương trình có source/reviewer/version bất biến. Timetable slot hiện có cần revision/bản ngoại lệ theo ngày, task ngày có owner/due local date/timezone/source/confirmation và notification preference + scheduled-event key để hủy/lập lại không trùng. `SleepSchedule` và alarm OS authority vẫn local; server chỉ giữ bản cấu hình nếu user đồng bộ rõ. Public profile phải là projection opt-in chỉ từ trường đã duyệt, tách private progress/alarm history; avatar cần upload metadata/status/reviewer/expiry và object key an toàn. Room/invite/friend/block/report cần owner/membership/TTL/status/audit, không lưu media mặc định. Không tạo bảng trống hàng loạt trước task/migration/retention được duyệt. [Onboarding](../01-product/07-dang-ky-va-khoi-tao-lo-trinh.md), [catalog](10-catalog-chuong-trinh-va-ke-hoach.md), [lịch/nhắc](../01-product/05-lich-hoc-nhac-viec.md), [hồ sơ](../01-product/06-ho-so-tien-do-xa-hoi.md), [room](09-phong-hoc-realtime.md).

R7 room invite QR cần token hash/expiry/revocation/max uses và membership tách khỏi media token; room chat ngắn hạn cần message owner/room/sequence/recipient scope, ảnh xử lý tạm và TTL. `group_message` không là input AI mặc định; `ai_turn` chỉ tham chiếu nội dung được user chọn sau kiểm quyền. Schema/retention/migration chỉ chốt trong task code, [contract realtime](09-phong-hoc-realtime.md).

**Khi mở MorningCard/EduSkills:** lưu `morning_cards` gắn `question_id + revision + curriculum_version + learning_outcome`, hook/reveal bản quyền đội, asset/fallback chữ, status/reviewer/rights/content hash và `edu_skills_commit`/prompt version ở **pipeline nội dung**, không đọc skill Markdown hay sách từ client. Session cần `confirmed_incorrect_count` được suy từ attempt `incorrect` duy nhất, trạng thái `active|correct|abandoned|emergency_stopped|incomplete|system_deferred` và policy version; không tin bộ đếm client. Tạo `streak_day_ledger` hoặc bảng tương đương với khóa duy nhất `(user_id, local_date, challenge_schedule_id)` khi code thưởng chuỗi; loại ngày `completed|missed|planned_rest|system_grace`. Chỉ `correct` chắc được xét một lần; bỏ lượt/dừng/không hoàn thành hết ngày không cộng, ngày nghỉ lên lịch trước và lỗi hệ thống không làm đứt chuỗi oan. `system_grace` giữ chuỗi cũ nhưng không cộng ngày mới. Mọi bảng/enum này **chưa mặc định tồn tại**; task migration phải định nghĩa chi tiết và test PostgreSQL. [Morning flow](../01-product/09-giac-ngu-va-bao-thuc.md), [EduSkills](11-eduskills-vn-tich-hop.md).

## 2. Bất biến transaction

- Tạo session theo `(user_id, local_session_id)` và attempt theo `(session_id, client_attempt_id)` idempotent. Cùng key cùng payload trả cùng kết quả; key khác payload 409, không cấp XP hai lần.
- Chấm bài và ghi `attempts`, `xp_ledger`, `topic_progress`, trạng thái session trong một transaction hoặc có cơ chế bù trừ/audit rõ. Không trả success khi commit thất bại.
- Chỉ `published` question có reviewer/rubric/revision/allowed mode hợp lệ mới cho điểm. Câu AI `draft` chỉ luyện không XP/rank; không đưa answer spec/rubric trước reveal.
- `uncertain`, emergency stop, offline metadata, sai bài không trừ/cấp XP sai. AI không ghi bảng trực tiếp. Mọi query theo owner token, deny-all mặc định và test A/B.
- Chỉ attempt `incorrect` có chứng cứ, ID duy nhất, đúng session/revision mới tăng đếm mở hint/bỏ lượt; retry cùng ID không tăng hai lần. `abandoned` không tạo `xp_ledger`/ngày chuỗi; `system_deferred` do AI/asset/mạng/câu lỗi không bị coi là người học bỏ lượt.
- Lịch/khối/môn có revision để đồng bộ hai máy; không đè âm thầm cấu hình báo thức local. Thời điểm DB UTC, ngày học theo timezone IANA.

## 3. Vòng đời dữ liệu

Giải thích quyền → đăng ký/đăng nhập (local alarm nếu offline) → hồ sơ học/avatar → plan nháp/xác nhận → chọn dữ liệu để sync → server xác thực, kiểm revision → học/attempt/room khi có quyền → tiến độ/ledger → export/xóa. Ảnh bài/frame AI xử lý tạm trong request, xóa trên mọi nhánh; không vào DB, object storage, log hoặc backup mặc định. Nháp chữ local nếu chọn lưu có TTL 24h, cách ly theo local profile. Retention online/backup cụ thể phải chốt trong [chính sách](../01-product/04-tai-khoan-quyen-rieng-tu.md) trước mở cho người dùng thật.

## 4. Migration và môi trường

Dev/test có thể dùng SQLite để chạy nhanh, **không** dùng kết quả đó để chứng minh PostgreSQL. CI/staging: `alembic upgrade head` trên DB trống và DB từ revision trước; kiểm unique/FK/cascade/transaction; thử downgrade hoặc quy trình rollback forward theo migration; seed dữ liệu đội duyệt ở môi trường phù hợp. Production app role chỉ quyền tối thiểu; migration role riêng. `Base.metadata.create_all()` không chạy production. Có backup/restore thử và khả năng tạm dừng endpoint ghi khi rollback.

## 5. Test tối thiểu

`DATA-01` user A/B, anonymous/expired token; `DATA-02` duplicate session/attempt/XP; `DATA-03` payload khác cùng key; `DATA-04` transaction lỗi giữa chừng; `DATA-05` migration PostgreSQL trống/có dữ liệu/rollback; `DATA-06` xóa user/backup/TTL; `DATA-07` conflict timetable revision; `DATA-08` question draft/retired không cấp XP; `DATA-09` ảnh/temp/log không sót. Ghi schema version/DB engine/test môi trường trong task. Revision hiện hành `0002_align_question_indexes` (`services/api/alembic/versions/`) đã khớp 100% với `Base.metadata` (`compare_metadata == []`), có module diễn tập backup/restore có kiểm tra SHA-256 (`services/api/app/db/backup.py`) và bộ test tự động `services/api/tests/test_migrations_and_data_invariants.py`.
