# T095 — Làm sạch ngôn ngữ sản phẩm, mở chế độ Hẹn giờ thường, giới hạn 1 báo thức hoàn thành/ngày và xuất APK release

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Xóa sạch toàn bộ nhãn kỹ thuật / nội bộ trên giao diện người dùng (`local`, `cục bộ`, `máy chủ`, `server`, `backend`, `offline`, `ngoại tuyến`, `GDPT 2018`, `2018`, `chuẩn quy tắc`, `study-time-v0.1`, `OS`) và rút gọn các đoạn chữ giải thích dài dòng thành ngôn ngữ ứng dụng thật, ngắn gọn, tự nhiên.
  2. Cho phép người dùng chọn rõ giữa **`Hẹn giờ thường`** (`AlarmMode.normal` — chỉ chọn giờ báo, nhãn và ngày lặp, có Hoãn 5 phút & Tắt chuông, không ép vòng tròn lịch ngủ-dậy hay câu hỏi sáng) và **`Báo thức dậy học`** (`AlarmMode.challenge` — có lịch ngủ-dậy và câu hỏi mở đầu ngày).
  3. Khóa quy tắc sản phẩm trên cả ứng dụng Flutter lẫn backend PostgreSQL: **nếu 1 ngày có nhiều báo thức thì chỉ tính tối đa 1 báo thức hoàn thành trong ngày** (không cộng EXP lần 2, không tăng số buổi hoàn thành trong ngày quá 1, và các chuông sau trong cùng ngày cho phép tắt thẳng không bắt giải lại).
  4. Sửa ký tự thừa đầu file `scripts/build_release_apk.ps1`, build kiểm chứng và xuất file APK release sản phẩm thật (`dist/apk/mindclock-android.apk`).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng kèm ảnh chụp nút `(local)`; `2026-11-27`.
- **Chủ sở hữu/reviewer:** AI Assistant / User.
- **Phạm vi file dự kiến:**
  - `app/lib/ui/core/strings/app_strings.dart`
  - `app/lib/domain/models/daily_study_plan.dart`
  - `app/lib/domain/models/alarm_occurrence.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_ring_screen.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/lib/ui/features/guest_shell/views/welcome_screen.dart`
  - `app/lib/ui/features/guest_shell/views/auth_screen.dart`
  - `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart`
  - `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/lib/ui/features/guest_shell/widgets/weekly_leaderboard_sheet.dart`
  - `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/personal_flow/views/account_auth_card.dart`
  - `app/lib/ui/features/personal_flow/views/practice_session_screen.dart`
  - `app/lib/ui/features/personal_flow/views/profile_progress_card.dart`
  - `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/lib/ui/features/study_focus/views/study_room_session_panel.dart`
  - `app/lib/ui/features/study_focus/views/study_community_sheet.dart`
  - `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/lib/ui/features/arena/views/arena_pvp_lobby.dart`
  - `services/api/app/routes/v1.py`
  - `docs/01-product/09-giac-ngu-va-bao-thuc.md`
  - `scripts/build_release_apk.ps1`
  - `app/test/t095_clean_copy_normal_alarm_and_daily_cap_test.dart` (mới)
  - `services/api/tests/test_t095_single_daily_alarm_cap.py` (mới)
- **Liên quan:** Sau `T094` (`22c23a7` / `1668df1`).
- **Source refs đã đọc:** `AGENTS.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/01-product/03-he-thiet-ke.md`, `docs/02-engineering/02-bao-thuc-android.md`.
- **Điểm tiếp tục:** Triển khai làm sạch copy, chọn loại báo thức, giới hạn 1 báo thức hoàn thành/ngày, chạy test và build APK release.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt (chỉ còn kiểm thử cài đặt trên máy Android thật khi có thiết bị kết nối).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
