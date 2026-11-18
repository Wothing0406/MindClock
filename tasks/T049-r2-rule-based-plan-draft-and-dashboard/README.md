# T049 — R2: Bản kế hoạch nháp rule-based có xác nhận, mức tự đánh giá theo môn và Dashboard Hôm nay (ON-04, ON-05)

- **Trạng thái:** `done`
- **Mục tiêu:** Hoàn thiện chặng cuối của Bước 2 (R2 Onboarding → Xác nhận kế hoạch → Dashboard):
  1. Xây dựng mô hình & máy sinh **bản kế hoạch nháp rule-based** (`DailyStudyPlan`, `SubjectSelfAssessment`, `RuleBasedPlanGenerator` — phiên bản `rule-plan-v0.1`, `catalogVersion: gdpt-2018-v1`): tối đa 3 việc/ngày, mỗi việc 10–25 phút, gắn nhãn `Kế hoạch cơ bản · Chưa có gợi ý AI`, phân biệt rõ môn có câu duyệt vs `Chưa có câu ôn được duyệt`, và **tuyệt đối không tự tạo/bật báo thức hay thông báo**.
  2. Nâng cấp `OnboardingSetupScreen` để người học chọn **mức tự đánh giá từng môn** (`Mới bắt đầu / Cơ bản / Đang ôn thi / Muốn thử thách`), xem trước bản kế hoạch nháp cập nhật theo thời gian thực, sửa hoặc chọn `Bỏ qua kế hoạch · Vào Hôm nay` hay `Xác nhận kế hoạch & Vào Hôm nay` (bỏ dòng cứng sai quy tắc `Báo thức tự động: 06:00`).
  3. Hiển thị thẻ **Kế hoạch hôm nay (đã xác nhận)** trên Dashboard `TodayScreen`, lưu bền vững theo từng `ownerScopeKey` (tương thích ngược JSON cũ).
- **Nguồn yêu cầu:** `AGENTS.md §1, §3, §4`, `docs/00-start/02-lo-trinh.md (R2 / B06)`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md (ON-04, ON-05)`, `docs/02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md`.
- **Chủ sở hữu/reviewer:** Flutter & Product Systems Architect.
- **Phạm vi file thực tế:**
  - `app/lib/domain/models/daily_study_plan.dart` (mới)
  - `app/lib/domain/services/rule_based_plan_generator.dart` (mới)
  - `app/lib/domain/models/study_profile.dart` (sửa)
  - `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart` (sửa)
  - `app/lib/ui/features/guest_shell/views/today_screen.dart` (sửa)
  - `app/test/onboarding_plan_draft_test.dart` (mới)
  - `app/test/guest_flow_widget_test.dart` (sửa helper unfocus trước scroll)
  - `tasks/T049-r2-rule-based-plan-draft-and-dashboard/*`
- **Liên quan:** Tiếp nối trực tiếp `T048-r2-auth-onboarding-clean-clone`; giữ 100% tương thích các test hiện có và quy chuẩn `MindClockTheme`.
- **Source refs đã đọc:** `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md §Chọn lớp, môn, trình độ & §Avatar và bản kế hoạch đầu`, `docs/02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md §Lựa chọn người học & §Planner có kiểm soát`, `app/lib/domain/models/study_profile.dart`, `app/lib/ui/features/guest_shell/views/onboarding_setup_screen.dart`, `app/lib/ui/features/guest_shell/views/today_screen.dart`.
- **Điểm tiếp tục:** Bước 3 & 4 theo lộ trình: (1) bật Firebase Email/Password trên Firebase Console & kiểm 2 tài khoản thật đầu-cuối; (2) kiểm báo thức `AD01–AD09` trên 2 máy Android vật lý; (3) nâng cấp Không gian học (`Học một mình` vs `Học cùng MindClock`, `Học sâu` im lặng tuyệt đối + server EXP ledger cho thời gian học theo `T041`).

## Cổng trước coding

- [x] Đã đọc tài liệu nguồn và code hiện tại.
- [x] Đã phát hiện điểm vi phạm `ON-05` trong `onboarding_setup_screen.dart:499` (`Báo thức tự động: 06:00`) và thiếu mô hình/hiển thị kế hoạch đã xác nhận trên `TodayScreen`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-05).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường (`69/69 flutter test PASS`, `dart analyze lib test 0 issues`).
- [x] `handoff.md` nêu cách kiểm tra, giới hạn và điểm tiếp tục.
