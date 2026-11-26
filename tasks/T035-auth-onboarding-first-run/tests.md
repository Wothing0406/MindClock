# Kế hoạch kiểm thử & Kết quả thực tế T035

- **Môi trường chạy:**
  - Android Emulator: `Medium Phone API 37.0` (x86_64, Android 16 / VanillaIceCream), kết nối qua adb port `5554`.
  - Flutter SDK 3.29.0 / Dart 3.7.0 trên Windows 11.
  - Backend: PostgreSQL 16 Docker container (`api-postgres-1`) trên port 5432, FastAPI server trên port 8000.
  - Firebase: Project ID `mindclock` (BOM 33.7.0, Google Services 4.4.2).

---

## 1. Ma trận Ca kiểm thử & Kết quả

| Mã TC | Mô tả ca kiểm | Điều kiện chấp nhận | Kết quả thực tế | Môi trường / Ngày |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Kiểm tra màn Chào mừng mới | Có nút chính "Bắt đầu ngay (Đăng ký / Đăng nhập)", các nút phụ "Dùng thử không cần tài khoản", "Chỉ báo thức (Offline)", "Để sau". Bố cục vừa vặn trên 360x780dp. | **ĐẠT** (`step1_welcome.png`) | Emulator-5554 / 2026-11-16 |
| **TC-02** | Chuyển sang màn Đăng ký / Đăng nhập | Chạm "Bắt đầu ngay" mở `AuthScreen` với đầy đủ trường: Biệt danh, Email, Mật khẩu, Xác nhận mật khẩu. | **ĐẠT** (`step2_auth.png`) | Emulator-5554 / 2026-11-16 |
| **TC-03** | Validation và xử lý lỗi tài khoản | Mật khẩu không khớp hoặc email sai định dạng chặn submit ngay tại client; lỗi xác thực hiển thị thông báo tiếng Việt rõ ràng, có nút dùng offline. | **ĐẠT** (`step2_auth_filled.png`) | Emulator-5554 / 2026-11-16 |
| **TC-04** | Thiết lập Onboarding THPT Lớp 10–12 | Chọn Avatar vector (Bình minh, Sách vở, Kỷ luật, Học sinh), chọn khối lớp 10, 11, 12, chọn môn học theo tổ hợp Bộ GD&ĐT. | **ĐẠT** (`step3_onboarding_setup.png`) | Emulator-5554 / 2026-11-16 |
| **TC-05** | Thẻ xem và xác nhận kế hoạch | Hiển thị thẻ tóm tắt "Kế hoạch đề xuất của bạn" với lớp, số môn và giờ báo thức đề xuất trước khi lưu. | **ĐẠT** (`step3_onboarding_scrolled.png`) | Emulator-5554 / 2026-11-16 |
| **TC-06** | Vào Hôm nay với danh tính học sinh | Màn Hôm nay xóa bỏ badge "Chế độ khách · Lưu trên máy", hiển thị danh tính học sinh (`Minh Khang · Lớp 11` hoặc `Báo thức trên máy`), thẻ đặt báo thức đầu tiên, TKB và không gian học. | **ĐẠT** (`step4_today_verified.png`) | Emulator-5554 / 2026-11-16 |
| **TC-07** | Phân tích mã nguồn tĩnh (Static Analysis) | `flutter analyze app` không có bất kỳ lỗi hoặc cảnh báo nào. | **ĐẠT** (0 issues found, 2.8s) | Windows / 2026-11-16 |
| **TC-08** | Unit & Persistence Tests | `flutter test test/domain_and_persistence_test.dart`: Công thức tính giờ dậy, khôi phục cấu hình báo thức, lưu mã môn chuẩn. | **ĐẠT** (5/5 tests passed) | Windows / 2026-11-16 |
| **TC-09** | Android MethodChannel Native Bridge | `flutter test test/android_bridge_contract_test.dart`: Hợp đồng v1, xử lý quyền Exact Alarm, Notification, Full-screen intent, phản hồi từ OS. | **ĐẠT** (6/6 tests passed) | Windows / 2026-11-16 |
| **TC-10** | Widget Flow & Khôi phục dữ liệu | `flutter test test/guest_flow_widget_test.dart`: Toàn bộ luồng onboarding, responsive 320dp 200% text scale (AC-08). | **ĐẠT** (2/2 tests passed) | Windows / 2026-11-16 |
| **TC-11** | Personal Flow Real Service Contract | `flutter test test/personal_flow_real_service_test.dart`: Token refresh, bảo vệ báo thức local, cô lập dữ liệu 2 tài khoản, không upload camera khi hủy. | **ĐẠT** (6/6 tests passed) | Windows / 2026-11-16 |
| **TC-12** | Tính toàn vẹn văn bản & task records | `python scripts/check_task_records.py` & `python scripts/check_docs_links.py`. | **ĐẠT** (Task records OK, 417 docs links PASS) | Windows / 2026-11-16 |
