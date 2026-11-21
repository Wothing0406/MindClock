# Kế hoạch thực hiện

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Migration 0005 + models/index/constraints | Alembic SQLite/PostgreSQL đạt | [x] |
| 2 | Group service + schemas/routes + account deletion + care hook | API A/B/atomic/idempotent đạt | [x] |
| 3 | Domain/repository/debug fixture Flutter | Contract đa nhóm/EXP parse đúng | [x] |
| 4 | Group hub UI trong tab Tôi, chuyển pet, pet asset runtime | 320dp/200%, Reduce Motion, không raw color/emoji | [x] |
| 5 | Test full scope, docs, diff/secret | Không P0/P1 trong lát | [x] |
| 6 | Commit/push/verify/handoff | SHA remote đúng | [x] |

## Ngoài phạm vi và task tiếp

- T075: thẻ pet trên dashboard, share card 1080, Android share sheet và dọn file tạm.
- T076: invite link/QR TTL, phòng chờ, duyệt và lịch hẹn.
- T077: chat phòng, ảnh và `@MindClock` với câu trả lời text/voice có consent.
- T078/T079: audio rồi camera thật hai máy.
- Game vẫn theo T083–T085; không stage WIP game vào T074.
