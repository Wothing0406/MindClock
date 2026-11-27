# Đặc tả T078 — Firebase App Distribution & Real Profile

- **AC-01 (Firebase App Distribution cấu hình đầy đủ, không giả upload khi chưa login):**
  - Có `.firebaserc` trỏ `default: "mindclock"` và `firebase.json` hợp lệ.
  - Có `scripts/distribute_apk_firebase.ps1` build APK với `--dart-define=MINDCLOCK_API_BASE_URL=...` và gọi `npx -y firebase-tools@latest appdistribution:distribute ... --app 1:357973416738:android:5e09df39793b206a05a37b`.
  - Có workflow `.github/workflows/firebase-app-distribution.yml` hỗ trợ `workflow_dispatch`. Khi chưa đăng nhập `firebase-tools` trong shell local, báo rõ bị chặn do chưa auth để người phụ trách đăng nhập chứ không bỏ qua xác thực.
- **AC-02 (Chuẩn hóa mã môn & Khôi phục Profile + TKB đa màn hình):**
  - `SubjectCatalog.normalizeCode` và `findByCode` ánh xạ chuẩn giữa backend (`TOAN`, `NGU_VAN`, `TIENG_ANH`, `VAT_LY`, `HOA_HOC`, `SINH_HOC`, `LICH_SU`, `DIA_LY`, `TIN_HOC`, `CONG_NGHE`, `GDCD`/`GDKTPL`) và client (`math`, `literature`, `english`, ...), giúp tên tiếng Việt và cờ `hasApprovedQuestions` hoạt động đúng sau khi tải `/v1/me` và `/v1/timetable`.
  - Bổ sung `fetchTimetableSnapshot()` (`GET /v1/timetable`) trên `PersonalFlowRepository` và `PersonalFlowViewModel`.
  - Khi đăng nhập thành công từ `AuthScreen` hoặc trực tiếp từ tab `Tôi` (`AccountAuthCard`), `MindClockShellScreen` tự khôi phục hồ sơ & TKB từ server nếu tài khoản có dữ liệu.
- **AC-03 (Profile rõ ràng cho người dùng thật & Sửa đầy đủ Biệt danh/Avatar/Lớp/Môn/Mục tiêu):**
  - `MeGuestScreen` hiển thị thẻ `Hồ sơ học sinh` rõ ràng: Biệt danh, Email/trạng thái xác thực, Khối lớp, Mục tiêu học tập, Chip môn học tiếng Việt, số tiết TKB/tuần, số báo thức bật, nút `Chỉnh sửa hồ sơ & TKB` và `Đồng bộ hồ sơ ngay`.
  - `TimetableProfileScreen` bổ sung chỉnh sửa Biệt danh (`alias`) và chọn Avatar preset (`MindClockAvatarCatalog.presets`), lưu cả local lẫn `PATCH /v1/me` + `PUT /v1/timetable`.
  - `DELETE /v1/me` xóa cả `DailyReport` cùng các bảng user-scoped khác.
- **AC-04 (Kiểm thử):** Toàn bộ `pytest`, `flutter test` (gồm `t078_real_profile_and_sync_test.dart`), `dart analyze`, `flutter analyze`, `check_docs_links.py`, `check_task_records.py` đều xanh.
