# Bàn giao T012

- **Trạng thái cuối:** `done` (chuẩn hóa ngôn từ, thiết kế và icon mức tài liệu; chưa sửa code app).
- **Đã làm:**
  - Viết [docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md](../../docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md): chốt 9 điểm nhãn từng mâu thuẫn (`Mở câu hỏi`, `Dừng khẩn cấp`, `Hoãn 5 phút`, `Chụp nháp`, `Chụp bài làm`, `Gửi bài`, `Hoàn thành không chấm`, thang `+10/+6/+2 XP`, `≥48×48 dp`); quy chuẩn giọng `vi-VN`, bảng từ cấm, tách 6 khái niệm (`XP/Hạng học tập/RP/Avatar/Khung/Uy tín`), bảng `AppStrings` đủ trạng thái, bảng token `MindClockTheme` và danh mục 17 icon + `semanticLabel`.
  - Đồng bộ [docs/13](../../docs/13-he-thiet-ke-ui.md) (bỏ trỏ nhầm `docs/37` về nhân vật/asset, thống nhất `Mở câu hỏi` / `Dừng khẩn cấp`), cập nhật ghi chú tại [docs/54](../../docs/54-kiem-ke-va-backlog-frontend.md) và [docs/README.md](../../docs/README.md).
- **File/docs thay đổi:** `docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md`, `docs/13-he-thiet-ke-ui.md`, `docs/54-kiem-ke-va-backlog-frontend.md`, `docs/README.md`, `tasks/T012-chot-ngon-tu-thiet-ke-icon-frontend/*`.
- **Test đã chạy:** `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` đều exit 0 trên Windows 11 (Python 3.11.0rc2).
- **Test chưa chạy/giới hạn:** chưa có Flutter app nên chưa đo độ tương phản pixel, TalkBack và layout `320/360/390/600 dp` + chữ `100/150/200%` trên thiết bị Android thật.
- **Rủi ro còn lại:** cần chốt nhanh 1 trong 2 bộ icon (khuyến nghị `Lucide` SVG subset ISC vs `Material Symbols Rounded`) và xác nhận licence/bundle font `Be Vietnam Pro` trước khi tạo `pubspec.yaml`.
- **Điểm tiếp tục chính xác:** sau khi cài Flutter SDK + Android SDK theo `docs/47` và xác nhận chọn `Lucide` hay `Material Symbols Rounded` + font `Be Vietnam Pro`, tạo `T013-flutter-shell-va-khach-local` cho lát cắt `FE-S01`, lấy `docs/55` làm nguồn cho `MindClockTheme` và `AppStrings`.
- **Quyết định phải xin người phụ trách:** chọn `Lucide` (SVG subset) hay `Material Symbols Rounded` cho Flutter, và xác nhận `Be Vietnam Pro` / `Noto Sans`.
