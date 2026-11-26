# Biên bản bàn giao T036

- **Trạng thái:** `done`
- **Mã task:** `T036-dashboard-multisubject-schedule`
- **Tiêu đề:** Dashboard Hôm nay & Cá nhân hóa nhiều môn, TKB tuần và quy tắc chọn câu ôn sáng
- **Thay đổi chính:**
  1. `app/lib/domain/models/alarm_config.dart`: Bổ sung enum `AlarmSubjectRule` (`todaySchedule`, `priorityWeak`, `fixedSubject`, `none`). Tương thích ngược 100% qua JSON parser.
  2. `app/lib/domain/services/morning_question_selector.dart`: Dịch vụ phân giải câu hỏi sáng theo thứ tự minh bạch (Lớp -> Quy tắc môn -> Môn ưu tiên trong hồ sơ -> Câu hỏi đã duyệt Bộ GD&ĐT -> Tránh lặp câu liên tiếp -> Fallback an toàn).
  3. `app/lib/ui/features/guest_shell/views/alarm_config_screen.dart`: Cung cấp 4 thẻ quy tắc chọn môn và cảnh báo minh bạch khi chọn môn chưa có câu duyệt.
  4. `app/lib/ui/features/guest_shell/views/today_screen.dart`: Dải chọn ngày T2–CN, lịch tiết học theo ngày, và thẻ đề xuất câu ôn sáng minh bạch với ước lượng 1–3 phút.
  5. `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`: Nâng cấp phương thức giải thích quy tắc môn và chế độ báo thức.
- **Kiểm thử thực tế:**
  - `cd app; flutter test test/backend_integration_contract_test.dart` (9/9 PASS).
  - `cd app; flutter test test/morning_question_selector_test.dart` (6/6 PASS).
  - `cd app; flutter test test/domain_and_persistence_test.dart` (5/5 PASS).
  - `cd app; flutter test test/guest_flow_widget_test.dart` (2/2 PASS).
  - `cd app; flutter test test/android_bridge_contract_test.dart` (6/6 PASS).
  - `cd app; flutter test test/personal_flow_real_service_test.dart` (6/6 PASS).
  - `cd app; flutter test test/study_focus_local_test.dart` (7/7 PASS).
  - `services/api/tests/test_auth_jwt.py` & `pytest` (28/28 PASS).
  - Toàn bộ 41 ca kiểm Flutter `cd app; flutter test` đạt 100%.
  - `flutter analyze app` (0 issues).
  - Đã cài đặt APK và chụp màn hình trực tiếp trên Android Emulator (`screen_live_clean2.png`, `screen_live_alarm.png`, `screen_me.png`, `screen_practice.png`, `screen_study.png`): Loại bỏ triệt để các badge kỹ thuật (`[ Đã lưu local ]`, `[ OS: Đã sẵn sàng ]`, `[ Server: Chưa đồng bộ server ]`, `[ Chế độ khách ]`), thay bằng danh tính học sinh chuẩn sản phẩm (`[ Học sinh · Lớp 11 ]`).
- **Rủi ro & Ghi chú tiếp tục:**
  - Lát cắt tiếp theo là T037 (Báo thức khắt khe & Âm thanh MP3, Chuông tăng dần chỉ dừng khi "Mở câu", Dừng khẩn cấp 1 chạm) và T038 (Không gian học với hiện diện Avatar AI 2D, camera học tập tuỳ chọn, thanh công cụ tập trung).
