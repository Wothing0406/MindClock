# Kế hoạch T076

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| ---- | -------- | ------------- | ---------- |
| 1 | Thêm `LocalAuthAccount` model + migration `0007_add_local_auth_accounts.py` + helper `local_auth.py` (`scrypt`, `HS256` JWT) + verify trong `verify_token.py` + router `/v1/auth/*` | Alembic upgrade/downgrade & parity SQLite + PG16 đạt | [x] |
| 2 | Viết `services/api/tests/test_local_auth_postgres.py` kiểm đăng ký, sai mật khẩu, trùng email, refresh, cô lập A/B, DELETE `/v1/me` & concurrency | Pytest SQLite + PG16 đạt 100% | [x] |
| 3 | Nối `backendBaseUri` vào `FirebaseAuthGateway` (`app.dart`, `firebase_auth_gateway.dart`) giữ nguyên phân tách lỗi credential, sửa parse `error.code` kiểu `int` và hỗ trợ refresh token backend | Unit + loopback/backend integration test đạt | [x] |
| 4 | Chuẩn hóa `TodayScreen` + `MindClockShellScreen` thêm **Danh mục 6 tính năng MVP** (`today-feature-directory`) và chuyển `TodayPetCard` xuống khu Cộng đồng/Động lực | Widget test 320dp 200% & toàn bộ test Flutter đạt | [x] |
| 5 | Rebuild Docker `services/api` (`alembic upgrade head`), rebuild `dist/mindclock-debug.apk` từ `lib/main.dart`, test đăng ký thật -> Onboarding -> Dashboard trên `emulator-5554` và chụp ảnh xác minh | Ảnh Emulator chứng minh login thật vào full Dashboard & Đấu trường | [x] |
