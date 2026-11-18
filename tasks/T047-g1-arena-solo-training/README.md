# T047 — G1: Đấu trường Luyện đơn cục bộ (PvE) trên Flutter Android

- **Trạng thái:** `done`
- **Mục tiêu:** Mở lối vào **Đấu trường** trong khung điều hướng Flutter Android và hoàn thiện lát cắt dọc **G1 Luyện đơn** (`Đấu trường → Luyện đơn → chọn môn/tướng → giải câu approved có bước trình bày → chấm correct|incorrect|uncertain → chọn Đánh thường/Chiêu → xem HP/phản hồi → tổng kết`), dùng bot deterministic theo luật `solo-three-v0.1` có `seed/replay` gắn nhãn `Máy tập`, hoạt động offline từ bộ câu approved đã cache, không RP/MMR/leaderboard và không dựng đối thủ online giả.
- **Nguồn yêu cầu:** Prompt triển khai G1 (`docs/04-game/05-prompts-trien-khai-dau-truong.md`), yêu cầu người dùng ngày 2026-11-18, `GAME-06` (`docs/03-quality/05-ca-nghiem-thu.md`).
- **Chủ sở hữu/reviewer:** Flutter & Game Systems Architect.
- **Phạm vi file thực tế:**
  - `app/lib/domain/game/solo_combat_engine.dart`
  - `app/lib/domain/game/solo_training_question_bank.dart`
  - `app/lib/ui/features/arena/view_models/solo_arena_view_model.dart`
  - `app/lib/ui/features/arena/views/arena_stage_widget.dart`
  - `app/lib/ui/features/arena/views/arena_screen.dart`
  - `app/lib/ui/core/strings/app_strings.dart`
  - `app/lib/ui/core/widgets/mindclock_icon.dart`
  - `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`
  - `app/test/solo_arena_engine_test.dart`
  - `app/test/solo_arena_widget_test.dart`
  - `app/test/guest_flow_widget_test.dart`
  - `tasks/T047-g1-arena-solo-training/*`
- **Liên quan:** Xây tiếp trên nền catalog/models đã đưa vào Git ở `T046-fix-t037-combat-git-tracking`; không mở G2 (1v1 online), G3 (2v2) hay Ranked trong task này.
- **Source refs đã đọc:** `AGENTS.md §1–§5`, `docs/04-game/01-pvp-gdd.md §2–§3`, `docs/04-game/02-nhan-vat-asset.md §1–§5`, `docs/04-game/04-che-do-don-doi-va-asset-gap.md §1–§7`, `docs/04-game/05-prompts-trien-khai-dau-truong.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md`, `docs/02-engineering/06-ai-va-cham-bai.md`, `docs/03-quality/05-ca-nghiem-thu.md (GAME-06)`, `assets/game/manifest.json`, `scripts/check_game_assets.py`, `.agents/skills/flutter-custom-design-system/SKILL.md`, `app/lib/ui/features/guest_shell/views/mindclock_shell_screen.dart`.
- **Điểm tiếp tục:** Bước tiếp theo sau G1 là **G2 (Giao hữu 1v1 giữa hai tài khoản thật)** trên Android + FastAPI/PostgreSQL (cần hoàn tất xác minh live PostgreSQL của T038 và nối API matchmaking/round/settle) và **G4 (Duyệt quyền thương mại + thay đồ họa vector tạm bằng asset gốc/được duyệt quyền)**; đồng thời kiểm lại trải nghiệm trên điện thoại Android vật lý trước phát hành.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt (AC-01..AC-06); phân định rõ phần chạy thật vs vector placeholder chờ G4.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường (`61/61 flutter test PASS`, `dart analyze 0 issues`, APK debug chạy thật trên emulator `Medium_Phone_API_37.0`).
- [x] Docs chuẩn/API/schema không mâu thuẫn (chưa mở API online/Ranked trong G1).
- [x] `handoff.md` nêu cách kiểm tra, giới hạn emulator vs máy thật và điểm tiếp tục.
