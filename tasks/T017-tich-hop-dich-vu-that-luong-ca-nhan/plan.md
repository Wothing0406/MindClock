# Kế hoạch thực hiện T017

## Điểm bắt đầu

- `app/` đã có luồng khách local + cấu hình/cầu nối báo thức Android native (`T014`, `T015`), tab `Luyện tập` mới là `PracticePlaceholderScreen`, tab `Tôi` mới có `MeGuestScreen`.
- Backend `T016` chưa tồn tại trong repo; tích hợp thật cần tách rõ `RemotePersonalFlowRepository` (HTTP `/v1` chuẩn `docs/07`) và `DebugFixturePersonalFlowRepository` (debug only có nhãn).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `T016` (`planned`) và `T017` (`in_progress`), kiểm tra `docs/07,17,18,24,25,28,39` và chuẩn `integration_test` hiện hành | Đủ cổng trước coding | [x] |
| 2 | Xây domain models & interfaces cho luồng cá nhân (`auth_session.dart`, `personal_flow_models.dart`, `auth_session_gateway.dart`, `personal_flow_repository.dart`, `camera_capture_gateway.dart`) | Phân định rạch ròi online server state vs local draft/offline | [x] |
| 3 | Xây tầng `data/` thật (`personal_api_client.dart` dùng `dart:io` + retry/timeout 15s + 401 refresh once + multipart `/attempts`, `remote_personal_flow_repository.dart`, `firebase_auth_gateway.dart`, `offline_text_draft_store.dart` TTL 24h scoped by `ownerKey`, `method_channel_camera_gateway.dart`) và tách `data/debug/` (`debug_fixture_personal_flow_repository.dart`, `debug_fixture_auth_gateway.dart`) | Tách hoàn toàn đường thật và fixture debug; `Idempotency-Key` ổn định khi retry | [x] |
| 4 | Nối camera native theo yêu cầu (`CameraBridgeHandler.kt`, `MainActivity.kt`, `AndroidManifest.xml` thêm `CAMERA` `required="false"` + `<queries>`) chỉ xin quyền khi chụp, đọc bytes xong xóa file tạm ngay | Không lưu ảnh mặc định vào Gallery/MediaStore | [x] |
| 5 | Xây `PersonalFlowViewModel`, UI đăng nhập/tài khoản trên tab `Tôi`, tab `Luyện tập` thật (`PracticeSessionScreen` có chế độ nhập chữ + camera preview/confirm + thách thức 3 lần sai mới gợi ý + báo chấm sai + lưu/gửi nháp 24h + tiến độ riêng tư server XP) và nối vào `MindClockShellScreen` & `app.dart` (xóa `practice_placeholder_screen.dart`) | Tuân thủ 1:1 `MindClockTheme`, `MindClockPressable`, `vi-VN`, không emoji, báo thức local không bị ảnh hưởng bởi lỗi auth/network | [x] |
| 6 | Cập nhật `pubspec.yaml` (`integration_test`), viết unit/contract tests (`app/test/personal_flow_real_service_test.dart`) và E2E `integration_test/personal_flow_e2e_test.dart` chạy với loopback `HttpServer` thật mô phỏng hợp đồng `/v1` (happy path, timeout 15s, token expired `401`, idempotency retry, A/B isolation, camera review/cancel, offline draft confirm) | Không bật `enableFlutterDriverExtension`; chạy static checks & cập nhật `T017` (`blocked` do chưa có backend `T016` & Flutter SDK) | [x] |
