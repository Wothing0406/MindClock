# Kế hoạch T075

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Migration 0006 + endpoint chọn primary + test PG/A-B | một primary/user, quyền đúng | [x] |
| 2 | Flutter model/repository + pet dashboard card | dữ liệu server/empty/error đúng | [x] |
| 3 | Share card + gateway + Kotlin/FileProvider | PNG/intent typed, cancel an toàn | [x] |
| 4 | Widget/unit/native test + analyzer/docs | AC-01–05 đạt | [x] |
| 5 | Build/cài emulator, chụp PNG + quay MP4 | font thật, recap đường dẫn | [x] |
| 6 | Rà staged/secret, commit/push/handoff | remote SHA trùng | [ ] |

## Rủi ro/đường lui

- Share target có thể không tồn tại trên emulator: bridge vẫn phải trả `NO_SHARE_TARGET`; PNG còn kiểm được.
- Tắt card bằng việc không truyền repository; dashboard chính vẫn hoạt động.
- Không sửa WIP game/Firebase/web đang nằm ngoài task.
