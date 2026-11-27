# T079 — Streak Nhóm Đủ Thành Viên (Chuỗi 1→100), Ngôn Từ Game Thuần & Kiến Trúc Host 24/7 Tải APK

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Đổi luật **Streak nhóm** trong `CommitmentGroupService._pet_summary` sao cho một ngày chỉ được cộng `+1` chuỗi khi **toàn bộ thành viên active của nhóm đều đã hoàn thành** hoạt động hợp lệ trong ngày (`study_care`, `morning_challenge`, `daily_report`), cộng dồn liên tiếp theo ngày kiểu TikTok (`Chuỗi 1`, `Chuỗi 2`, ..., `Chuỗi 100`) và hiển thị rõ tiến độ `Hôm nay X/Y người` trên app.
  2. Loại bỏ toàn bộ ngôn từ kỹ thuật/demo/thử nghiệm trong Đấu trường (`Tướng gốc`, `G1/G2/G3`, `0 RP`, `solo-three-v0.1`, `bộ pose`, `bảng thử nghiệm`, `playtest`, `chống pay-to-win`, `mô phỏng`) để UI đọc như một game đấu trí hoàn chỉnh.
  3. Bổ sung Blueprint triển khai backend `render.yaml` và tài liệu chuẩn `docs/03-quality/06-trien-khai-247-va-tai-apk.md` cho phương án host API 24/7 ổn định + phân phối APK ký số cho người dùng Android thật.
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `services/api/app/services/commitment_group_service.py`
  - `services/api/tests/test_commitment_groups_and_pet.py`
  - `app/lib/domain/models/commitment_group_models.dart`, `app/lib/data/debug/debug_fixture_community_repository.dart`
  - `app/lib/ui/features/community/views/{today_pet_card.dart,commitment_group_sheet.dart,pet_share_card.dart}`
  - `app/lib/ui/features/arena/views/{arena_screen.dart,arena_lobby_panel.dart,arena_pvp_lobby.dart}`
  - `app/test/{solo_arena_widget_test.dart,t062_offline_bank_alarm_and_arena_timer_test.dart,t079_group_streak_and_clean_arena_test.dart}`
  - `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`, `docs/03-quality/06-trien-khai-247-va-tai-apk.md`, `render.yaml`
- **Liên quan:** Kế thừa `T074`, `T075`, `T077`, `T078`.
- **Source refs đã đọc:** `services/api/app/services/commitment_group_service.py`, `app/lib/ui/features/arena/views/{arena_screen.dart,arena_lobby_panel.dart,arena_pvp_lobby.dart}`, `app/lib/ui/features/community/views/{today_pet_card.dart,commitment_group_sheet.dart,pet_share_card.dart}`.
- **Điểm tiếp tục:** Đã xong code, test SQLite/widget & docs; chờ deploy `render.yaml` + PostgreSQL, cấu hình `MINDCLOCK_API_BASE_URL` HTTPS, tạo Android release keystore và `firebase login` để phát APK qua Firebase App Distribution (trước khi git commit/push).

## Cổng trước coding

- [x] Đã đọc code hiện tại của `CommitmentGroupService`, `ArenaScreen`, `ArenaLobbyPanel`, `ArenaPvpLobby` và các test liên quan.
- [x] Đã rà lại ảnh hưởng tới `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và test SQLite/Flutter widget xanh (`89 passed, 10 skipped` PostgreSQL Docker opt-in chưa bật; `171 passed` Flutter).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] Docs chuẩn được cập nhật đồng bộ.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
