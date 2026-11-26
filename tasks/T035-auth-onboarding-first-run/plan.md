# Kế hoạch thực hiện T035

## Các bước triển khai

1. **Bước 1: Cập nhật `WelcomeScreen` và `MindClockShellScreen`**
   - Thêm trạng thái `_GuestFlowStage.auth`.
   - Cung cấp callback `onStartAuth` trên `WelcomeScreen`.
   - Cập nhật giao diện `WelcomeScreen` tôn trọng ngôn ngữ "Bình minh trên trang vở".
2. **Bước 2: Xây dựng màn hình `AuthScreen` chuyên dụng**
   - Hỗ trợ 2 chế độ: Đăng ký (kèm xác nhận mật khẩu, biệt danh) và Đăng nhập.
   - Kết nối `PersonalFlowViewModel` và `FirebaseAuthGateway`.
   - Có nút "Bỏ qua về chế độ dùng thử báo thức cục bộ" khi offline.
3. **Bước 3: Nâng cấp `OnboardingSetupScreen` và `PersonalFlowViewModel`**
   - Bổ sung chọn Biệt danh học sinh và Avatar.
   - Thêm bước tóm tắt & xác nhận kế hoạch trước khi vào Dashboard.
   - Đồng bộ hồ sơ qua `apiClient.patchJson('/me', ...)` khi `isAuthenticated`.
4. **Bước 4: Tinh gọn `TodayScreen`**
   - Khi `isAuthenticated == true`: Hiển thị "Chào buổi sáng, [Biệt danh] (Lớp [Khối])".
   - Loại bỏ các text kỹ thuật như "Chế độ khách · Lưu trên máy", "Chưa đồng bộ server".
   - Đưa trạng thái kết nối backend thành một indicator tinh tế.
5. **Bước 5: Chạy kiểm thử & nghiệm thu**
   - Chạy `flutter analyze` đảm bảo 0 cảnh báo.
   - Chạy các unit/widget test.
   - Cập nhật bản build lên Android Emulator, chụp màn hình kiểm chứng.
