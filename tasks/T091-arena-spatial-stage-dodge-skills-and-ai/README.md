# T091 — Nâng cấp sân đấu 2D không gian, né chiêu, nút skill gọn, bản đồ ngẫu nhiên và AI sinh câu theo hồ sơ

- **Trạng thái:** `verifying`
- **Mục tiêu:** Biến Đấu trường Luyện đơn thành sân đấu 2D không gian dọc có vị trí/làn chiến đấu rõ ràng, đòn đánh nhắm đúng vị trí mục tiêu kèm hiệu ứng trúng đòn đúng phía, hành động né chiêu thay đổi kết quả sát thương, nút chiêu dùng icon kỹ năng (`assets/arena/skill_*.png`), bản đồ `Ngẫu nhiên` chốt trước trận, và nguồn câu hỏi có kiểm soát theo đúng lớp của hồ sơ.
- **Nguồn yêu cầu:** Phản hồi trực tiếp của người dùng (lượt 9–11) và yêu cầu hoàn tất `T091` kèm báo cáo Quyết định Unity; `2026-11-27`.
- **Chủ sở hữu/reviewer:** AI Assistant / User.
- **Phạm vi file dự kiến:**
  - `services/api/app/routes/v1.py`
  - `app/lib/domain/models/study_ai_models.dart`
  - `app/lib/domain/game/solo_training_question_bank.dart`
  - `app/lib/ui/features/arena/view_models/solo_arena_view_model.dart`
  - `app/lib/ui/features/arena/views/arena_stage_widget.dart`
  - `app/lib/ui/features/arena/views/arena_skill_hand.dart`
  - `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/test/t091_arena_spatial_dodge_and_ai_test.dart`
- **Liên quan:** Kế thừa `T086`, `T087`, `T088` trên nhánh `main`.
- **Source refs đã đọc:** `AGENTS.md §3-5`, `docs/README.md`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/03-quy-trinh-vibe-code.md`, `docs/01-product/03-he-thiet-ke.md`, `docs/04-game/01-pvp-gdd.md`, `app/lib/ui/core/theme/mindclock_theme.dart`.
- **Điểm tiếp tục:** Đã pass toàn bộ analyze + widget/unit/API tests; giữ `verifying` chờ kiểm chứng trực quan trên thiết bị Android vật lý. Chuyển sang task tiếp theo (`T092`) về trạng thái occurrence của báo thức và dọn dẹp dashboard.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt trên môi trường dev/widget/API; ghi rõ phần cần máy Android thật.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
