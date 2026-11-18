# Đặc tả T049 — Bản kế hoạch nháp rule-based & Dashboard Hôm nay (ON-04, ON-05)

## Vấn đề và kết quả mong muốn

1. Hiện tại `OnboardingSetupScreen` chỉ hiện 3 dòng chữ tóm tắt tĩnh, trong đó dòng `Báo thức tự động: 06:00 mỗi sáng` mâu thuẫn trực tiếp với `ON-05` (`docs/01-product/07`: *không tự bật alarm/nhắc từ planner nếu chưa xác nhận riêng*).
2. Chưa có **mức tự đánh giá từng môn** (`Mới bắt đầu / Cơ bản / Đang ôn thi / Muốn thử thách`), chưa có **máy sinh kế hoạch nháp rule-based** (`<= 3 việc/ngày`, `10–25 phút/buổi`, nhãn rõ `Kế hoạch cơ bản · Chưa có gợi ý AI`, phân biệt môn chưa có câu duyệt), và chưa hiển thị kế hoạch đã xác nhận trên Dashboard `TodayScreen`.

## Phạm vi

- **Trong phạm vi:**
  - `DailyStudyPlan`, `DailyPlanItem`, `SubjectSelfAssessment` (`daily_study_plan.dart`) với JSON serialization.
  - `RuleBasedPlanGenerator` (`rule_based_plan_generator.dart`) sinh bản nháp có phiên bản `plannerRuleVersion = 'rule-plan-v0.1'`, `catalogVersion = 'gdpt-2018-v1'`, tối đa 3 việc hôm nay, 10–25 phút, không tự tạo alarm.
  - Cập nhật `StudyProfile` (lưu `selfAssessments` và `confirmedPlan`, tương thích ngược JSON cũ).
  - Cập nhật `OnboardingSetupScreen`: chọn mức tự đánh giá theo môn, xem trước bản nháp kế hoạch, cho phép `Xác nhận kế hoạch & Vào Hôm nay` hoặc `Bỏ qua kế hoạch · Vào Hôm nay`.
  - Cập nhật `TodayScreen`: hiển thị thẻ `Kế hoạch hôm nay` khi đã xác nhận (hoặc thẻ hướng dẫn gọn nếu bỏ qua), không ép tạo alarm.
  - Unit + widget tests (`onboarding_plan_draft_test.dart`) + kiểm chứng detached clean Git worktree.
- **Ngoài phạm vi:** Gọi Gemini sinh kế hoạch online (sẽ gắn lên trên nền `DailyStudyPlan` ở R4 sau eval), tạo báo thức tự động, thay đổi API backend.

## Yêu cầu kiểm chứng được

| ID | Liên kết | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | ON-04, ON-05 | `RuleBasedPlanGenerator` tạo bản nháp tối đa 3 việc/ngày, thời lượng mỗi việc 10–25 phút, gắn `plannerRuleVersion='rule-plan-v0.1'`, `catalogVersion='gdpt-2018-v1'`, nhãn `Kế hoạch cơ bản · Chưa có gợi ý AI`; môn chưa có ngân hàng duyệt mang cờ `hasApprovedQuestions=false` và lý do rõ | TC-01 |
| AC-02 | ON-04 | Trên `OnboardingSetupScreen`, học sinh chọn lớp 10–12, chọn môn bất kỳ (không ép 3 môn cố định), chọn mức tự đánh giá (`Mới bắt đầu / Cơ bản / Đang ôn thi / Muốn thử thách`) và thấy bản kế hoạch nháp cập nhật theo thời gian thực | TC-02 |
| AC-03 | ON-05 | Xác nhận kế hoạch trên Onboarding lưu `confirmedPlan` vào `StudyProfile`, hiển thị thẻ `Kế hoạch hôm nay` trên `TodayScreen`, và **không** tự tạo hoặc tự bật bất kỳ báo thức nào (`alarms` giữ nguyên) | TC-03 |
| AC-04 | ON-05 | Chọn `Bỏ qua kế hoạch` trên Onboarding vẫn vào được `TodayScreen` với `confirmedPlan == null`, không hiển thị kế hoạch ép buộc và không tạo báo thức tự động | TC-04 |
| AC-05 | Tương thích & Clean Clone | JSON `StudyProfile` cũ (không có `selfAssessments`/`confirmedPlan`) đọc lên an toàn; toàn bộ bộ test Flutter & `dart analyze` PASS trên cả working tree và detached clean Git worktree | TC-05 |
