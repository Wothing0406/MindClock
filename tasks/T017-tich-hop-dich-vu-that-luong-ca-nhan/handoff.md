# Bàn giao T017

- **Trạng thái:** `blocked` (đủ code & test suite ở client + tài liệu dependency backend `T016`, chưa thể biên dịch/chạy test vì thiếu Flutter SDK trên máy và thiếu backend thật `T016` + Firebase project).

## Phần đã hoàn tất

1. **Kiểm tra backend & mở task dependency riêng (`T016`):**
   - Đã kiểm tra repo (`git branch -a`, `git tag -l`, cây thư mục): chưa có `services/api/`, FastAPI hay PostgreSQL migration.
   - Đã mở [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md) (`planned`) đặc tả đầy đủ endpoint `/v1` (`docs/07`), schema PostgreSQL/Alembic (`docs/28`), Firebase ID token verification (`docs/24`), idempotency, timeout Gemini và xóa ảnh tạm (`docs/25`, `docs/39`). Không tự bịa endpoint ngoài tài liệu.
2. **Tách rõ dịch vụ thật và debug fixture trong Flutter (`app/lib/`):**
   - Đường thật mặc định (`createDefaultAuthGateway`, `createDefaultPersonalRepository` trong `app/lib/app.dart`): `FirebaseAuthGateway` (`MINDCLOCK_FIREBASE_WEB_API_KEY`) + `RemotePersonalFlowRepository` + `PersonalApiClient` (`MINDCLOCK_API_BASE_URL`, `dart:io` HTTP timeout 15 giây, refresh token 1 lần khi `401`, giữ nguyên `Idempotency-Key` khi retry).
   - Đường fixture debug nằm riêng tại `app/lib/data/debug/` (`DebugFixtureAuthGateway`, `DebugFixturePersonalFlowRepository`), chỉ bật khi `--dart-define=MINDCLOCK_USE_DEBUG_FIXTURE=true`, mang cờ `isDebugFixture=true`, `isServerAuthoritative=false` và hiển thị nhãn `Fixture debug · Không phải dịch vụ thật` trên UI.
3. **Luồng cá nhân (`PersonalFlowViewModel`, `AccountAuthCard`, `PracticeSessionScreen`):**
   - Đăng nhập/đăng ký Firebase REST, tự mở yêu cầu đăng nhập lại khi token hết hạn hoàn toàn (`AuthStatus.reauthRequired`) mà không ảnh hưởng `AlarmSchedulerService` hoặc `Dừng khẩn cấp`.
   - `GET /v1/challenges/next`, `POST /v1/sessions`, `POST /v1/sessions/{id}/events`, `POST /v1/sessions/{id}/answers`, `POST /v1/sessions/{id}/attempts` (multipart), `POST /v1/feedback`, `GET /v1/progress/summary`.
   - Chế độ thử thách ẩn gợi ý phương pháp ở lần sai rõ 1–2 và chỉ mở từ lần sai rõ thứ 3 (`uncertain` không tăng lượt sai); nút `Dừng khẩn cấp` luôn hiện hữu khi mở từ chuông reo.
   - XP chỉ hiển thị từ phản hồi server hợp lệ (`GradingResult.isServerAuthoritative && progressSummary.isServerAuthoritative`).
   - Báo chấm sai qua `POST /v1/feedback`.
   - Cách ly theo `ownerScopeKey` khi đăng xuất/đổi tài khoản A ↔ B: dọn phiên/tiến độ/bản nháp của tài khoản cũ trên UI, giữ nguyên báo thức thiết bị.
4. **Camera & Bản nháp offline 24 giờ:**
   - Android native (`CameraBridgeHandler.kt`, `MainActivity.kt`, `AndroidManifest.xml`): chỉ xin quyền `CAMERA` khi người dùng bấm chụp, dùng `ACTION_IMAGE_CAPTURE` trả byte JPEG nén trong RAM (<= 5 MB), không lưu Gallery/MediaStore.
   - UI bắt buộc bước xem lại ảnh và xác nhận riêng trước khi gọi multipart `POST /attempts`; không có hàng đợi tải ảnh ngầm khi lỗi.
   - `OfflineTextDraftStore`: lưu tối đa 1 bản nháp chữ mỗi tài khoản với TTL 24 giờ, tự xóa khi quá hạn, và khi online lại luôn hỏi xác nhận `Gửi bài này để nhận nhận xét?` trước khi gửi.
5. **Kiểm thử chuẩn hiện đại (`test/` & `integration_test/`):**
   - `app/pubspec.yaml` thêm `integration_test: sdk: flutter` (không dùng `flutter_driver` / `enableFlutterDriverExtension()`).
   - `app/test/support/loopback_v1_contract_server.dart`, `app/test/personal_flow_real_service_test.dart`, `app/integration_test/personal_flow_e2e_test.dart` dùng `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.

## Kiểm tra đã chạy sau sửa đổi cuối

- `where.exe flutter dart`: không tìm thấy `flutter` hoặc `dart` trên máy Windows hiện tại.
- `python scripts/check_docs_links.py`: `PASS local links in 57 documentation files`.
- `python scripts/check_task_records.py`: `Task records OK`.
- `git diff --check`: 0 lỗi conflict/trailing whitespace.
- `Select-String` trong `app/`: 0 `Color(0x` ngoài `mindclock_theme.dart`; 0 lời gọi `flutter_driver` / `enableFlutterDriverExtension` (chỉ có 1 dòng doc-comment giải thích tại `app/integration_test/personal_flow_e2e_test.dart:31`); 0 sử dụng `@HiltAndroidApp` / `dagger.hilt` / `androidx.compose`.

## Giới hạn & Phần chưa kiểm

- Chưa chạy `flutter pub get`, `flutter analyze`, `flutter test`, `flutter test integration_test/personal_flow_e2e_test.dart` vì thiếu Flutter SDK trên máy build.
- Chưa kết nối được với backend thật `T016` và Firebase Auth thật (chưa có server `/v1` và chưa có `google-services.json` / API key thật).
- Chưa xác minh thủ công camera, hết hạn token, xoay mạng và báo thức trên thiết bị Android thật (`adb devices` trống trước đó).

## Điểm tiếp tục cụ thể

1. Trên máy có Flutter SDK (và emulator/Android thật): chạy `cd app && flutter pub get && flutter analyze && flutter test && flutter test integration_test/personal_flow_e2e_test.dart` để xác minh toàn bộ `PF-TC-01..08` với `LoopbackV1ContractServer`.
2. Triển khai [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md) (FastAPI + PostgreSQL + Firebase Admin SDK + Gemini server-side).
3. Chạy app với `--dart-define=MINDCLOCK_API_BASE_URL=... --dart-define=MINDCLOCK_FIREBASE_WEB_API_KEY=...` trên Android thật, chạy đủ test end-to-end thật và cập nhật `tests.md` trước khi gỡ trạng thái `blocked`.
