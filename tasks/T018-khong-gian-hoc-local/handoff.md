# Bàn giao nhiệm vụ T018 — Không gian học local (6A)

- **Trạng thái cuối:** `blocked` (đủ mã nguồn Flutter, Android native `mindclock/study_focus` và bộ test `SF-TC-01..08`; chưa thể chạy `flutter analyze`, `flutter test` và kiểm tra thiết bị thật vì máy hiện tại chưa cài Flutter/Dart SDK và ADB/thiết bị Android).

## Đã làm (hành vi cụ thể)

1. **Domain & đồng hồ theo mốc thời gian (`docs/45 §§1–2`):**
   - `StudyFocusLevel` (`Linh hoạt`, `Tập trung thường` mặc định, `Cam kết`), `StudyFocusStatus` (`draft → running ↔ paused → completed | endedEarly` và `running | paused → interrupted → running | endedEarly`), `StudyTaskChoice` (gợi ý từ lịch học/hồ sơ + `Học tự do`).
   - `StudyFocusSessionSnapshot` lưu `startedAtEpochMs`, `plannedEndAtEpochMs`, `pausedAtEpochMs`, `leftAtEpochMs` và tính tách biệt `elapsedWallSeconds` với `inAppFocusSeconds` từ mốc thời gian thiết bị (không giảm theo mỗi lần render, không cộng thời gian ảo khi app tắt/kill).
2. **Xử lý đúng ngưỡng rời app & khôi phục sau kill/reboot (`F01–F03`):**
   - Lạnh mở lại từ `running` hoặc `paused` tự chuyển về `interrupted` (`Phiên đã gián đoạn`) tại mốc sống cuối cùng để không cộng giờ ảo, vẫn cho `Tiếp tục học` hoặc `Kết thúc`.
   - Ngưỡng rời app: `Linh hoạt` chỉ báo thời gian rời; `Tập trung thường` > 30 giây hiển thị 1 nhắc cục bộ khi quay lại (tùy chọn nhắc ngoài app qua kênh thông báo riêng `NOTIFICATION_ID = 4301` + `setOnlyAlertOnce(true)`, không chồng); `Cam kết` > 10 giây dừng `inAppFocusSeconds`, trừ quãng rời và yêu cầu bấm `Tiếp tục học` (vẫn cho `elapsedWallSeconds` chạy thực tế, vẫn thoát được).
3. **Lưu cục bộ idempotent, tách tài khoản, 0 XP ảo (`F07`):**
   - `LocalStudyFocusRepository` scope khóa theo `ownerScopeKey` (`guest`, `user:<uid>`), lưu bản ghi hoàn tất idempotent theo `sessionId`. Đăng xuất/đổi tài khoản đồng bộ qua `MindClockShellScreen` → `StudyFocusViewModel.setOwnerScope`, không lộ phiên tài khoản trước.
   - Đồng hồ và camera hoàn toàn tắt, không tự cấp XP/streak/coin (`xpAwardedByTimer == 0`).
4. **Công cụ hệ thống trung thực & Android native (`F08`, `docs/45 §1`):**
   - `StudyFocusBridgeHandler.kt` (`mindclock/study_focus`, `MainActivity.kt`, `<queries>` trong `AndroidManifest.xml`): thử mở Digital Wellbeing (`com.google.android.apps.wellbeing` / `com.samsung.android.forest`); nếu không hỗ trợ trả về `unavailable` kèm giải thích trung thực. Không dùng Accessibility, overlay, VPN, device-admin, UsageStats hay Lock Task. Hoàn toàn tách biệt với `AlarmSchedulerImpl` và `AlarmRingService`.
5. **Giao diện `vi-VN`, Reduce Motion, TalkBack (`F09`) & điểm vào:**
   - Sửa lỗi thiếu enum `MindClockIconKind.warning` và thêm `play`, `pause`, `stop` trong `app/lib/ui/core/widgets/mindclock_icon.dart`.
   - `StudySpaceScreen` hỗ trợ 320–600 dp, chữ 200%, `Semantics`, chế độ số tĩnh khi Reduce Motion bật, nối từ card `Không gian học` (`Bắt đầu học` / `Quay lại phiên học`) trên `TodayScreen` và nút trong `PracticeSessionScreen`; `AlarmRingScreen` vẫn ưu tiên hiển thị đè lên trên khi báo thức đến giờ.

## File/code/docs thay đổi

- Task records: `tasks/T018-khong-gian-hoc-local/{README.md,spec.md,plan.md,tests.md,worklog.md,handoff.md}`.
- Domain: `app/lib/domain/models/study_focus_models.dart`, `app/lib/domain/services/study_focus_bridge.dart`.
- Data: `app/lib/data/repositories/local_study_focus_repository.dart`, `app/lib/data/services/method_channel_study_focus_bridge.dart`.
- Android native: `app/android/app/src/main/kotlin/com/mindclock/app/StudyFocusBridgeHandler.kt`, `app/android/app/src/main/kotlin/com/mindclock/app/MainActivity.kt`, `app/android/app/src/main/AndroidManifest.xml`.
- UI & Wiring: `app/lib/ui/core/widgets/mindclock_icon.dart`, `app/lib/ui/core/strings/app_strings.dart`, `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`, `app/lib/ui/features/guest_shell/views/today_screen.dart`, `app/lib/ui/features/personal_flow/views/practice_session_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`, `app/lib/app.dart`.
- Test: `app/test/study_focus_local_test.dart`.

## Test đã chạy & phần chưa chạy

- **Đã chạy sau lần sửa cuối:** `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check`, và quét tĩnh `Select-String`.
- **Chưa chạy / giới hạn:** `where.exe flutter dart adb` không tìm thấy SDK trên host Windows hiện tại → chưa chạy `flutter analyze`, `flutter test test/study_focus_local_test.dart`, và chưa kiểm trên thiết bị Android thật (`F01–F03`, `F08`, `F09`, báo thức độc lập khi màn khóa).

## Điểm tiếp tục chính xác

1. Trên máy có Flutter SDK: chạy `cd app && flutter pub get && flutter analyze && flutter test` để xác minh biên dịch Flutter + `SF-TC-01..08` và các suite hiện có.
2. Build cài lên máy Android thật và kiểm tra `F01–F03`, `F07–F09` (khóa màn hình, rời app 5s/11s/31s, kill app/reboot, Digital Wellbeing có/không có trên OEM, TalkBack + chữ 200%, và báo thức reo khi đang học), ghi kết quả vào `tests.md` trước khi gỡ trạng thái `blocked`.
