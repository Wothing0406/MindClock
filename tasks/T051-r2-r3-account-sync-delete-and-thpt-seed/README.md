# T051 — R2/R3: Đồng bộ hồ sơ/TKB/consent, Xóa tài khoản từ Flutter & Ngân hàng câu THPT 10–12

- **Trạng thái:** `done`
- **Mục tiêu:**
  1. **Backend (`services/api`):**
     - Bổ sung bộ câu hỏi `published` (`source_type='approved_bank'`) cho **THPT Lớp 10, Lớp 11, Lớp 12** (`TOAN`, `TIENG_ANH`, `SINH_HOC`, `VAT_LY`, `HOA_HOC`) trong `seed.py` để học sinh THPT gọi `/v1/challenges/next` nhận đúng câu theo lớp/môn mà vẫn tương thích toàn bộ test hiện hành.
     - Vá lỗi `DELETE /v1/me` trong `routes/v1.py`: xóa sạch thêm dữ liệu PvP (`MatchQueue`, `RoundAction`, `RoundSubmission`, `MatchPlayer`) trước khi xóa `User` để không bị lỗi ràng buộc FK trên PostgreSQL khi user từng đấu PvP xóa tài khoản.
  2. **Flutter (`app/lib/`):**
     - Thêm `syncProfile`, `recordConsent`, `syncTimetable`, `deleteAccount` vào `PersonalFlowRepository`, `RemotePersonalFlowRepository` (`PATCH /v1/me`, `POST /v1/me/consent`, `PUT /v1/timetable`, `DELETE /v1/me`), `DebugFixturePersonalFlowRepository`, và `PersonalFlowViewModel`.
     - Sửa **2 bug thật** trong `TimetableProfileScreen`: (a) `_saveProfileChanges()` dùng `widget.viewModel.profile.copyWith(...)` để không làm mất `alias`, `avatarId`, `selfAssessments`, `confirmedPlan`; (b) sửa thông báo `_applyAiDraftTimetable()` không còn nói sai `Báo thức sáng đã tự động đồng bộ`, đồng thời gọi đồng bộ không chặn nếu đã đăng nhập.
     - Nối đồng bộ hồ sơ/TKB/consent từ `MindClockShellScreen` & `OnboardingSetupScreen` (lỗi mạng/offline không làm hỏng lưu local hay báo thức).
     - Bổ sung nút **Xóa tài khoản & dữ liệu trực tuyến** có xác nhận 2 bước trong `MeGuestScreen` (`me-delete-account-btn` → `me-delete-account-confirm`): gọi `DELETE /v1/me`, đăng xuất và xóa `ownerScopeKey` cục bộ của tài khoản đó, **nhưng vẫn giữ nguyên báo thức local trên máy**.
- **Nguồn yêu cầu:** Báo cáo rà soát 2026-11-18 (mục B5, B7), `AGENTS.md §1, §3, §4`, `docs/01-product/04-tai-khoan-quyen-rieng-tu.md`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md (ON-04..ON-06)`, `docs/02-engineering/04-hop-dong-api.md`.
- **Chủ sở hữu/reviewer:** Senior Mobile & Backend Systems Architect.
- **Phạm vi file dự kiến:**
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
  - `app/test/account_sync_and_delete_test.dart` (mới)
  - `tasks/T051-r2-r3-account-sync-delete-and-thpt-seed/*`
- **Source refs đã đọc:** `docs/01-product/04-tai-khoan-quyen-rieng-tu.md`, `docs/01-product/07-dang-ky-va-khoi-tao-lo-trinh.md`, `services/api/app/routes/v1.py`, `services/api/app/db/seed.py`, `services/api/app/db/models.py`, `app/lib/data/services/personal_api_client.dart`, `app/lib/ui/features/guest_shell/views/timetable_profile_screen.dart`, `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`.
- **Điểm tiếp tục:** Đã hoàn tất AC-01..AC-05, `75/75` Flutter tests PASS, `flutter analyze` 0 lỗi, `49/49` backend tests trên PostgreSQL 16 PASS. Bước tiếp theo theo lộ trình R5: `Học sâu` + server EXP ledger (`T052`) hoặc kiểm máy Android thật.

## Cổng trước coding

- [x] Đã đọc docs chuẩn và phát hiện 2 bug thật trong `TimetableProfileScreen` (`copyWith` mất dữ liệu onboarding & thông báo sai tự đồng bộ báo thức) và thiếu dọn bảng PvP trong `DELETE /v1/me`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-05).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có kết quả thực chạy trên PostgreSQL 16 + Flutter tests.
- [x] `handoff.md` ghi rõ SHA remote và điểm tiếp tục.
