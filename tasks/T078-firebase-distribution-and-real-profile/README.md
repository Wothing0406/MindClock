# T078 — Cấu hình Firebase App Distribution & Hoàn thiện Hồ sơ Người dùng Thật

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thiết lập **Firebase App Distribution** cho dự án `mindclock` (`1:357973416738:android:5e09df39793b206a05a37b`) gồm `.firebaserc`, `firebase.json`, `scripts/distribute_apk_firebase.ps1` và `.github/workflows/firebase-app-distribution.yml`.
  2. Hoàn thiện luồng vào **Hồ sơ học sinh (`Profile`)** rõ ràng và đồng bộ thật cho người dùng thật (`SubjectCatalog.normalizeCode`, `GET /v1/timetable`, khôi phục tự động khi đăng nhập ở `AuthScreen` hoặc tab `Tôi`, `DELETE /v1/me` xóa `daily_reports`, `MeGuestScreen` hiển thị đầy đủ Hồ sơ, `TimetableProfileScreen` chỉnh sửa được Biệt danh & Avatar + sửa overflow 320dp).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa/tạo:**
  - `.firebaserc`, `firebase.json`, `scripts/distribute_apk_firebase.ps1`, `.github/workflows/firebase-app-distribution.yml`
  - `services/api/app/routes/v1.py`
  - `app/lib/domain/{models/subject_catalog.dart,services/personal_flow_repository.dart}`
  - `app/lib/data/{repositories/remote_personal_flow_repository.dart,debug/debug_fixture_personal_flow_repository.dart}`
  - `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/{me_guest_screen.dart,timetable_profile_screen.dart,mindclock_shell_screen.dart}`
  - `app/test/t078_real_profile_and_sync_test.dart`
- **Liên quan:** Kế thừa `T076`, `T077`.
- **Source refs đã đọc:** `AGENTS.md §3–§4`, `app/android/app/google-services.json`, `app/android/app/build.gradle.kts`, `app/lib/domain/models/subject_catalog.dart`, `services/api/app/routes/v1.py`, `app/lib/ui/features/guest_shell/views/{me_guest_screen.dart,timetable_profile_screen.dart,mindclock_shell_screen.dart}`.
- **Điểm tiếp tục:** Người phụ trách chạy `npx -y firebase-tools@latest login` (hoặc cấu hình `FIREBASE_TOKEN` trên GitHub Secrets) và chạy `scripts/distribute_apk_firebase.ps1 -ApiBaseUrl <HTTPS_URL>` để đẩy bản APK lên Firebase App Distribution.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định các lỗi thật (lệch mã môn `TOAN`/`math`, thiếu khôi phục `/v1/timetable` và khôi phục hồ sơ khi login ở tab Tôi, thiếu sửa Biệt danh/Avatar ở `TimetableProfileScreen`, và Firebase CLI chưa đăng nhập).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Code & test xác minh cho phần Profile/Sync/SubjectCatalog/Firebase config đạt trên local (phần upload live lên Firebase App Distribution bị chặn do chưa đăng nhập tài khoản Firebase CLI trong máy).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] `handoff.md` nêu cách kiểm tra, lệnh Firebase login/distribute cho người dùng và điểm tiếp tục.
