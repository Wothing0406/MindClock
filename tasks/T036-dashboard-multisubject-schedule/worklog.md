# Nhật ký công việc T036

## 2026-11-16
- **Khởi động lát cắt T036:** Bổ sung hỗ trợ đa môn, thời khóa biểu tuần và quy tắc chọn câu hỏi buổi sáng minh bạch theo yêu cầu sản phẩm.
- **Mở rộng `AlarmConfig`:**
  - Bổ sung enum `AlarmSubjectRule` (`todaySchedule`, `priorityWeak`, `fixedSubject`, `none`).
  - Cập nhật serialization JSON và `copyWith` đảm bảo tương thích ngược 100%.
- **Hiện thực `MorningQuestionSelector`:**
  - Tạo `app/lib/domain/services/morning_question_selector.dart`.
  - Phân giải câu hỏi sáng theo thứ tự ưu tiên: Khối lớp THPT (10, 11, 12) -> Quy tắc môn của báo thức -> Môn trọng tâm trong hồ sơ -> Ngân hàng câu hỏi đã duyệt -> Tránh lặp câu hôm qua -> Fallback an toàn.
  - Viết 6 ca kiểm thử độc lập trong `app/test/morning_question_selector_test.dart` (Đạt 6/6).
- **Cập nhật `AlarmConfigScreen`:**
  - Cung cấp 4 thẻ quy tắc chọn môn ôn sáng: "Theo lịch học hôm nay" (`alarm-rule-today-schedule`), "Ưu tiên môn yếu / thi" (`alarm-rule-priority-weak`), "Môn cố định" (`alarm-rule-fixed-subject`), "Chỉ báo thức" (`alarm-rule-none`).
  - Khi chọn môn cố định chưa có câu duyệt: hiển thị biểu ngữ thông báo minh bạch tiếng Việt, giải thích chuông sẽ reo bình thường không làm kẹt học sinh.
- **Nâng cấp `TodayScreen`:**
  - Chuyển `TodayScreen` sang StatefulWidget với dải chọn ngày trong tuần (T2 đến CN).
  - Tự động highlight ngày được chọn và chấm đánh dấu "Hôm nay".
  - Hiển thị danh sách tiết học kèm ghi chú ôn tập / chuẩn bị bài cho từng tiết.
  - Hiển thị thẻ "Câu ôn sáng theo quy tắc": phân giải theo `MorningQuestionProposal`, hiển thị môn học, chủ đề, thời gian ước lượng (1-3 phút), nhãn Đã duyệt / Chưa có câu duyệt, lý do phân giải minh bạch và câu hỏi mẫu.
- **Kiểm thử hồi quy:**
  - `flutter analyze app`: 0 issue.
  - `morning_question_selector_test.dart`: 6/6 PASS.
  - `domain_and_persistence_test.dart`: 5/5 PASS.
  - `android_bridge_contract_test.dart`: 6/6 PASS.
  - `guest_flow_widget_test.dart`: 2/2 PASS.
  - `personal_flow_real_service_test.dart`: 6/6 PASS.
