# Kế hoạch thực hiện T078

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T078-firebase-distribution-and-real-profile/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Tạo `.firebaserc`, `firebase.json`, `scripts/distribute_apk_firebase.ps1`, `.github/workflows/firebase-app-distribution.yml` | Validate cú pháp và app ID khớp `google-services.json` | [x] |
| 3 | Fix `SubjectCatalog.normalizeCode`, thêm `fetchTimetableSnapshot()`, fix `DELETE /v1/me` (`DailyReport`), auto-hydrate khi login từ tab Tôi | Contract & sync test xanh | [x] |
| 4 | Nâng cấp thẻ `Hồ sơ học sinh` trên `MeGuestScreen` & thêm chỉnh Biệt danh/Avatar + sửa overflow 320dp trên `TimetableProfileScreen` | Render chuẩn 320dp chữ 200%, sửa/lưu đồng bộ | [x] |
| 5 | Viết test `t078_real_profile_and_sync_test.dart`, chạy full `pytest` + `flutter test` + scripts & cập nhật `handoff.md` | Toàn bộ test xanh | [x] |

## Rủi ro và đường lui

- **Firebase CLI chưa đăng nhập:** Không có credential trong shell tự động; script kiểm tra `login:list` trước khi upload và hướng dẫn rõ lệnh `npx -y firebase-tools@latest login`.
- **Tương thích profile cũ:** `SubjectCatalog.normalizeCode` chấp nhận cả chữ thường (`math`) lẫn mã chuẩn VN (`TOAN`), không làm mất dữ liệu local cũ.
