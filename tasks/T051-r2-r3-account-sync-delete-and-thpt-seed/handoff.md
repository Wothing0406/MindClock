# Bàn giao nhiệm vụ T051

- **Trạng thái cuối:** `done`
- **Đã làm:**
  1. Bổ sung 8 câu `published` (`approved_bank`, `curriculum: gdpt_2018`, `rights_status: approved`) cho **THPT Lớp 10, 11, 12** (`TOAN`, `TIENG_ANH`, `SINH_HOC`) trong `services/api/app/db/seed.py`, đồng thời giữ câu seed Lớp 9 cũ tương thích test nền.
  2. Sửa `DELETE /v1/me` trong `services/api/app/routes/v1.py` xóa sạch 4 bảng PvP (`MatchQueue`, `RoundAction`, `RoundSubmission`, `MatchPlayer`) trước khi xóa `User`; thêm kiểm chứng thật trên PostgreSQL 16 sau trận PvP ở `test_pvp_matchmaking.py` và test grade THPT 10–12 ở `test_api_v1.py`.
  3. Mở rộng `PersonalFlowRepository`, `RemotePersonalFlowRepository`, `DebugFixturePersonalFlowRepository`, `PersonalFlowViewModel`, và `GuestWorkspaceRepository.clearScopedAccountData` / `GuestWorkspaceViewModel.clearDeletedAccountWorkspace` để đồng bộ `PATCH /v1/me`, `POST /v1/me/consent`, `PUT /v1/timetable`, `DELETE /v1/me`.
  4. Sửa 2 bug thật trong `TimetableProfileScreen` (bảo toàn `alias`/`avatarId`/`selfAssessments`/`confirmedPlan` khi lưu hồ sơ; sửa thông báo AI TKB giữ nguyên báo thức cũ), nối đồng bộ không chặn ở `MindClockShellScreen` (`AuthScreen` + `OnboardingSetupScreen`), và thêm xác nhận 2 bước **Xóa tài khoản & dữ liệu trực tuyến** ở `MeGuestScreen` giữ nguyên báo thức local trên máy.
- **File/code/docs thay đổi:**
  - `services/api/app/db/seed.py`
  - `services/api/app/routes/v1.py`
  - `services/api/tests/test_api_v1.py`
  - `services/api/tests/test_pvp_matchmaking.py`
  - `app/lib/data/repositories/guest_workspace_repository.dart`
  - `app/lib/domain/services/personal_flow_repository.dart`
  - `app/lib/data/repositories/remote_personal_flow_repository.dart`
  - `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`
  - `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`
  - `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/timetable_profile_screen.dart`
  - `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/test/account_sync_and_delete_test.dart`
  - `tasks/T051-r2-r3-account-sync-delete-and-thpt-seed/*`
- **Test đã chạy (2026-11-18, Windows PG 16 `127.0.0.1:5432` & Flutter SDK cục bộ):**
  - `pytest tests/test_api_v1.py tests/test_pvp_matchmaking.py -vv -x`: **24 passed in 19.43s**
  - `pytest tests/test_answer_normalizer.py tests/test_api_v1.py tests/test_auth_jwt.py tests/test_migrations_and_data_invariants.py tests/test_product_mobile.py tests/test_pvp_matchmaking.py tests/test_timetable_image_parser.py -q`: **49 passed in 19.03s** (0 skipped)
  - `flutter analyze --no-pub`: **No issues found**
  - `flutter test`: **75/75 PASS**
  - Quét `Color(0x` ngoài `MindClockTheme`: **RAW_COLOR_HITS: 0**
  - `python scripts/check_docs_links.py`: **PASS local links in 517 Markdown files**
  - `python scripts/check_task_records.py`: **Task records OK**
- **Rủi ro còn lại:**
  - Chưa chạy APK/live Firebase Auth Email-Password thật trên máy Android vật lý (cần bật provider trên Firebase Console và chạy smoke test trên máy thật ở lát R6/R8).
  - R5 (`Học sâu` + server EXP ledger) vẫn cần triển khai ở task kế tiếp `T052`.
- **Điểm tiếp tục chính xác:** Mở task `T052` cho lát R5 (nối `StudyFocusViewModel` với `/v1/study/sessions`, `/help`, `/finish` + server EXP ledger & xác minh DB PostgreSQL 16).
- **Git:** Đang chuẩn bị commit & push lên `origin/main` (sẽ cập nhật SHA sau push).
