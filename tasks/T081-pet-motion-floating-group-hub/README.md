# T081 — Pet Streak Cử Động, Floating Mini Pet Nổi, Dashboard Gọn & Màn Hình Nhóm Chuyên Biệt

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thêm chuyển động liên tục (idle thở/nhún nhẹ, happy nhảy vui, tôn trọng Reduce Motion) cho `MamPetView`.
  2. Tạo `FloatingMiniPetOverlay` thu nhỏ Pet Streak thành bong bóng nổi kéo thả trên `MindClockShellScreen`, hiện `Chuỗi N` + `X/Y`, chạm vào mở nhanh popup Chuỗi/Báo cáo hoặc vào Màn hình Nhóm.
  3. Tạo `CommitmentGroupScreen` (màn hình Nhóm chuyên biệt theo phong cách "bình minh trên trang vở" + Hero Card `night` `#101A30` nổi bật tối đa 3 nhóm chuỗi, copy mã 1 chạm, modal Tạo nhóm / Nhập mã tách gọn).
  4. Thu gọn `TodayScreen` (Dashboard) bỏ thẻ dài rối mắt, ưu tiên Đồng hồ + Báo thức kế tiếp + Lưới 6 tính năng MVP.
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026` (sau `/grill-me`).
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `app/lib/ui/core/widgets/mam_pet_view.dart`
  - `app/lib/ui/features/community/views/{commitment_group_screen.dart,floating_mini_pet_overlay.dart,commitment_group_sheet.dart}`
  - `app/lib/ui/features/guest_shell/views/{today_screen.dart,mindclock_shell_screen.dart}`
  - `app/test/t081_pet_motion_and_group_hub_test.dart`
- **Liên quan:** Kế thừa `T075`, `T077`, `T079`.
- **Source refs đã đọc:** `docs/01-product/03-he-thiet-ke.md`, `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, `app/lib/ui/core/widgets/mam_pet_view.dart`, `app/lib/ui/features/guest_shell/views/today_screen.dart`.
- **Điểm tiếp tục:** Nâng cấp `MamPetView` có animation cử động.

## Cổng trước coding

- [x] Đã đọc `docs/01-product/03-he-thiet-ke.md` và `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và test xanh.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
