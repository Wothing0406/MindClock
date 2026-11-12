# T010 — Hồ sơ, huy hiệu hạng và nội dung người dùng

- **Trạng thái:** `verifying`
- **Mục tiêu:** hồ sơ và dữ liệu hiển thị được đặc tả đầy đủ; asset huy hiệu riêng với khung avatar; web demo xem thử tải avatar cục bộ; README mô tả đủ sản phẩm.
- **Nguồn yêu cầu:** tin nhắn người dùng ngày 12/11/2026 về avatar tải lên, rank badge, profile, lịch sử, uy tín, ngôn từ và README.
- **Chủ sở hữu/reviewer:** agent thực hiện / chủ dự án duyệt.
- **Phạm vi file:** `docs/52*`, `docs/53*`, `docs/README.md`, `docs/24`, `docs/25`, `docs/43`, `README.md`, `demo/arena.*`, `demo/assets/game/ui/rank/`, `scripts/build_rank_badges.py`, test.
- **Liên quan:** T009 arena và docs/46.
- **Source refs đã đọc:** `docs/24 §1–4`, `docs/25 §1–5`, `docs/21 §1–3`, `docs/43 khung rank`, `docs/44 §4`, `docs/46 §1–4`, `AGENTS.md`, `tasks/README.md`.
- **Điểm tiếp tục:** theo `handoff.md`: kiểm file picker/badge trên Android; API/moderation là task sau, không coi bản preview là upload thật.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Mâu thuẫn: docs/43 chỉ có khung, thiếu badge; profile upload chưa có hợp đồng. Bổ sung docs/52–53, không tuyên bố backend đã chạy.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance asset/docs/rule local đạt; phần browser/backend chưa đạt ghi rõ.
- [x] Plan/tests cập nhật kết quả thật.
- [x] Docs chuẩn/API/schema dự kiến cập nhật.
- [x] Handoff có điểm tiếp tục.
