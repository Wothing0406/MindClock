# Bàn giao nhiệm vụ T080

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  1. Thêm widget `CircularSleepClockPicker` (`app/lib/ui/features/guest_shell/widgets/circular_sleep_clock_picker.dart`) đồng hồ xoay 24h kéo giờ đi ngủ & giờ báo thức, dùng 100% token `MindClockTheme` (`night`, `nightSurface`, `primary`, `sunrise`, `nightText`), tích hợp vào `AlarmConfigScreen` cùng nút tinh chỉnh nhanh `±`.
  2. Tạo `scripts/start_exam_tunnel.ps1`, `scripts/build_release_apk.ps1`, `.github/workflows/android-release-apk.yml` (publish GitHub Releases đính kèm `mindclock-android.apk`), và `docs/download/index.html` (trang tải cho `https://ieltsoasis.site/`).
  3. Cấu hình Cloudflare Tunnel `mindclock-exam` trỏ `https://api.ieltsoasis.site` về Docker FastAPI + PostgreSQL 16 trên máy local.
- **Test đã chạy (27/11/2026):** `dart analyze . --fatal-infos`, `flutter analyze --no-pub`, `flutter test --no-pub -j 1 test/t080_circular_sleep_clock_test.dart test/alarm_ai_preview_and_candle_test.dart` → 4/4 passed.
- **Điểm tiếp tục chính xác:** Kiểm tra kết quả build `dist/apk/mindclock-android.apk`, push code/tag `v1.0.0` lên GitHub khi user xác nhận, và deploy `docs/download/index.html` lên Cloudflare Pages (`ieltsoasis.site`).
- **Git:** Chưa commit/push.
