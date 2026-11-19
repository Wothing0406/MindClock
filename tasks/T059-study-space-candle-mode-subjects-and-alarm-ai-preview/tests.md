# Kế hoạch và kết quả kiểm thử T059

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Khởi tạo `StudySpaceScreen` với profile chọn 3 môn (`Toán`, `Vật lí`, `Anh`) | Bộ chọn môn chỉ hiện đúng 3 môn này | `flutter test test/alarm_ai_preview_and_candle_test.dart` | Chưa chạy |
| TC-02 | AC-02 | Chọn chế độ `Đốt nến · Đếm giờ tự do`, bấm Bắt đầu và mô phỏng tiến 150 phút | Timer đếm tiến vượt 120p không bị cắt, ngọn nến cập nhật trực quan | `flutter test test/study_focus_local_test.dart test/alarm_ai_preview_and_candle_test.dart` | Chưa chạy |
| TC-03 | AC-03 | Mở `AlarmConfigScreen` ở ngày Thứ 2 có TKB Lý -> bấm xem câu thử thách AI gợi ý | Hiển thị câu cá nhân hóa đúng môn TKB/Profile hoặc fallback offline rõ ràng | `flutter test test/alarm_ai_preview_and_candle_test.dart` | Chưa chạy |
