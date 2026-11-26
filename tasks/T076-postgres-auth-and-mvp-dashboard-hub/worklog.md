# Nhật ký xử lý lỗi T076

## Vòng 1 — Parse payload `POST /v1/commitment-groups` & `HttpOverrides` trong Flutter test (`21/11/2026`)
- **Tái hiện:** Chạy `pytest -q` fail tại `test_local_auth_works_on_live_postgresql_with_alembic_0007` (`KeyError: 'group'`); chạy `t076_mvp_hub_and_backend_auth_test.dart` fail tại `TC-01` với `AuthException(AUTH_FAILED)`.
- **Nguyên nhân:** `CommitmentGroupService.create_group` trả thẳng object group (`grp.json()['name']`), chỉ `/commitment-groups/me` mới bọc dưới key `'group'`. Ở Flutter, `TestWidgetsFlutterBinding` cài đặt `HttpOverrides` toàn cục khiến mọi `HttpClient()` mặc định trả HTTP 400 rỗng thay vì gọi mock `HttpServer` loopback.
- **Sửa & kiểm lại:** Sửa assertion sang `grp.json()['name']`; truyền `_DirectHttpOverrides` qua `httpClientFactory` trong `t076_mvp_hub_and_backend_auth_test.dart`. Kết quả: `pytest` **96/96 PASS**, `flutter test` **162/162 PASS**.

## Vòng 2 — `error.code` kiểu `int` (`400`) từ Identity Toolkit trên Emulator APK thật (`21/11/2026`)
- **Tái hiện:** Cài `dist/mindclock-debug.apk` lên `emulator-5554`, bấm `Tạo tài khoản & Tiếp tục` với `e2ehs76@mindclock.vn` thì UI đứng yên và `local_auth_accounts` không có bản ghi.
- **Nguyên nhân:** Kiểm `adb logcat -d -s flutter` ghi nhận `type 'int' is not a subtype of type 'String?' in type cast` tại `FirebaseAuthGateway._postJson` (`firebase_auth_gateway.dart:376`), vì Google Identity Toolkit trả `{"error": {"code": 400, "message": "OPERATION_NOT_ALLOWED"}}` với `code` là `int` trước khi kích hoạt cơ chế fallback `/v1/auth/*`.
- **Sửa & kiểm lại:** Đọc an toàn `Object? rawCode = err?['code']` và `msgField = err?['message']?.toString()` để phân biệt integer HTTP code của Firebase và string `error.code` của FastAPI; bổ sung `code: 400` vào mock test `t076_mvp_hub_and_backend_auth_test.dart`. Rebuild APK & chạy lại trên `emulator-5554`: `/v1/auth/register`, `/v1/me/consent`, `/v1/me`, `/v1/timetable` đều `200 OK`, vào trọn Onboarding Lớp 12 -> Dashboard Hub 6 ô -> Đấu trường 3 tướng gốc.
