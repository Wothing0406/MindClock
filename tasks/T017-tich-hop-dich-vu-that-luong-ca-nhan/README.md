# T017 — Thay fixture bằng dịch vụ thật cho luồng cá nhân

- **Trạng thái:** `blocked`
- **Mục tiêu:** xây dựng tầng Auth online, HTTP API `/v1` (`RemotePersonalFlowRepository`), camera xin quyền đúng lúc với bước xem lại/xác nhận trước upload, bản nháp chữ offline tối đa 24 giờ chỉ đồng bộ khi xác nhận, báo chấm sai (`/feedback`), tiến độ riêng tư (`/progress/summary`), tách hoàn toàn khỏi debug fixture có nhãn, và bộ test end-to-end theo `integration_test` hiện hành.
- **Nguồn yêu cầu:** nhiệm vụ ngày 14/11/2026 (`docs/06, 07, 17, 18, 24, 25, 28, 39`), đối chiếu `docs/16` và hướng dẫn chính thức Flutter `docs.flutter.dev/testing/integration-tests` (không bật `flutter_driver` / `enableFlutterDriverExtension()`).
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `app/pubspec.yaml`, `app/lib/domain/**`, `app/lib/data/**`, `app/lib/ui/**`, `app/lib/app.dart`, `app/lib/main.dart`, `app/android/app/src/main/**`, `app/test/**`, `app/integration_test/**`, `tasks/T017-tich-hop-dich-vu-that-luong-ca-nhan/*`.
- **Liên quan:** phụ thuộc backend thật tại [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md) (`planned`) và Firebase Auth project thật (`--dart-define` / cấu hình Android) để xác minh luồng online ngoài loopback test server.
- **Source refs đã đọc:** `docs/06 §§1–5`, `docs/07 §§1–8`, `docs/17 §§1–6`, `docs/18 §§1–5`, `docs/24 §§1–4`, `docs/25 §§1–5`, `docs/28 §§1–7`, `docs/39 §§1–6`, `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md`, `.agents/skills/flutter-add-integration-test/SKILL.md`, `docs.flutter.dev/testing/integration-tests`. Skill chính: `flutter-apply-architecture-best-practices`; skill bổ trợ: `flutter-add-integration-test` (chỉ phần `IntegrationTestWidgetsFlutterBinding`, bỏ qua bước `enableFlutterDriverExtension`).
- **Điểm tiếp tục:** đã hoàn tất tầng domain/data/UI/Android camera bridge, loopback `/v1` contract test và `integration_test/personal_flow_e2e_test.dart`; đang **blocked** ở 2 điều kiện bàn giao cuối: (1) máy build chưa cài Flutter/Dart SDK để chạy `flutter analyze`, `flutter test` và `flutter test integration_test/personal_flow_e2e_test.dart`, và (2) backend FastAPI/PostgreSQL ([T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md)) cùng dự án Firebase Auth thật chưa được triển khai. Tiếp tục bằng cách cài Flutter SDK chạy test loopback trước, rồi dựng `T016` và nối chạy thật theo `--dart-define`.

## Cổng trước coding

- [x] Đã kiểm tra repo và xác nhận backend FastAPI/PostgreSQL chưa tồn tại; đã mở task phụ thuộc riêng `T016` theo đúng hợp đồng `docs/07`, `docs/28`.
- [x] Đã đọc đầy đủ `docs/07, 17, 18, 24, 25, 28, 39`, `.agents/skills/flutter-apply-architecture-best-practices/SKILL.md`, `.agents/skills/flutter-add-integration-test/SKILL.md` và đối chiếu `docs.flutter.dev/testing/integration-tests` (dùng `IntegrationTestWidgetsFlutterBinding`, **không** thêm `enableFlutterDriverExtension()`).
- [x] `spec.md`, `plan.md`, `tests.md` điền đầy đủ trước khi sửa code.

## Cổng kết thúc

- [ ] Kết nối chạy thật được tối thiểu 1 luồng online với backend `T016` (Auth online -> `/v1/challenges/next` -> `/v1/sessions` -> `/answers`/`/attempts` -> `/progress/summary` -> đăng xuất).
- [ ] `flutter analyze`, `flutter test` và `flutter test integration_test/personal_flow_e2e_test.dart` pass trên máy có Flutter SDK.
- [ ] Xác minh thủ công trên máy Android thật: quyền camera đúng lúc, không lưu ảnh mặc định, token hết hạn không ảnh hưởng báo thức local.
