# Worklog T004

- 11/11/2026: Đọc nguồn chuẩn/tài liệu liên quan; xác minh VNHSGE, VMLU, ViMMRC từ trang nguồn. VNHSGE không có giấy phép dữ liệu rõ; VMLU repo ghi `TBU`, mirror bên thứ ba; ViMMRC cần thỏa thuận.
- Tạo task trước thay đổi dữ liệu/cấu hình. Tải 406 JSON VNHSGE bằng sparse checkout, 3 JSONL mirror VMLU vào `data/research/raw/` gitignored; không tải ảnh/Word. Inventory đọc 17.054/10.880 mục; nhận ra 9.833 mục test VMLU thiếu answer.
- Viết docs/39 (trình bày/chấm/adaptive), docs/40 (PvP/roster/map/FX), cập nhật docs nguồn, API, AI, SQL, UX báo thức, test và registry. Quyết định: ranked chấm sau nộp chỉ sau cổng người chấm; speed bonus tắt mode viết; stun chỉ khóa thẻ riêng.
- Vòng kiểm tra 1: `git diff --check` báo một dòng trống EOF docs/37; đã chuẩn hóa newline và chạy lại pass. `check_task_records.py` báo thiếu worklog/handoff; đã tạo, chạy lại với UTF-8 vì PowerShell session cp1252 không in được lỗi tiếng Việt.
