# T082 — Đồng Bộ Toàn Bộ Giao Diện Về Phong Cách Gốc "Bình Minh Trên Trang Vở" & Cải Tạo Không Gian Học

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Xóa bỏ các khối nền tối (`mc.night` / `mc.nightSurface`) đang gây lệch màu ("đang trắng tự dưng đen thui") ở `TodayScreen`, `AlarmConfigScreen`, `CircularSleepClockPicker`, `CommitmentGroupScreen`, `FloatingMiniPetOverlay`, `WelcomeScreen`, `MindClockShellScreen`, `StudySpaceScreen` — chỉ giữ `mc.night` cho màn chuông reo `AlarmRingScreen` theo đúng `docs/01-product/03-he-thiet-ke.md`.
  2. Nâng cấp Không gian học (`StudySpaceScreen`) với 3 trụ cột khác biệt ChatGPT & Google Meet: Micro-Check tỉnh táo cuối chặng, Gia sư Socratic khóa giải hộ từng bước, và Bàn học nhóm giữ Chuỗi chung.
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `app/lib/ui/features/guest_shell/views/{today_screen.dart,alarm_config_screen.dart,welcome_screen.dart,mindclock_shell_screen.dart}`
  - `app/lib/ui/features/guest_shell/widgets/circular_sleep_clock_picker.dart`
  - `app/lib/ui/features/community/views/{commitment_group_screen.dart,floating_mini_pet_overlay.dart}`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
- **Liên quan:** Kế thừa `T080`, `T081`.
- **Source refs đã đọc:** `docs/01-product/03-he-thiet-ke.md`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`.
- **Điểm tiếp tục:** Sửa toàn bộ khối `mc.night` ngoài màn chuông reo về `mc.surface` / `mc.paper` / `mc.primarySoft`.

## Cổng trước coding

- [x] Đã rà toàn bộ `mc.night` / `nightSurface` trong `app/lib/ui/`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và test xanh.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
