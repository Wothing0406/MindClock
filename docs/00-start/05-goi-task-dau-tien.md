# Gói task đầu tiên để AI bắt tay coding

Đây là **backlog có thứ tự**, chưa là task đã tạo. Từ [hiện trạng](01-hien-trang.md), B01 là điểm vào vì test/runtime đang treo. Mỗi gói khi được giao phải tạo `tasks/TNNN-...` từ template trước sửa code, thu hẹp một AC nếu quá lớn, cập nhật [truy vết](../03-quality/03-truy-vet-yeu-cau.md) và bàn giao theo [quy trình](03-quy-trinh-vibe-code.md). Không mở web route thay app.

| Gói | File phải đọc | Lát cắt và AC | Test/điểm dừng |
| --- | --- | --- | --- |
| B01a — ổn định backend test | `services/api/tests/test_api_v1.py`, `app/main.py`, `app/db/*`, `pyproject.toml`; [runbook](../03-quality/04-moi-truong-chay-thu.md) | `pytest` health kết thúc ổn định, xác định nguyên nhân treo; không đổi hợp đồng API để “lách” test | `pytest -vv` ca health, toàn suite, log nguyên nhân; PostgreSQL test sau. Nếu thuộc WIP T022/T023, phối hợp task owner, không ghi đè. |
| B01b — Flutter/Android build | `app/pubspec.yaml`, `app/lib/main.dart`, `app/android/`; [Android](../02-engineering/02-bao-thuc-android.md) | SDK/CI build debug, analyze/unit/widget; cấu hình env an toàn | `flutter doctor`, `flutter analyze`, `flutter test`, Gradle unit, APK artifact; ghi máy/version. Nếu Windows chặn runtime, chuyển máy/CI. |
| B01c — PostgreSQL migration | `services/api/alembic`, `db/models.py`, Docker compose; [SQL](../02-engineering/03-du-lieu-sql.md) | Migration trên DB trống và DB có dữ liệu, API health PostgreSQL, backup/restore rehearsal | Alembic + pytest với PostgreSQL, unique/rollback; SQLite pass không đủ. |
| B02 — alarm máy thật | `app/android/*Alarm*`, `BootAndTimeReceiver`, Flutter alarm service/ViewModel; [alarm](../02-engineering/02-bao-thuc-android.md) | Save/schedule/ring/Dừng/mode/permission/reboot đúng | AD01–AD07 ít nhất hai máy; fail Dừng thì chặn tiếp. |
| B03 — câu sáng | Flutter guest/personal flow, `/v1/challenges/next`, `questions`/seed; [content](../02-engineering/05-ngan-hang-cau-hoi.md) | TKB→câu duyệt→nhập chữ→feedback; offline không chấm | LEARN-01/02/06, Android E2E; reviewer câu thật. |
| B04 — tài khoản/đồng bộ | Auth gateway, `/v1/me|alarms|sessions`, DB; [API](../02-engineering/04-hop-dong-api.md) | Firebase test project, A/B, revision, idempotency, delete | AUTH-01/04, DATA-01, LEARN-05; PostgreSQL/two accounts. |
| B05 — AI đánh giá | Gemini service, `/answers|attempts`, corpus/rubric; [AI](../02-engineering/06-ai-va-cham-bai.md) | 3 verdict, uncertain/fallback, no secret/photo log, eval set | AI-01/02, LEARN-03/04; owner chốt ngưỡng trước pilot. |

**Không gộp B01a/b/c thành “fix cả production” nếu môi trường thiếu; mỗi task có AC và handoff riêng.** Sau B02 mới nói báo thức thật trên Android. Sau B04/B05 chưa được nói ranked/PvP sẵn sàng; xem [gates](02-lo-trinh.md).
