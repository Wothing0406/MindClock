# Đặc tả kỹ thuật T035

## 1. Hành trình người dùng

1. **Khởi động lần đầu:**
   - Người dùng thấy `WelcomeScreen` với tiêu đề "Dậy đúng giờ. Nghĩ bằng chính mình."
   - Nút chính `ValueKey('welcome-auth-start')`: **Đăng ký / Đăng nhập** -> Chuyển sang `_GuestFlowStage.auth`.
   - Nút phụ `ValueKey('welcome-alarm-only')`: **Chỉ dùng báo thức trên máy** -> Chuyển sang `_GuestFlowStage.alarmConfig` (giữ đường cứu sinh offline).
2. **Xác thực (`AuthScreen`):**
   - Người dùng chuyển đổi giữa tab **Tạo tài khoản** và **Đăng nhập**.
   - Form Đăng ký:
     - Email (`auth-email-input`), Biệt danh (`auth-alias-input`), Mật khẩu (`auth-password-input`), Xác nhận mật khẩu (`auth-confirm-password-input`).
     - Client check: Mật khẩu >= 6 ký tự, Xác nhận mật khẩu khớp hoàn toàn.
     - Gọi `personalViewModel.signUpWithEmail(email, password, alias)`.
   - Form Đăng nhập:
     - Email, Mật khẩu. Gọi `personalViewModel.signIn(email, password)`.
   - Thành công -> Chuyển sang `_GuestFlowStage.onboardingSetup`.
3. **Onboarding Lớp 10–12 & Kế hoạch:**
   - Khối lớp: Chọn `Lớp 10`, `Lớp 11`, hoặc `Lớp 12`.
   - Môn học: Chọn từ danh mục THPT (`Toán`, `Ngữ văn`, `Tiếng Anh`, `Vật lí`, `Hóa học`, `Sinh học`, `Lịch sử`, `Địa lí`, `Tin học`, `GDCD`...).
   - Đánh giá: Mức độ ưu tiên/tự tin (Mới bắt đầu / Cơ bản / Nâng cao).
   - Avatar: Chọn biểu tượng/avatar đại diện.
   - Xác nhận kế hoạch: Lưu hồ sơ qua `viewModel.saveStudyProfile(...)` và đồng bộ `PATCH /v1/me`.
   - Hoàn tất -> Vào `_GuestFlowStage.mainTabs` (Hôm nay).

## 2. Tiêu chí chấp nhận (AC)

- **AC-01:** `WelcomeScreen` lấy hành động Đăng ký / Đăng nhập làm trọng tâm, giữ nút dùng báo thức offline cục bộ.
- **AC-02:** `AuthScreen` kiểm tra hợp lệ mật khẩu khớp, độ dài tối thiểu, hiển thị thông báo lỗi tiếng Việt thân thiện, không log mật khẩu.
- **AC-03:** Sau khi đăng ký/đăng nhập thành công, app tự động điều hướng sang luồng onboarding hồ sơ THPT và lưu `StudyProfile` có tên, lớp, môn học.
- **AC-04:** Hồ sơ người dùng sau onboarding được gửi lên backend `PATCH /v1/me` với Bearer ID token hợp lệ, lưu vào PostgreSQL.
- **AC-05:** Màn hình `TodayScreen` khi đã đăng nhập hiển thị thông tin học sinh thực tế (Biệt danh, Lớp, Môn đã chọn), loại bỏ huy hiệu "Chế độ khách · Lưu trên máy".

## 3. Ca kiểm thử (TC)

- **TC-01 (Unit/Widget):** Kiểm tra `WelcomeScreen` hiển thị nút Đăng ký / Đăng nhập và nút Báo thức cục bộ.
- **TC-02 (Unit/Widget):** Kiểm tra `AuthScreen` validate mismatch mật khẩu hiển thị thông báo lỗi trước khi gọi gateway.
- **TC-03 (Contract):** Kiểm tra `PersonalApiClient.patchJson('/me')` cập nhật alias, grade_band, selected_subjects trên backend PostgreSQL.
- **TC-04 (Integration/Emulator):** Xác minh luồng chạy thực tế trên Android Emulator từ màn Chào mừng -> Đăng nhập -> Onboarding -> Hôm nay.
