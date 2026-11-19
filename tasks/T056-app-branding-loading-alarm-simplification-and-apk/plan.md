# Kế hoạch thực hiện T056

## Điểm bắt đầu

- Đã có `assets/brand/mindclock-mark.svg` từ `T034`, `flutter test` (`82/82`), `:app:testDebugUnitTest` (`10/10`), Docker FastAPI + PG16 (`:8000`), và Android Emulator `emulator-5554` đang kết nối.
- `app/android/app/src/main/res/` chưa có `mipmap-*` và `launch_background.xml`. `AlarmConfigScreen` đang hiển thị card chọn 11 môn và card chọn chế độ thường/thử thách.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Xuất bộ icon Android (`mipmap-*` PNG 48–192px + Adaptive VectorDrawable + `ic_launcher_round`), `launch_background.xml`, `styles.xml`, cập nhật `AndroidManifest.xml` | Có đủ asset icon/splash hợp lệ trong `res/`, `assembleDebug` & unit tests Android không lỗi | [x] |
| 2 | Tạo `MindClockBrandMark` (`CustomPaint` theo tỷ lệ `mindclock-mark.svg` dùng màu theme), nâng cấp boot loading ở `MindClockShellScreen`, thêm `ArenaSection.loading` ở `SoloArenaViewModel` & `ArenaScreen` | Có màn boot app & màn loading vào game, `RAW_COLOR_HITS: 0` | [x] |
| 3 | Tinh gọn `AlarmConfigScreen` (xóa chọn môn & chọn chế độ thường/thử thách, mặc định auto Thử thách + `todaySchedule` từ hồ sơ & TKB), dọn code/string thừa, cập nhật `docs/01-product/09-giac-ngu-va-bao-thuc.md` & `docs/00-start/01-hien-trang.md` | Màn đặt báo thức sạch, auto lưu `AlarmMode.challenge` + `todaySchedule` | [x] |
| 4 | Cập nhật unit/widget tests (`guest_flow_widget_test.dart`, `solo_arena_widget_test.dart`, v.v.) và viết `app/integration_test/arena_game_e2e_test.dart` | `flutter analyze`, `flutter test`, Kotlin unit tests xanh | [x] |
| 5 | Thêm `scripts/build_android_apk.ps1`, chạy E2E game test & test live trên `emulator-5554`, cập nhật `test_demo_android/` (`game_emulator_test_report.md` + ảnh mới) & build APK | E2E game pass trên `emulator-5554`, APK xuất thành công, repo hygiene scripts PASS | [x] |

## Rủi ro và đường lui

- Windows Defender / IDE indexer giữ lock trong `app/build/app/intermediates`: `scripts/build_android_apk.ps1` tự dọn thư mục `intermediates` trước khi gọi `flutter build apk` nên build ổn định lại.
- Timer im lặng ở `ArenaSection.loading` khiến `pumpAndSettle` bỏ qua; đã chuyển sang `AnimationController` thực tế vừa chạy thanh tiến trình mượt 60fps vừa chuyển cảnh chắc chắn cả ngoài app lẫn trong test.
