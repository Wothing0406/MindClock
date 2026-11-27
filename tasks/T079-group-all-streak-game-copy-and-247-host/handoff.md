# Bàn giao nhiệm vụ T079

- **Trạng thái cuối:** `verifying` (đã xong toàn bộ code, docs, test SQLite & 171 Flutter widget tests; chưa chạy PostgreSQL Docker, chưa deploy thật lên Render/Neon và chưa phân phối APK trực tiếp từ máy local do thiếu `firebase login` / release keystore).
- **Đã làm:**
  1. **Streak nhóm = 100% thành viên active hoàn thành trong ngày (`Chuỗi 1` → `Chuỗi 100+`):** `CommitmentGroupService._pet_summary` yêu cầu `active_member_ids.issubset(uids)` theo từng `local_date`, giữ nguyên chuỗi hôm qua trong khi chờ thành viên còn lại của hôm nay, trả thêm `bestStreakDays`, `memberCount`, `allMembersDoneToday`, `streakMilestoneLabelVi`; cập nhật `CommitmentPetSummary`, `TodayPetCard`, `CommitmentGroupSheet`, `PetShareCard`.
  2. **Làm sạch ngôn từ game trong Đấu trường:** Thay toàn bộ nhãn kỹ thuật/demo/thử nghiệm ở `ArenaScreen`, `ArenaLobbyPanel`, `ArenaPvpLobby` (bỏ `Tướng gốc`, `G1/G2/G3`, `bộ pose`, `0 RP`, `solo-three-v0.1`, `playtest`, `bảng thử nghiệm`).
  3. **Kiến trúc host 24/7 + tải APK Android ổn định:** Thêm Blueprint `render.yaml` (`mindclock-api` Starter + health check `/v1/health`, biến Firebase & Gemini giữ bí mật) và tài liệu vận hành `docs/03-quality/06-trien-khai-247-va-tai-apk.md` (Render Starter / VPS Singapore + Neon PostgreSQL, Firebase App Distribution cho nhóm 10–100 tester, GitHub Releases / Cloudflare R2 cho link tải công khai `.apk`, quy trình ký cố định release keystore).
  4. **Khớp regression T076/T062/Solo Arena & thêm test T079:** Sửa `t076_mvp_hub_and_backend_auth_test.dart` (`['math', 'physics']`), `solo_arena_widget_test.dart`, `t062_offline_bank_alarm_and_arena_timer_test.dart`, thêm `test_group_streak_requires_all_active_members_and_accumulates_days` và `t079_group_streak_and_clean_arena_test.dart`.
- **File/code/docs thay đổi:**
  - `services/api/app/services/commitment_group_service.py`
  - `services/api/tests/test_commitment_groups_and_pet.py`
  - `app/lib/domain/models/commitment_group_models.dart`
  - `app/lib/ui/features/community/views/{today_pet_card.dart,commitment_group_sheet.dart,pet_share_card.dart}`
  - `app/lib/ui/features/arena/views/{arena_lobby_panel.dart,arena_screen.dart,arena_pvp_lobby.dart}`
  - `app/test/{t076_mvp_hub_and_backend_auth_test.dart,solo_arena_widget_test.dart,t062_offline_bank_alarm_and_arena_timer_test.dart,t079_group_streak_and_clean_arena_test.dart}`
  - `render.yaml`, `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, `docs/03-quality/06-trien-khai-247-va-tai-apk.md`, `tasks/T079-group-all-streak-game-copy-and-247-host/*`
- **Test đã chạy (27/11/2026, local Windows):**
  - `services\api\.venv\Scripts\python.exe -m pytest -q` → `89 passed, 10 skipped` (Docker chưa bật nên 10 test PostgreSQL opt-in skip).
  - `dart analyze . --fatal-infos` → `No issues found!`; `dart fix --dry-run` → `Nothing to fix!`; `flutter analyze --no-pub` → `No issues found!`; `flutter test --no-pub -j 1` → `171 passed`.
- **Rủi ro / Việc chưa chạy:**
  - Chưa chạy pytest với PostgreSQL thật, chưa deploy `render.yaml` lên Render + Neon, chưa tạo release keystore cố định, chưa đăng nhập Firebase CLI (`firebase login`) để upload `.apk` lên Firebase App Distribution.
  - Repo đang có sẵn thay đổi ngoài phạm vi (`.idea/*` và các task trước chưa commit) nên **không** tự ý `git commit`/`push` theo yêu cầu trước đó (`không push lên github` và giữ sạch WIP).
- **Điểm tiếp tục chính xác:**
  1. Bật PostgreSQL / Neon URL, chạy Alembic migration (`alembic upgrade head`) và deploy `render.yaml` lấy URL HTTPS `https://<service>.onrender.com`.
  2. Chạy `npx -y firebase-tools@latest login` trên máy có trình duyệt, sau đó chạy `scripts/distribute_apk_firebase.ps1 -ApiBaseUrl "https://<service>.onrender.com"` với release keystore đã ký cố định.
  3. Kiểm tra lại `app/test` với URL backend thật trên 2 máy Android thật (nhóm 2 người cùng hoàn thành trong ngày -> kiểm tra `Chuỗi 1`, nhảy sang ngày mới -> `Chuỗi 2`).
