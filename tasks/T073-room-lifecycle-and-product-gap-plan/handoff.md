# Bàn giao nhiệm vụ

- **Trạng thái cuối:** `done`; AC T073 đạt và source commit đã có trên remote.
- **Đã làm:** host kick member, chặn tự rejoin, host hard-delete room/cascade members, Flutter clear state và UI xác nhận; ma trận T074–T084 tách rõ phần chưa có.
- **File/code/docs thay đổi:** community service/routes; API client/repository/VM/panel/grid; test SQLite/PostgreSQL/Flutter; docs hiện trạng/API/realtime/product plan; hồ sơ T073.
- **Test đã chạy:** Flutter 13 PASS, analyze sạch; API SQLite 3 PASS; PostgreSQL thật 3 PASS trên database tạm; docs 654 link PASS, task records OK. Chi tiết ở `tests.md`.
- **Test chưa chạy/giới hạn:** không APK/máy thật và không media nhiều máy; mic/cam/loa vẫn unavailable đúng UI.
- **Rủi ro còn lại:** hard delete chưa có audit moderation vì chat/report room chưa mở; media, lịch hẹn, pet ledger, game là T074–T084.
- **Điểm tiếp tục chính xác:** mở T074 từ `_template`, đọc `docs/01-product/05-lich-hoc-nhac-viec.md` và `docs/00-start/08-ke-hoach-hoan-thien-product.md`; đặc tả task/event owner, recurrence, timezone, quiet hours và hủy notification cũ trước code.
- **Git:** nhánh `main`, source commit `113c16115e924e0e9eec157eed7a0584e1147f61`; đã push và `git ls-remote origin refs/heads/main` trả đúng SHA ngày 21/11/2026. Commit metadata bàn giao đi sau; không stage WIP game, Firebase JSON, asset research hoặc docs formatting ngoài hunk T073.
- **Quyết định phải xin người phụ trách:** không có trong lát T073.
