# Nhật ký thực hiện T017

## 2026-11-14

- Kiểm tra repo trước khi code: `services/api/` (backend FastAPI/PostgreSQL) chưa tồn tại, chỉ có tài liệu thiết kế `docs/07`, `docs/18`, `docs/28`. Mở task backend phụ thuộc riêng [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md).
- Đọc đầy đủ `docs/06, 07, 17, 18, 24, 25, 28, 39`, `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md`, `.agents/skills/flutter-add-integration-test/SKILL.md`, và đối chiếu tài liệu Flutter hiện hành `docs.flutter.dev/testing/integration-tests` (chọn `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` + `flutter test integration_test/...`, không bật `enableFlutterDriverExtension()`).
- Tạo hồ sơ `T017` trước khi sửa mã Flutter/Android.
- Cài đặt hoàn chỉnh tầng `domain/` (`auth_session.dart`, `personal_flow_models.dart`, `auth_session_gateway.dart`, `camera_capture_gateway.dart`, `personal_flow_repository.dart`).
- Cài đặt tầng `data/` tách biệt đường thật (`personal_api_client.dart`, `remote_personal_flow_repository.dart`, `firebase_auth_gateway.dart`, `offline_text_draft_store.dart`, `method_channel_camera_gateway.dart`, `local_id_generator.dart`) và đường fixture debug riêng dưới `app/lib/data/debug/` (`debug_fixture_auth_gateway.dart`, `debug_fixture_personal_flow_repository.dart`).
- Bổ sung cầu nối camera Android native (`CameraBridgeHandler.kt`, `MainActivity.kt`, `AndroidManifest.xml`): chỉ xin quyền `CAMERA` khi người dùng bấm chụp, dùng `ACTION_IMAGE_CAPTURE` trả về bytes JPEG nén trong RAM, không ghi vào Gallery/MediaStore.
- Xây `PersonalFlowViewModel`, `AccountAuthCard`, `PracticeSessionScreen`, nối vào `MeGuestScreen`, `MindClockShellScreen`, `app.dart`, và xóa `practice_placeholder_screen.dart` không còn tham chiếu.
- Viết `app/test/support/loopback_v1_contract_server.dart`, `app/test/personal_flow_real_service_test.dart` (`PF-TC-01..08`) và `app/integration_test/personal_flow_e2e_test.dart` dùng `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
- Kiểm tra tĩnh trên Windows host (không có Flutter/Dart SDK qua `where.exe flutter dart`): `scripts/check_docs_links.py` PASS (57 docs), `scripts/check_task_records.py` OK, `Select-String` xác nhận 0 `Color(0x` ngoài `mindclock_theme.dart`, 0 lời gọi `flutter_driver` / `enableFlutterDriverExtension` / Hilt / Compose / `\bInkWell\b` / `\bNavigationBar\b`.
- Đặt trạng thái `T017` thành `blocked` thay vì `done` vì thiếu Flutter SDK trên máy để biên dịch/chạy test và thiếu backend thật `T016` + dự án Firebase Auth.
