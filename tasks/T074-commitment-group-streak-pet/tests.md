# Kế hoạch kiểm thử

| ID | AC | Kịch bản | Mong đợi | Tầng | Kết quả |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | tạo nhóm 1–3, nhóm thứ 4/không auth/tên biên | tối đa 3 group active, owner đúng | API SQLite | Đạt 21/11/2026 |
| TC-02 | AC-02 | invite friend/non-friend/expired/full/accept kép/giới hạn 3 nhóm | quyền và capacity atomic | API + PostgreSQL | Đạt API + concurrency PG |
| TC-03 | AC-03 | join code, owner/non-owner approve | request state đúng | API | Đạt |
| TC-04 | AC-04 | kick/leave/delete/cross-owner | membership/group đúng | API | Đạt |
| TC-05 | AC-05 | study 299s/300s + morning correct/incorrect + retry trên 1–3 nhóm | care/EXP đúng từng nhóm, không trùng | API | Đạt; study + morning + retry |
| TC-06 | AC-06 | care dates liên tiếp/đứt và EXP qua mốc | streak/stage đúng | unit/API | Đạt contract/care; mốc tính server |
| TC-07 | AC-07 | repository wire contract | JSON/HTTP đúng | Flutter unit | Đạt |
| TC-08 | AC-07 | create/render/quản trị UI | state/loading/error đúng | Flutter widget | Đạt phạm vi fixture + analyzer |
| TC-09 | AC-07 | 320dp, chữ 200%, Reduce Motion | không overflow/animation bắt buộc | Flutter widget | Đạt; golden 390×844 |
| TC-10 | AC-01/02/05 | PostgreSQL migration/concurrency/idempotency | constraint/lock thật | PostgreSQL disposable DB | Đạt; 1 pass, DB random tự xóa |

## Lệnh và kết quả thực

- API SQLite: 7 passed.
- PostgreSQL disposable migration/concurrency: 1 passed.
- Flutter unit/widget/golden: 4 passed; analyzer 0 lỗi.
- Docs: 661 Markdown links pass; task records OK.
- Cảnh báo còn lại: deprecation alias `anyio.abc.BlockingPortal` từ Starlette, không làm test fail.
