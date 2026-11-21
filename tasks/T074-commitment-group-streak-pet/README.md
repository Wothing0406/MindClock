# T074 — Nhóm cam kết, streak và pet Mầm

- **Trạng thái:** `in_progress`
- **Mục tiêu:** hoàn thành riêng nền nhóm kín + quyền trưởng nhóm + ledger care/EXP server và UI pet thật. Không gộp chat, media, share hoặc PvP.
- **Nguồn yêu cầu:** yêu cầu người dùng 21/11/2026 về giao diện streak, nhóm trưởng, mời/duyệt/kick, pet và share.
- **Chủ sở hữu/reviewer:** đội MindClock / backend + Flutter reviewer.
- **Phạm vi file dự kiến:** migration/model/service/routes/schema FastAPI; repository/model/view Flutter; test SQLite/PostgreSQL/widget; docs contract.
- **Liên quan:** T043 docs-only, T066/T067 progression, T070 asset pet, T073 room lifecycle. Dashboard/share là T075; phòng chờ/QR là T076; chat `@MindClock` là T077; audio/camera là T078/T079.
- **Source refs đã đọc:** `AGENTS.md`, `docs/00-start/07-quy-tac-skills-va-ai-agent.md`, `docs/01-product/{12,13,14}*.md`, `docs/02-engineering/12-lich-chung-va-ghep-phong.md`, T043/T073 handoff, code hiện tại.
- **Điểm tiếp tục:** hoàn tất và kiểm test backend T074 trước; chỉ sau đó mới chốt repository/UI và dashboard.

## Cổng trước coding

- [x] Đọc nguồn chuẩn, skill routing và code hiện tại.
- [x] Xác nhận T043 chỉ docs; repo chưa có model/API/UI nhóm pet.
- [x] Spec/plan/tests có AC ↔ TC.

## Cổng kết thúc

- [ ] AC đạt hoặc ghi rõ phần chưa đạt.
- [ ] Migration PostgreSQL + test A/B/transaction/idempotency đạt.
- [ ] Flutter UI dùng token/house pressable, chữ lớn/Reduce Motion đạt.
- [ ] Docs/API/handoff/Git được cập nhật và push riêng.
