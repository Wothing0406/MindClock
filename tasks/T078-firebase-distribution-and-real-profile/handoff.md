# Bàn giao nhiệm vụ T078

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  - Thiết lập cấu hình Firebase App Distribution (`.firebaserc`, `firebase.json`), script [distribute_apk_firebase.ps1](../../scripts/distribute_apk_firebase.ps1) và workflow GitHub Actions [.github/workflows/firebase-app-distribution.yml](../../.github/workflows/firebase-app-distribution.yml) trỏ đúng Firebase Android App ID `1:357973416738:android:5e09df39793b206a05a37b`.
  - Chuẩn hóa mã môn `SubjectCatalog.normalizeCode` (`TOAN` ↔ `math`, `NGU_VAN` ↔ `literature`, `TIENG_ANH` ↔ `english`, ...), bổ sung `fetchTimetableSnapshot()` (`GET /v1/timetable`), sửa `DELETE /v1/me` xóa `DailyReport`, tự đồng bộ khôi phục Profile + TKB khi đăng nhập từ cả `AuthScreen` lẫn tab `Tôi`.
  - Nâng cấp card `Hồ sơ học sinh` trên `MeGuestScreen` (Biệt danh, Email/tài khoản, Khối lớp, Mục tiêu, Chip môn học tiếng Việt, thống kê TKB/báo thức, nút `Chỉnh sửa hồ sơ & TKB` và `Đồng bộ hồ sơ ngay`) và cho phép chỉnh Biệt danh + Avatar preset trên `TimetableProfileScreen` (kèm sửa overflow 320dp).
- **Test đã chạy:** Xem `tests.md` (`pytest`, `dart analyze`, `flutter analyze`, `flutter test`, `check_docs_links.py`, `check_task_records.py`, `check_game_assets.py`).
- **Bị chặn / chưa chạy:** Upload APK trực tiếp lên Firebase App Distribution bị chặn do `npx -y firebase-tools@latest login:list` báo `! No authorized accounts, run "firebase login"`; chưa test build APK release & E2E trên máy thật với backend public URL.
- **Điểm tiếp tục chính xác:** Người dùng chạy `npx -y firebase-tools@latest login` trên máy (hoặc thêm secret `FIREBASE_TOKEN` vào GitHub Actions), sau đó chạy `powershell -ExecutionPolicy Bypass -File scripts/distribute_apk_firebase.ps1 -ApiBaseUrl https://<backend-url> -Testers "<email-tester>"`.
- **Git:** Nhánh `main`, chưa commit/push.
