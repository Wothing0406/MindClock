# Bàn giao T003

- **Trạng thái cuối:** `done` ở mức tài liệu, registry metadata và skill đã cài; app/backend chưa được tạo.
- **Đã làm:** cài 5 skill Agent Sprite Forge và 2 skill Flutter vào dự án; viết docs kinh tế/RP/sprite và nguồn dữ liệu/đường nhập; cập nhật docs nguồn.
- **File/code/docs thay đổi:** docs/37, docs/38, data/sources/registry.json, 7 thư mục `.agents/skills/`, docs chuẩn liên quan, AGENTS.md và hồ sơ T003; không có app/backend hoặc corpus đã nhập.
- **Test đã chạy:** 11/11/2026: `python scripts/check_task_records.py` → OK; `git diff --check` → exit 0; JSON/registry/RP/coin assertions → OK; 7/7 skill SKILL.md → có; local Markdown links → OK. Chi tiết ở `tests.md`.
- **Test chưa chạy/giới hạn:** chưa có hai máy/app/backend để kiểm tra trận, ví, RP; cổng đó thuộc task coding sau.
- **Rủi ro còn lại:** quyền dữ liệu VNHSGE/VMLU chưa rõ, ViMMRC cần thỏa thuận; thông số sức mạnh/coin/RP chưa playtest.
- **Điểm tiếp tục chính xác:** mở docs/37 §6 và docs/38 §3–4 khi lập task backend mới; tạo task theo `tasks/README.md`, làm ví/nhân vật miễn phí rồi giao hữu hai máy trước ranked. Trước bulk import cần bằng chứng quyền từng nguồn/item và reviewer; nếu không, dùng câu đội tự viết. Trước tạo sprite thật, kiểm tra `generate2dmedia` route/chi phí và cài phụ thuộc cần thiết, rồi đo asset trên máy yếu.
