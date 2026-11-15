# Bàn giao T026

- **Trạng thái:** `done` cho docs, không phải sản phẩm đã phát hành.
- **Đã làm:** PRD/hành trình và tài liệu chuyên đề đăng ký, catalog THPT, lịch ngủ/báo thức, phòng học AI/bạn, động lực; đồng bộ SQL/API/AI/PvP/privacy/test/roadmap; cập nhật index, AGENTS, skill Android và README.
- **Kiểm:** TC-01–05 PASS (review tài liệu); `python scripts/check_docs_links.py` PASS 351 file; `python scripts/check_task_records.py` PASS; `git diff --check` PASS. Không chạy Android/Firebase/PostgreSQL/Gemini thật trong task này.
- **Quyết định còn mở:** chủ sản phẩm/reviewer xác nhận catalog và ngân hàng câu từng lớp; chính sách tuổi/consent, quyền asset, ngưỡng chấm AI trước pilot, ngân sách Gemini Live, thiết bị Android/OEM mục tiêu; xem [decision ledger](../../docs/00-start/06-quyet-dinh-va-gia-dinh.md).
- **Điểm tiếp tục:** B01a/B01b/B01c trong [backlog](../../docs/00-start/05-goi-task-dau-tien.md), sau đó B02 alarm máy thật. Đọc handoff T022/T023 trước chạm WIP runtime. Mỗi gói tạo task mới với AC/test; không kết luận production từ tài liệu.
