# Đặc tả T036 — Dashboard Hôm nay & Cá nhân hóa nhiều môn, TKB tuần và quy tắc chọn câu ôn sáng

## 1. Bối cảnh & Vấn đề

- Màn Hôm nay hiện tại chỉ hiển thị một danh sách tĩnh các tiết của đúng ngày thứ trong tuần hiện hành (`DateTime.now().weekday`), không cho học sinh xem nhanh các ngày khác trong tuần (Thứ 2 đến Chủ nhật) để chuẩn bị bài cho ngày mai.
- Báo thức hiện tại chỉ cho chọn hoặc là "Chỉ báo thức", hoặc là một mã môn cố định cứng, không hỗ trợ logic chọn môn động theo:
  1. "Theo lịch học hôm nay" (tự động lấy theo môn của ngày có chuông);
  2. "Ưu tiên môn yếu / thi" (lấy từ mục tiêu và danh sách ưu tiên trong hồ sơ);
  3. "Môn cố định" (học sinh tự chọn);
  4. "Chỉ báo thức".
- Thiếu một service rõ ràng thực thi Quy tắc chọn câu hỏi buổi sáng (`MorningQuestionSelector`) theo tiêu chuẩn minh bạch của Bộ GD&ĐT: Lớp -> Môn -> Chủ đề yếu -> Lịch sử chưa lặp -> Câu đã duyệt -> Fallback an toàn.

## 2. Tiêu chí chấp nhận (Acceptance Criteria)

- **AC-01 (Màn Hôm nay trả lời 4 câu hỏi):**
  - Màn Hôm nay hiển thị rõ ràng:
    1. *Hôm nay học gì:* Strip chọn ngày trong tuần (T2 đến CN) với ngày được chọn có highlight; danh sách tiết học, giờ bắt đầu, tên môn, ghi chú bài tập/chuẩn bị; nút thêm/sửa tiết cho ngày đang xem.
    2. *Báo thức tiếp theo:* Hiển thị giờ reo, chế độ (Thường / Thử thách), âm thanh và quy tắc môn.
    3. *Nên ôn gì sáng mai:* Thẻ gợi ý câu ôn sáng được phân giải theo quy tắc minh bạch, kèm ước lượng thời gian (1–3 phút) và nhãn "Đã duyệt".
    4. *Không gian học:* Thẻ gợi ý phiên học tập trung theo môn cần ưu tiên trong ngày.
- **AC-02 (Cơ chế chọn môn cho báo thức `AlarmSubjectRule`):**
  - Cập nhật `AlarmConfig` hỗ trợ `subjectRule`:
    - `today_schedule`: Theo lịch học ngày reo chuông;
    - `priority_weak`: Ưu tiên môn yếu / thi từ hồ sơ;
    - `fixed_subject`: Môn cố định do người dùng chọn;
    - `none`: Chỉ báo thức.
  - Phân giải môn học thực tế an toàn khi hôm nay là ngày nghỉ hoặc chưa có tiết học.
- **AC-03 (Minh bạch khi môn chưa có câu duyệt):**
  - Khi môn được phân giải chưa có câu hỏi được duyệt trong ngân hàng (`SubjectCatalog.hasApprovedQuestions == false` như Tin học, Ngữ văn, GD KT&PL):
    - Hiển thị rõ lý do minh bạch tiếng Việt: *"Môn này chưa có câu hỏi được duyệt trong ngân hàng"*.
    - Đưa ra phương án ôn thay thế: Cho phép chọn môn đã duyệt (Toán, Tiếng Anh, Sinh học) hoặc tự động chuyển sang chế độ Báo thức thường để không khóa chuông của học sinh.
- **AC-04 (Service chọn câu hỏi sáng `MorningQuestionSelector`):**
  - Chọn câu hỏi theo đúng ma trận thứ tự ưu tiên:
    1. Khối lớp (`gradeLevel`: Lớp 10, Lớp 11, Lớp 12).
    2. Môn học (theo `AlarmSubjectRule`).
    3. Chủ đề cần cải thiện trong hồ sơ.
    4. Loại trừ câu hỏi vừa làm trong phiên gần nhất (tránh lặp câu liên tiếp).
    5. Chỉ chọn câu đã duyệt (`approved: true`).
    6. Trả về metadata minh bạch: topic, difficultyBand, estimatedMinutes, learningOutcome.
- **AC-05 (Kiểm thử & Tính tương thích ngược):**
  - Không phá vỡ các hợp đồng đã có (`guest_flow_widget_test.dart`, `domain_and_persistence_test.dart`, `android_bridge_contract_test.dart`).
  - Toàn bộ unit tests mới cho `MorningQuestionSelector` đạt 100%.
  - `flutter analyze` 0 lỗi.
