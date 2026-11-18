# Kế hoạch thực hiện T047 — G1 Luyện đơn

## Điểm bắt đầu

- Đã hoàn tất audit Flutter code hiện tại, `assets/game/manifest.json`, `scripts/check_game_assets.py` (PASS cơ học, `research_demo_only`), và xác nhận AVD `Medium_Phone_API_37.0` sẵn sàng.
- Cập nhật thực tế môi trường: `.local-sdk/flutter/bin/flutter.bat test --no-pub` chạy trọn vẹn toàn bộ 61 unit & widget test trên máy cục bộ (không còn bị chặn WDAC trong phiên này), kết hợp kiểm chứng trực tiếp bằng APK debug trên Android emulator `Medium_Phone_API_37.0`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo `app/lib/domain/game/solo_combat_engine.dart` (luật `solo-three-v0.1`, kiểm tra disabled reason, bot deterministic có `seed` & `replayLog`) và `app/lib/domain/game/solo_training_question_bank.dart` (27 câu approved cache 4 môn Toán/Vật lí/Tiếng Anh/Sinh học + bộ chấm luyện 3 trạng thái `correct|incorrect|uncertain`) | Biên dịch sạch, không lộ đáp án trước nộp | [x] |
| 2 | Tạo `app/lib/ui/features/arena/view_models/solo_arena_view_model.dart` điều phối trạng thái Hub / Setup / Battle / Summary, Reduce Motion, Bỏ qua hiệu ứng, Tắt âm mặc định và fallback lỗi asset | Đủ state cho toàn luồng G1 không RP/online giả | [x] |
| 3 | Bổ sung icon vector (`arena`, `shield`, `volumeOff`, `volumeOn`) trong `mindclock_icon.dart`, `AppStrings.navArena` trong `app_strings.dart`, tạo `arena_stage_widget.dart` & `arena_screen.dart` theo đúng `MindClockTheme` (0 raw hex, 0 emoji hệ thống, câu > sân) | Giao diện dọc rõ ràng, 320–390dp, chữ 200%, TalkBack | [x] |
| 4 | Nối tab `Đấu trường` (`nav-arena`) vào `mindclock_shell_screen.dart` và cập nhật `app/test/guest_flow_widget_test.dart` | Vào được Đấu trường → Luyện đơn từ thanh tab chính | [x] |
| 5 | Viết unit test bot/rule (`app/test/solo_arena_engine_test.dart`) và widget test luồng (`app/test/solo_arena_widget_test.dart`); chạy `dart analyze` và toàn bộ `flutter test --no-pub` | 0 lỗi analyze; 61/61 tests PASS | [x] |
| 6 | Build APK Android (`flutter build apk --debug`), chạy & kiểm chứng luồng Đấu trường → Luyện đơn trực tiếp trên Android emulator `Medium_Phone_API_37.0`, chụp ảnh bằng chứng và sửa triệt để lỗi emoji `↔` phát hiện qua ảnh thật | App chạy thật trên Android không crash/emoji, thao tác hết vòng Luyện đơn | [x] |
| 7 | Chạy `check_docs_links.py`, `check_task_records.py`, `check_game_assets.py`, rà diff (không raw hex/emoji/secret/WIP), cập nhật `tests.md`/`worklog.md`/`handoff.md`, stage đúng file T047, commit & push `origin/main` | Remote khớp SHA, phân định rõ phần thật vs placeholder | [x] |

## Rủi ro và đường lui

- **Rủi ro đóng gói nhầm art nghiên cứu:** Giữ nguyên `app/pubspec.yaml` không đóng gói `assets/game/`; mọi hình tướng ở G1 dùng vector placeholder theo `MindClockTheme` có nhãn rõ (`Đồ họa vector tạm (art gốc chờ duyệt G4)`).
- **Giới hạn emulator vs máy thật:** Đã kiểm chứng trên Android emulator `Medium_Phone_API_37.0` (API 37, 1080×2400); vẫn cần playtest bổ sung trên điện thoại Android vật lý ở cổng trước phát hành (theo `AGENTS.md §3`).
