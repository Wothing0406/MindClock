# Kế hoạch kiểm thử & Kết quả T036

## Ma trận Ca kiểm thử

| Mã TC | Mục tiêu kiểm thử | Điều kiện chấp nhận | Kết quả thực tế | Môi trường / Ngày |
| :--- | :--- | :--- | :--- | :--- |
| **MQS-01** | `MorningQuestionSelector`: Báo thức theo lịch hôm nay | Thứ 2 tiết đầu lúc 07:00 Tiếng Anh -> đề xuất câu Tiếng Anh, ước lượng 1p, nhãn Đã duyệt. | **ĐẠT** (`test/morning_question_selector_test.dart`) | Local Dart test / 2026-11-16 |
| **MQS-02** | `MorningQuestionSelector`: Ngày nghỉ fallback an toàn | Hôm nay là Chủ nhật (nghỉ) -> fallback sang môn ưu tiên cao nhất trong hồ sơ (Toán). | **ĐẠT** (`test/morning_question_selector_test.dart`) | Local Dart test / 2026-11-16 |
| **MQS-03** | `MorningQuestionSelector`: Báo thức ưu tiên môn yếu | Chọn rule priorityWeak -> đề xuất câu Toán Tính đơn điệu của hàm số. | **ĐẠT** (`test/morning_question_selector_test.dart`) | Local Dart test / 2026-11-16 |
| **MQS-04** | `MorningQuestionSelector`: Môn chưa có câu duyệt | Chọn Vật lí/Tin học -> proposal báo rõ `hasApprovedQuestions = false` kèm giải thích tiếng Việt minh bạch và gợi ý môn Toán đã duyệt. | **ĐẠT** (`test/morning_question_selector_test.dart`) | Local Dart test / 2026-11-16 |
| **MQS-05** | `MorningQuestionSelector`: Tránh lặp câu liên tiếp | Không đề xuất lại câu hỏi vừa làm trong phiên hôm qua (`mc-math-12-001` -> `mc-math-12-002`). | **ĐẠT** (`test/morning_question_selector_test.dart`) | Local Dart test / 2026-11-16 |
| **TC-DSH-01** | `TodayScreen`: Chuyển đổi ngày trong tuần | Dải chọn T2 đến CN: chọn ngày nào chuyển đúng lịch và việc cần chuẩn bị của ngày đó. | **ĐẠT** (Widget code & verification) | Local / Emulator-5554 |
| **TC-DSH-02** | `TodayScreen`: Thẻ ôn tập sáng minh bạch | Hiển thị câu ôn đề xuất kèm lý do minh bạch, đề mẫu, thời gian 1-3p, badge Đã duyệt. | **ĐẠT** (Widget code & verification) | Local / Emulator-5554 |
| **TC-CFG-01** | `AlarmConfigScreen`: 4 lựa chọn quy tắc môn | Hiển thị 4 lựa chọn: Theo lịch học hôm nay, Ưu tiên môn yếu, Môn cố định, Chỉ báo thức; lưu và khôi phục đúng JSON. | **ĐẠT** (`alarm_config_screen.dart`) | Local / Emulator-5554 |
| **TC-REG-01** | Kiểm tra hồi quy toàn bộ app | `flutter analyze app` 0 lỗi; `guest_flow_widget_test.dart` (2/2 PASS), `domain_and_persistence_test.dart` (5/5 PASS), `android_bridge_contract_test.dart` (6/6 PASS). | **ĐẠT** (Toàn bộ pass 100%) | Windows 11 / 2026-11-16 |
