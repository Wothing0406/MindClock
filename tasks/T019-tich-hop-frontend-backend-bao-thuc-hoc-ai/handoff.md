# Bàn giao T019

- **Trạng thái task:** `blocked` (frontend integration layer + cấu hình `.env` + loopback contract test suite đã viết xong, nhưng máy Windows hiện tại không có `flutter`/`dart` SDK để biên dịch/chạy test, và repo chưa có `services/api/` chạy thật từ `T016`).

## Chức năng — Chạy thật hay mẫu — Bằng chứng — Giới hạn

| Chức năng | Chạy thật hay mẫu | Bằng chứng | Giới hạn |
| --- | --- | --- | --- |
| Cấu hình biến môi trường (`.env`, `.env.example`, `.gitignore`) | Cấu hình thật (template chuẩn `--dart-define-from-file`) | `.gitignore`, `app/.env.example`, `app/.env` (untracked trong `git status`), `app/lib/app.dart` (`String.fromEnvironment`) | Giá trị `MINDCLOCK_FIREBASE_WEB_API_KEY` và URL backend đang là placeholder/local emulator `10.0.2.2:8000`; chưa có Firebase project key & server thật |
| Lưu & lập lịch báo thức local + UI 3 trạng thái | Code chạy thật trên frontend/OS bridge (`T014`–`T015` + mở rộng `T019`), kiểm thử tự động chưa chạy được | `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`, `today_screen.dart`, `INT-TC-01` | Máy thiếu `flutter`/`dart` nên chưa biên dịch/chạy widget test `INT-TC-01` và chưa re-verify trên máy Android thật |
| Đồng bộ báo thức `/v1/alarms` & `/v1/sessions/{id}/events` (`dismiss`) | Client HTTP thật trong `RemoteAlarmSyncGateway` + loopback mock HTTP (`LoopbackV1ContractServer`); chế độ mẫu chỉ bật khi `kDebugMode && MINDCLOCK_DEBUG_FIXTURE=true` | `remote_alarm_sync_gateway.dart`, `pending_alarm_event_store.dart`, `loopback_v1_contract_server.dart`, `INT-TC-01`, `INT-TC-02` | `services/api/` (`T016`) chưa tồn tại trong repo; chưa kiểm chứng được với FastAPI + PostgreSQL thật |
| `Dừng khẩn cấp` tắt chuông ngay & ghi nhận server sau không re-schedule | Logic frontend + queue 7 ngày thật; test hợp đồng đã viết | `GuestWorkspaceViewModel.triggerEmergencyStop`, `mindclock_shell_screen.dart`, `pending_alarm_event_store.dart`, `INT-TC-02` | Chưa chạy trên thiết bị Android thật cùng backend đang bật |
| Không gian học timer/pause/finish local (`T018` + `T019`) | Code chạy thật trên thiết bị; đồng bộ kết thúc phiên idempotent tách khỏi nút thoát | `StudyFocusViewModel`, `StudySpaceScreen`, `study_focus_models.dart`, `INT-TC-03`, `INT-TC-05` | Chưa chạy `flutter test` trong phiên này vì thiếu SDK |
| Hỏi AI `Hỏi MindClock` qua `POST /v1/study/help` | Client thật gọi `/v1/study/help` qua `PersonalApiClient`; test dùng `LoopbackV1ContractServer` và `DebugFixtureStudyAiGateway` cho chế độ mẫu | `remote_study_ai_gateway.dart`, `study_space_screen.dart`, `study_focus_view_model.dart`, `INT-TC-04` | Chưa có backend `/v1/study/*` + Gemini server-side chạy thật để test nội dung gợi ý và rate limit thật |
| Firebase ID Token & cô lập tài khoản `A ↔ B` | `FirebaseAuthGateway` & `PersonalApiClient` tái sử dụng từ `T017`; loopback mô phỏng Identity Toolkit/SecureToken + `403` | `app/lib/app.dart`, `personal_api_client.dart`, `INT-TC-06`, static scan 0 key/token | Chưa chạy E2E với dự án Firebase Auth thật |

## Điểm tiếp tục cụ thể

1. Cài/mở môi trường có Flutter & Dart SDK, chạy `flutter pub get`, `flutter analyze`, và `flutter test test/backend_integration_contract_test.dart` (kèm toàn bộ `flutter test`) trong thư mục `app/`.
2. Triển khai `T016` (`services/api/` FastAPI + PostgreSQL) bổ sung các endpoint `/v1/alarms`, `/v1/sessions/{id}/events`, `/v1/study/sessions`, `/v1/study/help`, `/v1/study/sessions/{id}/finish` đúng hợp đồng `docs/07` & `docs/45 §5`.
3. Điền URL server thật và Firebase Web API key thật vào `app/.env` cục bộ, chạy `flutter run --dart-define-from-file=.env` trên máy Android thật và xác nhận hết chuỗi `INT-TC-01..07` rồi mới bỏ trạng thái `blocked`.
