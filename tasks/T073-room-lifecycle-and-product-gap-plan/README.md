# T073 — Vòng đời phòng học và kế hoạch hoàn thiện product

- **Trạng thái:** `done`
- **Mục tiêu:** chủ phòng quản trị được thành viên và đóng/xóa phòng; mọi client bỏ room state sau khi bị kick/phòng bị xóa; có ma trận bằng chứng cho các phần product còn thiếu.
- **Nguồn yêu cầu:** yêu cầu người dùng ngày 21/11/2026 về pet, phòng học, mic/loa/camera, timer, nhắc việc, nhóm, game và kiểm thử thực.
- **Chủ sở hữu/reviewer:** đội MindClock / reviewer backend + Flutter.
- **Phạm vi file dự kiến:** `services/api/app/{routes/v1.py,services/community_service.py}`, `app/lib/{domain/services,data/repositories,ui/features/study_focus}`, test backend/Flutter, docs canonical.
- **Liên quan:** T068, T069, T070, T071, T072; không thay thế task WebRTC/media, pet ledger, lịch hẹn hay game.
- **Source refs đã đọc:** `AGENTS.md §1–5`, `docs/README.md`, `docs/00-start/01-hien-trang.md`, `docs/00-start/02-lo-trinh.md`, `docs/00-start/03-quy-trinh-vibe-code.md`, `docs/01-product/{05,08,12,13}*.md`, `docs/02-engineering/{07,09,12}*.md`, `docs/04-game/{01,04}*.md`, T068/T069 handoff và code hiện tại.
- **Điểm tiếp tục:** T074 — lịch/todo server và local notification idempotent; trước code đọc ma trận product và docs lịch nhắc.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn: mic/cam hiện chỉ là metadata; pet chỉ có art; room chưa có kick/delete.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt trong phạm vi REST lifecycle.
- [x] Các bước trong `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] Docs chuẩn/API được cập nhật.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
