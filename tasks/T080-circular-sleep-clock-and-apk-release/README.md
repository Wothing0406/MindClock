# T080 — Đồng Hồ Xoay Lịch Ngủ 24h Đồng Bộ Theme & Phát Hành APK GitHub Releases Trỏ `api.ieltsoasis.site`

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thêm widget đồng hồ xoay 24 giờ (`CircularSleepClockPicker`) ngay trong `AlarmConfigScreen` cho phép kéo trực tiếp 2 điểm **Giờ đi ngủ** và **Giờ dậy**, hiển thị cung ngủ và thời lượng ngủ (`X giờ Y phút`) đồng bộ 100% bảng màu `MindClockTheme` (`primary`, `sunrise`, `paper`, `surface`, `ink`, `outline`), không dùng emoji hệ thống, vẫn giữ nút tinh chỉnh `±5 phút` / `±15 phút` và `Semantics` cho khả năng tiếp cận.
  2. Thiết lập trang tải APK tĩnh + workflow phát hành GitHub Releases (`.github/workflows/android-release-apk.yml`) và script build APK local (`scripts/build_release_apk.ps1`) trỏ mặc định `MINDCLOCK_API_BASE_URL=https://api.ieltsoasis.site` (về máy host / tunnel hiện tại).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `app/lib/ui/features/guest_shell/widgets/circular_sleep_clock_picker.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`
  - `app/test/t080_circular_sleep_clock_test.dart`
  - `.github/workflows/android-release-apk.yml`
  - `scripts/build_release_apk.ps1`
  - `docs/download/index.html` (trang tải APK Cloudflare Pages cho `ieltsoasis.site`)
- **Liên quan:** Kế thừa `T079`.
- **Source refs đã đọc:** `app/lib/ui/core/theme/mindclock_theme.dart`, `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`.
- **Điểm tiếp tục:** Xây dựng `CircularSleepClockPicker` và tích hợp vào `AlarmConfigScreen`.

## Cổng trước coding

- [x] Đã đọc `MindClockTheme` và `AlarmConfigScreen`.
- [x] Đã xác định rõ ranh giới: không thay đổi logic báo thức local hay OS bridge.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và test xanh.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
