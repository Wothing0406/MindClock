# Bàn giao nhiệm vụ T095

- **Trạng thái cuối:** `verifying` (đã hoàn tất code, test tự động, rebuild Docker API và build APK release `67.2 MB`; chưa có thiết bị Android thật cắm qua `adb` để bấm kiểm thử trực tiếp trên máy).
- **Đã làm:**
  1. Xóa chế độ khách không cần đăng nhập (`guest-alarm-only`, `auth-offline-alarm-fallback`, `onboarding-later`, `onboarding-alarm-only`) trên `WelcomeScreen`, `AuthScreen`, `OnboardingSetupScreen`, `AccountAuthCard`, `MindClockShellScreen`.
  2. Làm sạch ngôn ngữ UI trên toàn app (bỏ `local`, `cục bộ`, `máy chủ`, `server`, `offline`, `GDPT 2018`, `study-time-v0.1`, `OS`).
  3. Mở lựa chọn **`Hẹn giờ thường`** (`AlarmMode.normal`) vs **`Báo thức dậy học`** (`AlarmMode.challenge`) trên `AlarmConfigScreen` + cập nhật `AlarmRingScreen`.
  4. Rút gọn chat AI trong `StudySpaceScreen` còn 1 ô nhập duy nhất mượt mà (`study-ai-question-input`, gửi qua nút hoặc phím Enter), bỏ ô `study-ai-tried-step-input` và khóa chặn Socratic.
  5. Áp dụng giới hạn **tối đa 1 báo thức hoàn thành/ngày** ở cả Flutter (`GuestWorkspaceViewModel`, `AlarmRingScreen`) và FastAPI/PostgreSQL (`services/api/app/routes/v1.py`), đồng bộ `docs/01-product/09-giac-ngu-va-bao-thuc.md`.
  6. Sửa `scripts/build_release_apk.ps1`, rebuild container `api-api-1`, build APK release và đóng gói thư mục `product/` (`product/README.md`, `product/mindclock-android.apk`).
- **Kiểm chứng gần nhất (`2026-11-28`):**
  - `pytest tests/test_t095_single_daily_alarm_cap.py tests/test_t094_study_room_lifecycle_postgres.py tests/test_api_v1.py -q` (PostgreSQL 16): `24 passed`.
  - `cd app; flutter analyze --no-pub`: `No issues found!`.
  - `cd app; flutter test --no-pub -j 1`: `200 passed` (`0` failed).
  - `scripts/build_release_apk.ps1`: xuất `dist/apk/mindclock-android.apk` và `product/mindclock-android.apk` (`70,475,285 bytes` / `67.2 MB`).
- **Điểm tiếp tục chính xác:** Cắm máy Android thật hoặc tải `product/mindclock-android.apk` để kiểm thử end-to-end trên thiết bị rồi chuyển trạng thái `T095` sang `done`.
