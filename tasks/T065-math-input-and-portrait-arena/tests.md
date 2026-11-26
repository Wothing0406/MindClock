# Kiểm thử

TC-01 ↔ AC-01: normalize phần trăm, đơn vị, phân số có tổng; render chỉ số dưới/mũ.
TC-02 ↔ AC-02: chèn ký hiệu tại selection và trường trình bày.
TC-03 ↔ AC-03: Android dọc và hai tài khoản. Chưa chạy.

## Kết quả thực tế 20/11/2026

Windows, Flutter SDK `.local-sdk/flutter`, chạy trong `app/`:

- `flutter test --no-pub test/math_formula_and_keypad_test.dart test/t065_math_notation_test.dart`: PASS 4 test, chạy lại sau khi đổi hàng ký hiệu cuộn ngang và thêm xem trước.
- `flutter test --no-pub -j 1 test/math_formula_and_keypad_test.dart test/t065_math_notation_test.dart test/solo_arena_widget_test.dart test/solo_arena_engine_test.dart test/arena_pvp_and_sprites_test.dart test/t064_arena_lobby_shop_and_leaderboard_test.dart`: PASS 18 test. PvP dùng fixture, không chứng minh hai tài khoản backend thật.
- `flutter test --no-pub test/t065_skill_hand_test.dart`: PASS 2 test: khóa thẻ trước khi giải đúng; sân thu gọn vẫn hiện hai tướng.
- `flutter analyze --no-pub`: PASS, No issues found (42.2 giây). Trước đó đã sửa optional parameter `dimmed` không còn caller sau khi bỏ danh sách nút chiêu cũ.
- `python scripts/check_docs_links.py`: PASS 603 Markdown. `python scripts/check_task_records.py`: PASS trước cập nhật bàn giao.
- Android E2E `flutter test --no-pub integration_test/arena_game_e2e_test.dart -d emulator-5554`: lần 1 FAIL ở build, `mergeDebugNativeLibs` AccessDeniedException với thư mục arm64-v8a rỗng có ReadOnly. Đã xác minh đường dẫn nằm trong app/build, gỡ ReadOnly và xóa riêng thư mục rỗng, chạy lại. Chưa tính PASS. Test cũng dùng auth/repository fixture.
- Máy Android vật lý và hai tài khoản online: chưa chạy, không nghiệm thu toàn bộ AC-03.

Kết thúc lượt kiểm tra: E2E lần 2 FAIL tại `packageDebugResources`, không xóa được các thư mục cache `merged.dir/values` và `stripped.dir`. Đã xác minh đường dẫn trong app/build, không có reparse point, gỡ ReadOnly và xóa riêng output đó. Lần 3 không trả log khởi động/build trong thời gian theo dõi; đã dừng bằng Ctrl+C, **không có kết quả PASS** và không để lệnh E2E tiếp tục chạy ngầm. Giả thuyết cần kiểm tiếp: quyền/cache build hoặc tiến trình công cụ trên Windows; chưa xác định nguyên nhân gốc cho lần 3.

Kiểm cuối 21/11/2026: `flutter analyze --no-pub` PASS (`0 issues`); `flutter test --no-pub -j 1` PASS **160/160** (gồm `t065_math_notation_test.dart`, `t065_skill_hand_test.dart`, `t064_arena_lobby_shop_and_leaderboard_test.dart`); Android E2E `flutter test --no-pub integration_test/arena_game_e2e_test.dart -d emulator-5554` **PASS** (`01:06 +1: All tests passed!`) sau khi dọn `app/build/app/intermediates` trước build; `dist/mindclock-debug.apk` (`163.19 MB`) build thành công. Hai tài khoản backend PvP 1v1 trên hai máy vật lý vẫn chưa chạy (phần này giữ trạng thái `verifying`).
