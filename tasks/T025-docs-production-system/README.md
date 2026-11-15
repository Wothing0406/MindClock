# T025 — Bộ tài liệu production cho vibe coding

- **Trạng thái:** `done` (chỉ task tài liệu; không phải trạng thái app production)
- **Mục tiêu:** thay bộ docs đánh số, chồng chéo bằng một cây tài liệu nguồn chuẩn từ product đến release; giữ lịch sử ở archive và định tuyến AI coding rõ ràng.
- **Nguồn yêu cầu:** người dùng ngày 15/11/2026, yêu cầu làm lại docs từ đầu đến cuối.
- **Chủ sở hữu/reviewer:** Codex / chủ dự án.
- **Phạm vi:** `docs/`, `AGENTS.md`, `README.md`, skill Android nội bộ, `scripts/check_docs_links.py`, task này. Không đổi mã app/API đang làm dở.
- **Source refs:** `docs/README.md`, docs/04/06/07/09/14/25/28/31/34/39/45/46/47/56/57, `tasks/README.md`, `app/`, `services/api/`.
- **Liên quan:** T024 rebaseline; WIP T022/T023 được giữ nguyên.
- **Điểm tiếp tục:** mở [gói task đầu tiên](../../docs/00-start/05-goi-task-dau-tien.md) theo B01a/B01b/B01c; đối chiếu [quyết định còn mở](../../docs/00-start/06-quyet-dinh-va-gia-dinh.md) trước pilot/game.

## Cổng trước thay đổi

- [x] Đã xem trạng thái Git, index và quy trình task.
- [x] Đã xác định docs hiện tại 58 file đánh số + một docs WIP, chồng chéo trạng thái và nguồn chuẩn.
- [x] Spec/plan/tests được ghi trước khi di chuyển/chỉnh script.

## Cổng kết thúc

- [x] Cây docs và nguồn chuẩn đúng AC.
- [x] Test link/archive/traceability/task records đạt, giới hạn ghi trong `tests.md`.
- [x] Handoff có điểm tiếp tục cụ thể.
