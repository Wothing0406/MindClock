# Kế hoạch triển khai T036

- [ ] **Bước 1: Cập nhật Domain Models & Quy tắc chọn môn**
  - Mở rộng `AlarmConfig` hỗ trợ `AlarmSubjectRule` (`today_schedule`, `priority_weak`, `fixed_subject`, `none`), cập nhật `toJson`, `fromJson`, `copyWith`.
  - Giữ tương thích ngược với JSON cũ (nếu `subjectRule` vắng mặt thì suy ra từ `subjectCode`).
- [ ] **Bước 2: Xây dựng Service `MorningQuestionSelector`**
  - Định nghĩa `MorningQuestionProposal` chứa môn, tên môn, chủ đề, thời gian ước lượng, outcome, mã câu và cờ `hasApprovedQuestions`.
  - Viết logic phân giải câu hỏi theo khối lớp THPT, quy tắc chọn môn của báo thức, TKB và hồ sơ ưu tiên.
  - Viết unit test độc lập `app/test/morning_question_selector_test.dart` kiểm tra tất cả các nhánh.
- [ ] **Bước 3: Nâng cấp `AlarmConfigScreen`**
  - Cập nhật giao diện chọn môn báo thức theo 4 lựa chọn: "Theo lịch học hôm nay", "Ưu tiên môn yếu / thi", "Môn cố định", "Chỉ báo thức".
  - Hiển thị giải thích minh bạch khi môn được chọn chưa có câu duyệt.
- [ ] **Bước 4: Nâng cấp `TodayScreen`**
  - Thêm thanh chọn ngày trong tuần `_WeekdayPickerStrip` (Thứ 2 đến Chủ nhật) cho phép xem lịch và tiết học của từng ngày.
  - Thẻ "Lịch học & Chuẩn bị bài" theo ngày được chọn với danh sách tiết học, ghi chú bài tập, nút sửa tiết/nghỉ.
  - Thẻ "Báo thức tiếp theo & Câu ôn sáng": Hiển thị giờ reo, quy tắc môn, chủ đề đề xuất cho sáng mai hoặc lý do/phương án thay thế nếu môn chưa duyệt.
- [ ] **Bước 5: Kiểm thử tự động & Nghiệm thu trên Emulator**
  - Chạy `flutter analyze app` và `flutter test`.
  - Cài đặt APK lên Android Emulator `emulator-5554`, chụp ảnh màn hình các tính năng mới vào artifact.
  - Cập nhật `tests.md`, `worklog.md`, `handoff.md`.
