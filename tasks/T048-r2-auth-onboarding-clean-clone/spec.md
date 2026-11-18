# Đặc tả T048 — R0/R2: Clean-clone Flutter, Giải thích quyền và Auth/Onboarding (ON-01..ON-06)

## Vấn đề và kết quả mong muốn

1. **Lỗi biên dịch bản clone sạch (R0 blocker):** Hiện tại `mindclock_shell_screen.dart` và `today_screen.dart` đã được commit trên `origin/main`, nhưng `auth_screen.dart` và `morning_question_selector.dart` vẫn nằm untracked trong working tree local. Bất kỳ bản clone sạch hoặc CI nào sẽ lỗi biên dịch `Target of URI doesn't exist`.
2. **Điểm thiếu của R2 (`docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`):**
   - `WelcomeScreen` chưa có khung **Giải thích quyền** (chuông chính xác, thông báo, màn hình khóa, DND, camera/mic — nêu rõ chỉ hỏi OS permission đúng lúc dùng, không bật hàng loạt lúc mở đầu).
   - `AuthScreen` thiếu ô xác nhận bắt buộc khi đăng ký: **Đồng ý điều khoản & quyền dữ liệu (v1)** và **Xác nhận độ tuổi THPT (15–18 / có đồng ý phụ huynh)**; nút đường dự phòng cần ghi rõ `Chỉ dùng báo thức trên máy`; nút ẩn/hiện mật khẩu đang dùng `Icons.visibility_off_outlined` (stock Material) thay vì `MindClockPressable` text toggle chuẩn design system.
   - Chưa có widget test chuyên biệt cho `ON-01..ON-06` (validation form, lỗi `CONFIGURATION_NOT_FOUND` không chuyển sang tài khoản giả, fallback `Chỉ dùng báo thức trên máy`, đăng ký → onboarding THPT → dashboard, đổi tài khoản A/B cô lập draft/TKB nhưng giữ báo thức local).
3. **Đồng bộ hiện trạng:** `docs/00-start/01-hien-trang.md` còn mốc `16/11/2026`, chưa phản ánh kết quả kiểm chứng thật ngày 2026-11-18 (live PostgreSQL 16 49/49 PASS, Flutter 61+ tests PASS, G1 solo arena, clean-clone fix).

## Phạm vi

- **Trong phạm vi:**
  - Theo dõi Git sạch cho `auth_screen.dart`, `morning_question_selector.dart`, `morning_question_selector_test.dart`.
  - Cập nhật `welcome_screen.dart` (thêm thẻ Giải thích quyền gọn, giữ nguyên các nút & `ValueKey` cũ để không phá test hiện hành).
  - Cập nhật `auth_screen.dart` (thêm 2 ô xác nhận consent & độ tuổi khi đăng ký, validate rõ tiếng Việt, nút `Chỉ dùng báo thức trên máy`, nút `Hiện`/`Ẩn` mật khẩu bằng `MindClockPressable`, 0 raw hex/emoji).
  - Viết `app/test/auth_onboarding_flow_test.dart` kiểm chứng `ON-01..ON-06`.
  - Xác minh biên dịch & test trên **detached clean Git worktree** (không phụ thuộc file untracked).
  - Cập nhật `docs/00-start/01-hien-trang.md`.
- **Ngoài phạm vi:** Sửa backend Auth, sửa web `/demo`/`/product`, commit `google-services.json`/secret, mở G2/G3/Ranked, hoặc tuyên bố đã bật Firebase Email/Password live trên Firebase Console nếu chưa kiểm trên project thật.

## Yêu cầu kiểm chứng được

| ID | Liên kết | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | ON-01 | Mở app lần đầu thấy `WelcomeScreen` có khung **Giải thích quyền** (chuông chính xác, thông báo, màn khóa, DND, camera/mic — hỏi đúng lúc dùng), CTA chính `Đăng ký / Đăng nhập` và nút `Chỉ dùng báo thức trên máy` | TC-01 |
| AC-02 | ON-02 | Ở `AuthScreen` (Đăng ký): email sai, mật khẩu < 6 ký tự, xác nhận mật khẩu lệch, hoặc chưa tích đồng ý điều khoản/độ tuổi đều chặn submit và báo lỗi tiếng Việt rõ ràng; không bắt buộc `@gmail.com` | TC-02 |
| AC-03 | ON-01, ON-03 | Khi `AuthSessionGateway` trả lỗi `CONFIGURATION_NOT_FOUND` hoặc lỗi mạng, UI hiển thị đúng thông báo hướng dẫn (không tự đăng nhập tài khoản giả) và người dùng bấm `Chỉ dùng báo thức trên máy` vào thẳng cấu hình chuông local | TC-03 |
| AC-04 | ON-04, ON-05 | Sau khi đăng ký/đăng nhập hợp lệ → vào `OnboardingSetupScreen` chọn lớp 10–12, môn theo catalog, xác nhận kế hoạch → vào `MainTabs` (`Hôm nay`) hiển thị biệt danh đã nhập | TC-04 |
| AC-05 | ON-06 | Đổi tài khoản A → đăng xuất → tài khoản B: hồ sơ/TKB/draft của A không lộ sang B, trong khi báo thức local trên máy vẫn còn và sửa/xóa được | TC-05 |
| AC-06 | R0 Clean Clone | Bản `git worktree add --detach` chỉ chứa file đã commit vượt qua `dart analyze` (0 issues) và `flutter test --no-pub` (100% PASS) mà không phụ thuộc file untracked | TC-06 |
