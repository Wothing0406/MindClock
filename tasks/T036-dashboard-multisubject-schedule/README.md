# T036 — Dashboard Hôm nay & Cá nhân hóa nhiều môn THPT, TKB tuần và quy tắc chọn câu ôn sáng

- **Trạng thái:** `in_progress`
- **Mục tiêu:** Cải tiến màn Hôm nay để trả lời ngay 4 câu hỏi: hôm nay học môn gì, có việc gì cần làm, báo thức tiếp theo lúc nào, nên ôn gì sáng mai. Hỗ trợ hiển thị lịch ngày và tuần (cho phép chuyển đổi xem từng ngày trong tuần Thứ 2 - Chủ nhật, sửa ngoại lệ). Bổ sung cơ chế chọn môn cho báo thức (Theo lịch hôm nay / Ưu tiên môn yếu / Môn cố định / Chỉ báo thức) và quy tắc chọn câu minh bạch.
- **Nguồn yêu cầu:** Yêu cầu sản phẩm mục 2: "Dashboard và cá nhân hóa nhiều môn" theo `docs/01-product/02-hanh-trinh-ux.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md`, `AGENTS.md §3`.
- **Chủ sở hữu/reviewer:** Senior Mobile & Backend Systems Architect.
- **Phạm vi file dự kiến:**
  - `app/lib/domain/models/alarm_config.dart`
  - `app/lib/domain/services/morning_question_selector.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`
  - `app/test/morning_question_selector_test.dart`
- **Liên quan:** T014, T015, T020, T035.
- **Source refs đã đọc:** `docs/01-product/02-hanh-trinh-ux.md §2`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md §3`, `docs/02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md`.
- **Điểm tiếp tục:** Viết spec.md, plan.md, tests.md và triển khai code.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [ ] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
