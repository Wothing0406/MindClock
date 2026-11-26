# Biên bản bàn giao T035

- **Trạng thái:** `done`
- **Kết quả đạt được:**
  - Hoàn thiện Happy Path: Chào mừng -> Đăng ký/Đăng nhập học sinh -> Onboarding THPT 10–12 -> Xem và xác nhận kế hoạch -> Màn Hôm nay cá nhân hóa.
  - Xóa bỏ nhãn "Chế độ khách · Lưu trên máy", dọn sạch các thẻ kỹ thuật debug gây rối.
  - Bảo lưu 100% đường cứu sinh: Báo thức local, chế độ Offline và nút Dừng khẩn cấp một chạm hoạt động không phụ thuộc mạng/token.
  - Đã kiểm chứng trực quan trên Android Emulator API 37 với bộ ảnh chụp 4 bước đầy đủ (`step1_welcome.png` đến `step4_today_verified.png`).
- **Lệnh kiểm tra lại:**
  ```powershell
  flutter analyze app
  cd app; flutter test test/domain_and_persistence_test.dart
  cd app; flutter test test/android_bridge_contract_test.dart
  cd app; flutter test test/guest_flow_widget_test.dart
  cd app; flutter test test/personal_flow_real_service_test.dart
  python scripts/check_task_records.py
  python scripts/check_docs_links.py
  ```
- **Rủi ro & Giới hạn:**
  - Firebase Authentication trực tuyến cần bật provider Email/Password trong Firebase Console của dự án `mindclock` để học sinh đăng ký thật qua mạng. Trong lúc chưa bật, app tự động thông báo tiếng Việt lịch sự và có nút dùng báo thức trên máy ngay tại màn hình.
- **Điểm tiếp tục chính xác:** Mở task `T036-dashboard-multisubject-schedule`: Cải tiến màn Hôm nay để hiển thị lịch học ngày và tuần (TKB nhiều môn), thiết kế bộ chọn môn cho báo thức (Theo lịch hôm nay / Ưu tiên môn yếu / Môn cố định) và quy tắc chọn câu hỏi ôn buổi sáng.
