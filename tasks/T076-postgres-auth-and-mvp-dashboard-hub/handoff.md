# Bàn giao nhiệm vụ T076

- **Trạng thái cuối:** `verifying` (đạt toàn bộ AC-01..AC-04, pytest + Flutter test + live Docker PostgreSQL 16 + Android Emulator E2E; chưa commit/push theo yêu cầu không tự push khi chưa được ủy quyền).
- **Đã làm:**
  - Backend PostgreSQL Auth (`services/api`): Thêm bảng `local_auth_accounts` (Alembic `0007_add_local_auth_accounts.py`), helper `local_auth.py` (`scrypt` + HS256 JWT + regex mật khẩu mạnh), xác minh JWT kép HS256/Firebase RS256 tại `verify_token.py`, router `/v1/auth/{register,login,refresh}` và xóa cascade tài khoản trong `DELETE /v1/me`.
  - Flutter Auth Fallback & MVP Command Center (`app`): Nối `backendBaseUri` vào `FirebaseAuthGateway` (kèm sửa lỗi parse `error.code` kiểu `int` phát hiện khi chạy APK thật với Identity Toolkit `OPERATION_NOT_ALLOWED`), thêm **Danh mục tính năng 6 ô** (`today-feature-directory`) trên `TodayScreen` và chuyển `TodayPetCard` xuống dưới.
  - Tài liệu & DevFest: Điền đầy đủ hồ sơ trình bày DevFest 12 phần tách bạch tại `docs/06-devfest/01-ho-so-trinh-bay-devfest.md` và cập nhật `docs/00-start/01-hien-trang.md`.
- **File/code/docs thay đổi:**
  - `services/api/app/{config.py,db/models.py,auth/local_auth.py,auth/verify_token.py,routes/auth.py,routes/v1.py,main.py,schemas.py}`, `services/api/alembic/versions/0007_add_local_auth_accounts.py`, `services/api/tests/test_local_auth_postgres.py`.
  - `app/lib/{app.dart,data/services/firebase_auth_gateway.dart,ui/features/guest_shell/views/today_screen.dart,ui/features/guest_shell/views/mindclock_shell_screen.dart}`, `app/test/t076_mvp_hub_and_backend_auth_test.dart`.
  - `docs/00-start/01-hien-trang.md`, `docs/06-devfest/01-ho-so-trinh-bay-devfest.md`, `tasks/T076-postgres-auth-and-mvp-dashboard-hub/*`, `test_demo_android/screenshots/{23_t076_live_dashboard_hub.png,24_t076_arena_lobby_original.png}`.
- **Test đã chạy:**
  - `.venv\Scripts\python.exe -m pytest -q` (SQLite + PostgreSQL 16): **96 passed**, 0 failed.
  - `flutter analyze --no-pub`: **0 issues**; `TODAY_RAW_HEX_HITS=0`; `flutter test --no-pub -j 1`: **162/162 passed**; sau lần sửa cuối `firebase_auth_gateway.dart` (chỉ xử lý `error.code` int), đã chạy lại `flutter analyze --no-pub`, `t076_mvp_hub_and_backend_auth_test.dart` (2/2 passed) và test live trên `dist/mindclock-debug.apk`.
  - E2E `emulator-5554` + Docker `api-api-1`/`api-postgres-1`: Đăng ký `e2ehs76@mindclock.vn` → Onboarding Lớp 12 → Dashboard Hub → Đấu trường đạt 100%, xem [tests.md](tests.md).
- **Test chưa chạy/giới hạn:** Chưa test trên **2 thiết bị Android vật lý** (R1 alarm/Doze/voice); `:app:testDebugUnitTest` (12/12 pass) chạy ở lượt tiền-T076 (không đụng Kotlin native trong T076).
- **Rủi ro còn lại:** Trên thiết bị thật ngoài emulator, build bản release bắt buộc truyền `-ApiBaseUrl https://<host-backend>` vì mặc định `10.0.2.2:8000` chỉ trỏ tới host từ Android Emulator.
- **Điểm tiếp tục chính xác:** Nếu được phép commit/push: rà `git status` / staged diff (`dist/` và `test_demo_android/` hoặc tài sản WIP kiểm tra theo `.gitignore`), stage từng phần hợp lệ và push. Bước tiếp theo theo lộ trình R1: mở `tasks/` kiểm báo thức trên 2 thiết bị Android vật lý.
- **Git:** Giữ chưa commit/push trong worktree hiện tại theo yêu cầu phiên (`DO NOT commit or push unless explicitly authorized`).
- **Quyết định phải xin người phụ trách:** Xác nhận trước khi commit/push nhánh hiện hành lên GitHub hoặc khi muốn bật Email/Password trực tiếp trên Firebase Console song song với PostgreSQL local auth.
