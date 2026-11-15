# Nhật ký T025

| Vòng | Quan sát | Quyết định | Test lại |
| --- | --- | --- | --- |
| 1 / 15-11-2026 | 58 file docs đánh số ở root và docs WIP, nhiều nguồn chuẩn/ưu tiên đan xen. | Viết docs canonical theo vòng đời sản phẩm, chuyển tài liệu cũ nguyên nội dung vào archive, kiểm link đệ quy. | Chờ TC-01–04. |
| 2 / 15-11-2026 | Ma trận truy vết cũ gán P-04–P-08 sai chức năng; index thiếu phần lịch/hồ sơ và cổng quyết định. | Sửa truy vết theo PRD, thêm P-11/P-12 + PLAN/PROFILE test và sổ quyết định. | Link checker 248 file, task checker, regression checker pass. |
| 3 / 15-11-2026 | `git diff --check` toàn repo báo trailing whitespace ở `services/api/app/demo_ui.py` WIP không thuộc T025. | Giữ nguyên code WIP; kiểm/stage đúng phạm vi docs. | Chờ `git diff --cached --check` sau stage. |
| 4 / 15-11-2026 | Skill Android nội bộ còn link tới docs root đã chuyển. | Sửa skill và mở link checker tới `.agents/skills/**/*.md`. | 338 Markdown pass; staged docs check pass. |
