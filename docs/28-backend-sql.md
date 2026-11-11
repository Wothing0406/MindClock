# Backend SQL — thiết kế khởi đầu

**Quyết định kiến trúc ngày 11/11/2026:** FastAPI tiếp tục là API; **PostgreSQL là nguồn dữ liệu có thẩm quyền** cho phiên, câu hỏi, XP và thi đấu. SQLite chỉ dùng cho demo/local một máy; không dùng SQLite làm server nhiều người thi trực tuyến. Firebase Authentication có thể giữ để xác thực ở giai đoạn đầu, backend xác minh ID token rồi ánh xạ `uid` sang `users.auth_subject`; không dùng Firestore cho dữ liệu nghiệp vụ mới. Đây là thay đổi thiết kế, **chưa có backend SQL đang chạy**. Quyết định này thay thế phần CSDL Firestore trong [docs/06](06-kien-truc-va-du-lieu.md); hợp đồng HTTP ở [docs/07](07-hop-dong-api-va-ai.md) vẫn giữ, trừ khi task coding ghi thay đổi cụ thể.

**Mở rộng sản phẩm:** [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md) thêm bảng hồ sơ nhiều môn, mục tiêu thi, task/nhắc lịch; [docs/31](31-bao-thuc-thu-thach.md) thêm mode không Hoãn và số lần sai rõ. Cần đưa các bảng/cột này vào migration khi code, không lưu dưới dạng JSON tùy tiện trong `users`.

## 1. Vì sao SQL

MindClock có nhiều quan hệ và bất biến: một người có lịch/báo thức/phiên; một phiên có lượt nộp; một sự kiện chỉ cấp XP một lần; hai bên trận đấu cùng chốt kết quả. SQL cho khóa ngoại, unique constraint và transaction rõ. PostgreSQL hỗ trợ [ràng buộc unique](https://www.postgresql.org/docs/current/ddl-constraints.html); dùng transaction để ghi phiên, XP và kết quả nhất quán. Không chuyển sang SQL vì giao diện cần React; lựa chọn giao diện và CSDL độc lập.

## 2. Sơ đồ thành phần

```mermaid
flowchart LR
  M[Flutter Android/iOS] -->|HTTPS + ID token| API[FastAPI]
  M --> A[Báo thức và cache trên máy]
  API -->|xác minh token| AUTH[Firebase Auth]
  API --> DB[(PostgreSQL)]
  API -->|ảnh tạm + rubric| AI[Gemini API]
  API -->|xóa sau xử lý| TMP[Ảnh tạm]
```

Ở demo 0 đồng có thể thay Firebase Auth bằng **tài khoản demo giả lập chỉ trong môi trường local**, AI bằng fixture, DB bằng SQLite local. Không được nối chế độ demo vào production. Online hai máy cần API và DB cùng truy cập qua mạng; nếu chưa có chỗ host miễn phí đáng tin, trình diễn giao hữu bằng dữ liệu mẫu có nhãn.

## 3. Cấu trúc backend dự kiến

```text
services/api/
  app/main.py
  app/config.py
  app/auth/verify_token.py
  app/db/base.py
  app/db/models/
  app/repositories/
  app/services/alarm.py
  app/services/grading.py
  app/services/xp.py
  app/services/competition.py
  app/routes/v1/
  alembic/versions/
  tests/
```

SQLAlchemy 2.x cho model/query và Alembic cho migration là lựa chọn đề xuất; [SQLAlchemy](https://docs.sqlalchemy.org/en/20/orm/session_transaction.html) dùng transaction context và [Alembic](https://alembic.sqlalchemy.org/en/latest/tutorial.html) quản lý schema revision. Pin phiên bản khi bắt đầu code. Một DB session/request, không chia sẻ session giữa request/task; chỉ commit ở service transaction boundary. Không giữ transaction mở lúc chờ Gemini: tạo attempt `pending` → gọi AI ngoài transaction → chốt kết quả trong transaction ngắn.

## 4. Bảng dữ liệu MVP

| Bảng | Cột chính | Ràng buộc/index quan trọng |
| --- | --- | --- |
| `users` | `id UUID PK`, `auth_subject`, `alias`, `grade_band`, `locale`, `time_zone`, `consent_version`, timestamps | `auth_subject UNIQUE`; không dùng email làm PK |
| `alarms` | `id`, `user_id`, `local_time`, `time_zone`, `weekdays_mask`, `enabled`, `snooze_minutes`, `revision` | FK user; `revision >= 1`; chỉ cấu hình, chuông chạy local |
| `timetable_slots` | `id`, `user_id`, `weekday`, `subject_code`, `topic_id`, `position` | FK user; `weekday 1..7`; unique user/day/position |
| `questions` | `id`, `subject_code`, `grade_band`, `topic_id`, `difficulty`, `prompt`, `answer_spec_json`, `rubric_json`, `status`, `revision`, `approved_by` | Index `(status, grade_band, subject_code, topic_id, difficulty)`; published phải có rubric/người duyệt |
| `alarm_sessions` | `id`, `user_id`, `alarm_id`, `local_session_id`, `question_id`, `question_revision`, `local_date`, `time_zone`, `state`, `version`, timestamps | `UNIQUE(user_id, local_session_id)`; FK; version chống ghi đè |
| `attempts` | `id`, `session_id`, `client_attempt_id`, `kind`, `grade_status`, `feedback_json`, `rubric_revision`, `model_version`, `created_at` | `UNIQUE(session_id, client_attempt_id)`; **không lưu ảnh** |
| `xp_ledger` | `id`, `user_id`, `source_type`, `source_id`, `reason`, `delta`, `created_at` | `UNIQUE(user_id, source_type, source_id, reason)`; delta theo rule server |
| `topic_progress` | `user_id`, `topic_id`, `attempts`, `correct`, `next_review_at`, `updated_at` | PK `(user_id, topic_id)`; chỉ server cập nhật |
| `idempotency_records` | `user_id`, `key`, `route`, `payload_hash`, `response_json`, `expires_at` | `UNIQUE(user_id, key)`; cùng key khác payload = 409 |
| `consent_events` | `id`, `user_id`, `scope`, `version`, `granted`, `occurred_at` | Append-only; hiện trạng tính từ event mới nhất |

Kiểu `UUID`, `JSON/JSONB`, timestamp timezone-aware; ứng dụng ghi UTC, `local_date` giữ ngày tại múi giờ người học. Với SQLite local, dùng kiểu tương thích qua ORM và test transaction chính trên PostgreSQL trước pilot. Không cho mobile truy cập SQL trực tiếp. Từng bảng có chính sách xóa/ẩn theo [docs/25](25-bao-mat-va-du-lieu.md).

## 5. Giao hữu và bảng hạng sau MVP

| Bảng | Khóa và ý nghĩa |
| --- | --- |
| `competition_profiles` | PK `user_id`, opt-in, alias công khai, avatar allowlist |
| `matches` | PK `id`, mode, question_id, state, deadline_at, rule_version |
| `match_players` | PK `(match_id,user_id)`, seen/submitted time, outcome |
| `match_submissions` | PK `id`, unique `(match_id,user_id)`, answer status, review state |
| `rating_ledger` | unique `(match_id,user_id)`, before/delta/after; hai dòng cùng transaction |
| `score_ledger` | unique `(board_id,user_id,source_id)`, điểm học tuần do server tính |
| `leaderboard_entries` | PK `(board_id,user_id)`, score, alias snapshot, updated_at; index `(board_id,score DESC,user_id)` |

`boards` định nghĩa môn/khối/tuần; `groups` và `group_memberships` thêm khi mở thi nhóm. Trận `uncertain/voided` không ghi rating. Bảng top 20 query theo index và keyset cursor, không quét toàn bộ attempts. Luật Solo RPG ba vòng và bảng SQL bổ sung (`match_rounds`, `round_skills`, `round_submissions`, `round_results`, `match_results`) ở [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md); quản lý revision câu ở [docs/34](34-ngan-hang-cau-hoi-da-mon.md). Phần Firestore trong docs/21 là mô hình cũ.

## 6. Transaction bắt buộc

1. **Tạo phiên:** insert `alarm_sessions` với unique `(user_id,local_session_id)`; retry trả phiên cũ. Kiểm tra question revision và ownership.
2. **Nộp bài:** unique `client_attempt_id`; kiểm tra trạng thái và giới hạn lượt. AI chạy ngoài transaction. Chốt `grade_status`, state phiên và `xp_ledger` trong cùng transaction ngắn; unique ledger chống cấp hai lần.
3. **Sửa kết quả AI:** thêm bản ghi audit; đảo/điều chỉnh XP bằng ledger mới, không xóa lịch sử cũ. Không cho AI trực tiếp ghi SQL.
4. **Trận:** lock hàng match và hai player theo thứ tự ổn định, xác nhận hai submission, chốt outcome và hai dòng rating ledger trong một transaction; retry không đổi rating. Tránh lock lâu khi chờ AI/mạng.
5. **Xóa tài khoản:** ẩn leaderboard/thu hồi quyền ngay; xóa dữ liệu cá nhân theo batch và chứng thực trạng thái; không báo hoàn tất trước khi xong.

## 7. API, bảo mật và vận hành

- API `/v1` theo [docs/07](07-hop-dong-api-va-ai.md); backend xác minh Firebase ID token, tự lấy UID và tra `users`. Không nhận điểm, role hoặc `user_id` từ client làm sự thật.
- SQL dùng query tham số hóa/ORM; DB credential chỉ server giữ, quyền DB chia migration/runtime và tối thiểu. Không log SQL params có PII, ảnh, token hoặc lời giải.
- Migration Alembic có upgrade và kế hoạch rollback; test migrate DB trống và DB có dữ liệu mẫu. Không dùng `create_all()` thay migration trên staging/production.
- Backup/restore PostgreSQL, kiểm thử khôi phục, và quy trình xóa dữ liệu phải đi cùng nhau. `health` kiểm tra API; readiness kiểm tra DB nhưng không lộ DSN.
- Local 0 đồng: Python + SQLite + Gemini mock. Test CI có thể dùng PostgreSQL chạy local/container nếu đội cài được; SQLite không thay kiểm thử khóa/transaction PostgreSQL cho XP và rating.

## 8. Chuyển từ docs Firestore cũ

| Tài liệu cũ | Tình trạng khi coding SQL |
| --- | --- |
| `docs/06` §5–7 | Schema Firestore là lịch sử thiết kế; thay bằng bảng và quy tắc ở docs/28. Luồng báo thức/state §1–4 vẫn áp dụng. |
| `docs/17` vòng đời dữ liệu | Giữ nghiệp vụ, đổi tên collection thành bảng; cập nhật khi task đầu tiên code. |
| `docs/18` tích hợp API | Giữ client → FastAPI → Gemini; thay Firestore adapter bằng SQL repository. |
| `docs/21` bảng đấu trường | Giữ luật; thay projection Firestore bằng `leaderboard_entries` SQL. |
| `docs/12`, `docs/25` | Thay kiểm thử Firestore Rules bằng DB/API authorization, migration, backup và SQL retention; Firebase Auth vẫn cần cấu hình an toàn. |

**Cổng bắt đầu code:** tạo ADR-002 mới ghi thay Firestore, cập nhật docs liên quan trong cùng task, chốt PostgreSQL version/hosting ngân sách, lập migration đầu và test unique/transaction. Vì repo hiện chưa có dữ liệu production, chưa cần chuyển dữ liệu thật. Không tuyên bố SQL đã được triển khai chỉ vì có tài liệu này.

