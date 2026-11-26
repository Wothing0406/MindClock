# Nhật ký làm việc T035

- **2026-11-16 20:15**: Nhận phản hồi thực tế từ người dùng sau khi chạy app trên Android Emulator: Màn Hôm nay còn gắn mác 'chế độ khách/local', thiếu báo thức, giao diện nhỏ nhiều thẻ kỹ thuật.
- **2026-11-16 20:25**: Rà soát codebase đối chiếu 6 hành trình cốt lõi và lập Bảng kiểm khoảng cách (Gap Audit). Tạo task `T035-auth-onboarding-first-run` với `README.md`, `spec.md`, `plan.md`, `tests.md`, `worklog.md`, `handoff.md`.
- **2026-11-16 20:35**: Bổ sung `alias` và `avatarId` vào domain model `StudyProfile`, thêm danh sách khối lớp THPT `thptGradeLevels` vào `SubjectCatalog`.
- **2026-11-16 20:45**: Xây dựng màn hình `AuthScreen` với đầy đủ tab Đăng ký / Đăng nhập, kiểm tra validation client, tích hợp `PersonalFlowViewModel` và fallback báo thức offline.
- **2026-11-16 20:55**: Cập nhật `WelcomeScreen` đưa "Bắt đầu ngay (Đăng ký / Đăng nhập)" làm CTA chính, sắp xếp lại nút phụ gọn gàng trong tầm nhìn 780dp.
- **2026-11-16 21:05**: Cập nhật `OnboardingSetupScreen`: Lựa chọn khối lớp THPT 10–12, chọn Avatar vector, bổ sung thẻ "Kế hoạch đề xuất của bạn" để học sinh xem và xác nhận trước khi lưu.
- **2026-11-16 21:15**: Cải tiến `TodayScreen`: Thay pill "Chế độ khách · Lưu trên máy" bằng danh tính học sinh (`Minh Khang · Lớp 11` hoặc `Báo thức trên máy`), thu gọn thông báo cấp quyền thành thanh một chạm tinh tế, giữ các pill trạng thái đồng bộ server.
- **2026-11-16 21:30**: Sửa lỗi layout overflow khi text scale 200% tại độ rộng 320dp trên `OnboardingSetupScreen` và `WelcomeScreen`.
- **2026-11-16 21:40**: Biên dịch APK debug thành công (`flutter build apk --debug`, 62.7s), cài đặt lên Android Emulator (`emulator-5554`), kiểm tra tương tác thực tế từ màn Chào mừng -> Đăng ký -> Chọn lớp/môn/avatar -> Xác nhận kế hoạch -> Vào Hôm nay. Chụp ảnh lưu trữ vào artifact.
- **2026-11-16 21:50**: Chạy toàn bộ test tự động (`flutter analyze`, `domain_and_persistence_test.dart`, `guest_flow_widget_test.dart`, `android_bridge_contract_test.dart`, `personal_flow_real_service_test.dart`) đều đạt 100%. `check_task_records.py` và `check_docs_links.py` đều PASS.
