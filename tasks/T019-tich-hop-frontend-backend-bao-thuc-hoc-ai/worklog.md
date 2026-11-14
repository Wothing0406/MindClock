# Nhật ký thực hiện T019

## 2026-11-14

- Đọc hợp đồng `docs/07`, `docs/45 §5`, hồ sơ `T016` (`planned`) và kiểm tra thực tế workspace: chưa có backend `services/api/` đang chạy hay trong repo.
- Rà soát code `T014`–`T018` để tái sử dụng `PersonalApiClient`, `FirebaseAuthGateway`, `GuestWorkspaceViewModel`, `StudyFocusViewModel`.
- Lập hồ sơ `T019` (`README.md`, `spec.md`, `plan.md`, `tests.md`, `worklog.md`, `handoff.md`) trước khi chỉnh sửa mã nguồn.
- Cập nhật `.gitignore` bỏ qua `.env`, `app/.env`, `*.env.local`; tạo `app/.env.example` (không secret) và `app/.env` (untracked local).
- Mở rộng `PersonalApiClient`, `AlarmConfig`, `StudyFocusSessionSnapshot`, `StudyFocusRecord`; tạo `AlarmSyncGateway`, `RemoteAlarmSyncGateway`, `DebugFixtureAlarmSyncGateway`, `PendingAlarmEventStore`, `StudyAiGateway`, `RemoteStudyAiGateway`, `DebugFixtureStudyAiGateway`, `study_ai_models.dart`.
- Tích hợp đồng bộ không chặn local vào `GuestWorkspaceViewModel`, `StudyFocusViewModel`, `TodayScreen`, `StudySpaceScreen`, `MindClockShellScreen`, và nối một `PersonalApiClient` duy nhất trong `app/lib/app.dart`.
- Mở rộng `LoopbackV1ContractServer` cho `/v1/alarms`, `/v1/alarms/{id}`, `/v1/study/sessions`, `/v1/study/help`, `/v1/study/sessions/{id}/finish` và viết `app/test/backend_integration_contract_test.dart` (`INT-TC-01..07`).
- Chạy kiểm tra công cụ: `where.exe flutter dart` báo thiếu SDK trên máy host Windows; chạy đạt `check_docs_links.py`, `check_task_records.py`, `git diff --check`, `git status --short` (xác nhận `app/.env` không untracked vào git) và quét tĩnh không có API key/Gemini URL/Bearer token/emoji trong `app/lib` và `app/.env.example`.
- Gắn trạng thái `T019` là `blocked` (chưa hoàn tất chạy `flutter test` và chạy thật với `services/api/` / PostgreSQL / Gemini / Firebase Auth / Android device).
