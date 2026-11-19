# Kế hoạch và kết quả kiểm thử T059

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Khởi tạo `StudySpaceScreen` với profile chọn 3 môn (`Toán`, `Vật lí`, `Anh`) | Bộ chọn môn chỉ hiện đúng 3 môn này | `flutter test --no-pub -j 1` (`alarm_ai_preview_and_candle_test.dart`) | **PASS** (19/11/2026) |
| TC-02 | AC-02 | Chọn chế độ `Đốt nến · Đếm giờ tự do`, bấm Bắt đầu và mô phỏng tiến 150 phút | Timer đếm tiến vượt 120p không bị cắt (`02:30:00`), ngọn nến cập nhật + nhắc nghỉ mắt | `flutter test --no-pub -j 1` (gồm `study_focus_local_test.dart` & `alarm_ai_preview_and_candle_test.dart`) + `pytest` PG16 `62/62` | **PASS: 91/91 Flutter tests + 62/62 PG16 pytest** (19/11/2026) |
| TC-03 | AC-03 | Mở `AlarmConfigScreen` ở ngày Thứ 2 có TKB Lý -> xem câu thử thách AI gợi ý, tạo lại & fallback offline | Hiển thị câu cá nhân hóa đúng môn TKB/Profile và fallback offline khi AI lỗi | `flutter test --no-pub -j 1`; `flutter analyze --no-pub`; `RAW_HEX_COLOR_HITS=0` | **PASS** (`No issues found!`, `RAW_HEX_COLOR_HITS=0`, 19/11/2026) |
