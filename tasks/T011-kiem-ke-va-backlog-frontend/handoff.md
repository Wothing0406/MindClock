# Bàn giao T011

- **Trạng thái cuối:** `done` (hoàn thành kiểm kê & backlog frontend mức tài liệu; **chưa sửa code, chưa có app Flutter/APK chạy thật**).
- **Đã làm:**
  - Đọc đầy đủ `AGENTS.md`, `docs/README.md`, `tasks/README.md`, `docs/04, 05, 07, 08, 09, 13, 16, 22, 23, 24, 27, 29, 30, 31, 32, 39, 41, 42, 45, 46, 47, 48, 49, 51, 52, 53`, handoff `T009` và `T010`, `demo/index.html`, `demo/arena*`, `demo/profile-rules.js`, `demo/assets/game/manifest.json` và `audio/manifest.json`.
  - Xuất bản kiểm kê & backlog frontend tại [docs/54-kiem-ke-va-backlog-frontend.md](../../docs/54-kiem-ke-va-backlog-frontend.md) gồm 5 mục: (1) bảng màn hình đầy đủ, (2) 3 phạm vi tách bạch, (3) component Flutter dùng chung & kiểm kê tái sử dụng asset `demo/assets/game/`, (4) backlog 9 lát cắt dọc `FE-S01..FE-S09` với AC (EARS) ↔ test, (5) 9 mâu thuẫn tài liệu/prototype và 3 nhóm quyết định còn thiếu.
  - Cập nhật chỉ mục [docs/README.md](../../docs/README.md) để liên kết `docs/54`.
- **File/docs thay đổi:** `docs/54-kiem-ke-va-backlog-frontend.md`, `docs/README.md`, `tasks/T011-kiem-ke-va-backlog-frontend/*`. Không chỉnh sửa `demo/` hay tạo code ứng dụng.
- **Test đã chạy:** xem [tests.md](tests.md); `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` đều exit 0 trên Windows 11 (Python 3.11.0rc2) ngày 14/11/2026.
- **Test chưa chạy/giới hạn:** chưa có APK/app Flutter, chưa có `flutter`/`adb` trong PATH nên chưa kiểm runtime `320/360/390/600 dp`, chữ `100/150/200%`, báo thức Android `AD01–AD09` hay Chrome Android cho `T009/T010`.
- **Rủi ro còn lại:** chưa chốt licence/bundle font `Be Vietnam Pro`, bộ icon SVG thống nhất, quyền thương mại sprite `demo/assets/game/characters/*`, quy chế DevFest và ngưỡng tuổi/đồng ý phụ huynh.
- **Điểm tiếp tục chính xác:**
  1. Cài đặt Flutter SDK + Android Studio/Platform Tools và kết nối máy Android thật theo `docs/47` (`flutter doctor -v`, `adb devices`).
  2. Chốt nhanh các điểm ở `docs/54 §5` (font, icon set, `Hàn Bối Tháp` vs `Hàn Bối Pháp`, đồng bộ nhãn `Mở câu hỏi`/`Dừng khẩn cấp`).
  3. Tạo task `T012-flutter-shell-va-khach-local` từ `tasks/_template/` cho lát cắt `FE-S01` (ưu tiên `khách → đặt chuông → reo → câu hỏi → nhập bài → phản hồi → Hôm nay`, ẩn `Đấu trường` theo cohort flag).
- **Quyết định phải xin người phụ trách:** chốt tên thống nhất nhân vật 2 (`Hàn Bối Tháp` hay `Hàn Bối Pháp`), phạm vi dùng asset `demo/assets/game/` ở bản phát hành, quy chế DevFest và quy trình đồng ý độ tuổi trước pilot.
