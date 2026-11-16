# T033 — B03/B05: Hợp đồng MorningCard mở màn, Bỏ lượt ở lần sai rõ thứ 5 và EduSkills-VN adapter

- **Trạng thái:** `done`
- **Mục tiêu:** Triển khai trọn vẹn lát cắt dọc `B03`/`B05` (`P-03`, `P-06`, `P-07`) nối FastAPI `/v1` và Flutter Android: (1) adapter `EduSkills-VN` với 4 chế độ prompt `AUTHOR_DRAFT`, `GRADE_CANDIDATE`, `HINT_ONE_STEP`, `POST_ATTEMPT_EXPLAIN` kèm kiểm định chống lộ đáp án, (2) `MorningCard` gắn cùng `questionId` + `questionRevision` + `learningOutcome` với fallback chữ tĩnh và nút `Bỏ qua mở màn` (chỉ bỏ cảnh, vẫn phải làm câu để hoàn thành), (3) theo dõi `confirmedIncorrectCount` ở server, mở hint từ lần sai rõ thứ 3, mở `canAbandon = true` và route `POST /v1/sessions/{id}/abandon` từ lần sai rõ thứ 5 (không cộng EXP/chuỗi, trả `revealVi` hậu lượt; `uncertain` không tăng sai).
- **Nguồn yêu cầu:** Yêu cầu người dùng ngày 16/11/2026; `AGENTS.md §3`; `docs/00-start/05-goi-task-dau-tien.md` (B03, B05); `docs/01-product/09-giac-ngu-va-bao-thuc.md` (`MORNING-01..03`); `docs/02-engineering/04-hop-dong-api.md §3`; `docs/02-engineering/11-eduskills-vn-tich-hop.md`.
- **Chủ sở hữu/reviewer:** AI Coding Agent.
- **Phạm vi file dự kiến:** `services/api/app/services/eduskills_adapter.py`, `services/api/app/db/seed.py`, `services/api/app/routes/v1.py`, `services/api/tests/test_api_v1.py`, `app/lib/domain/models/personal_flow_models.dart`, `app/lib/domain/services/personal_flow_repository.dart`, `app/lib/data/repositories/remote_personal_flow_repository.dart`, `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`, `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`, `app/lib/ui/features/personal_flow/views/practice_session_screen.dart`, `docs/02-engineering/04-hop-dong-api.md`, `docs/02-engineering/11-eduskills-vn-tich-hop.md`, `docs/03-quality/03-truy-vet-yeu-cau.md`, `tasks/T033-b03-morning-card-and-abandon-flow/*`.
- **Liên quan:** Tiếp nối `T029`–`T032`.
- **Source refs đã đọc:** `AGENTS.md §3, §5`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/04-hop-dong-api.md`, `docs/02-engineering/11-eduskills-vn-tich-hop.md`, `docs/03-quality/03-truy-vet-yeu-cau.md`.
- **Điểm tiếp tục:** Chuyển sang `B06` (Catalog chương trình THPT lớp 10–12 + Onboarding planner có xác nhận) và kiểm thử E2E trên máy Android thật khi có thiết bị.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
