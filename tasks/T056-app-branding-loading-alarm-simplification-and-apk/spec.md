# Đặc tả nhiệm vụ T056

## Vấn đề và kết quả mong muốn

1. **Thiếu nhận diện khởi động & chuyển cảnh tải:** App Android chưa có `ic_launcher` (`mipmap-*`), chưa có native splash screen và màn boot Flutter chỉ hiện chữ thô `'Đang tải dữ liệu trên máy...'`; Đấu trường G1 nhảy trực tiếp từ `setup` sang `battle` không có màn Loading Game & precache asset.
2. **Màn Cấu hình báo thức (`S06`, ảnh `11_alarm_config_challenge_and_sound.png`) còn rườm rà:** Hiện vẫn hiển thị danh mục chọn 11 môn thủ công và bộ chọn `Báo thức thường` vs `Báo thức thử thách`, trong khi người dùng tải MindClock để dùng báo thức thử thách và muốn AI/hệ thống tự lấy môn theo hồ sơ tổ hợp + lịch học buổi sáng hôm đó.
3. **Cần kiểm thử Game trên môi trường ảo + báo cáo đầy đủ & xuất APK cài thử điện thoại:** Cần có E2E game test chạy trên `emulator-5554`, báo cáo test game chi tiết trong `test_demo_android/` và script/file APK rõ cách truyền URL host backend.

## Phạm vi

- **Trong phạm vi:**
  - Tạo icon launcher đa độ phân giải + Adaptive Icon từ `assets/brand/mindclock-mark.svg`, gắn `android:icon` / `android:roundIcon` trong `AndroidManifest.xml`.
  - Tạo Android `LaunchTheme` (`launch_background.xml`, `styles.xml`) + `MindClockBrandMark` + Flutter Boot Screen (`MindClockShellScreen`).
  - Thêm `ArenaSection.loading` (`SoloArenaViewModel` + `ArenaScreen`) với precache asset sân đấu/tướng/chiêu, thanh tiến trình mượt và tôn trọng `Reduce Motion`.
  - Tinh gọn `AlarmConfigScreen`: xóa card chọn môn thủ công & card chọn chế độ thường/thử thách; mặc định mọi chuông mới tạo là `AlarmMode.challenge` + `AlarmSubjectRule.todaySchedule` (hiển thị card tóm tắt cơ chế tự động từ hồ sơ & TKB buổi sáng, vẫn giữ **Dừng khẩn cấp 1 chạm** không bị khóa).
  - Thêm `app/integration_test/arena_game_e2e_test.dart`, chạy test trên `emulator-5554`, cập nhật ảnh/báo cáo `test_demo_android/`, và xuất `app-debug.apk` kèm `scripts/build_android_apk.ps1`.
- **Ngoài phạm vi:** Không mở khóa G2/G3/Ranked PvP, không tạo keystore Play Store production ở repo công khai, không xóa `AlarmMode` khỏi domain/backend (giữ tương thích ngược dữ liệu cũ).
- **Dữ liệu/role/quyền liên quan:** Không thêm quyền OS mới; tiếp tục giữ `Dừng khẩn cấp` 1 chạm kể cả offline/lỗi AI.
- **Tài liệu chuẩn:** `AGENTS.md §2–3`, `docs/01-product/03-he-thiet-ke.md`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/04-game/02-g1-luyen-don-cuc-bo.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Đóng gói Android APK | Có đủ `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`, `mipmap-anydpi-v26/ic_launcher.xml` từ `mindclock-mark.svg`, `AndroidManifest.xml` gắn `android:icon` và `LaunchTheme` (`launch_background.xml`) | TC-01, TC-06 |
| AC-02 | Mở app khi chưa nạp xong dữ liệu | Hiển thị màn boot đồng bộ thương hiệu (`MindClockBrandMark`, tên app, trạng thái tải ngắn, không màu hardcode ngoài theme, chịu được `320dp` / `200%` textScale) | TC-02 |
| AC-03 | Mở `AlarmConfigScreen` (tạo mới hoặc sửa) | Không còn danh sách chọn 11 môn thủ công hay lựa chọn `Báo thức thường / thử thách`; tự động lưu `AlarmMode.challenge` + `AlarmSubjectRule.todaySchedule` (tự động từ hồ sơ & TKB buổi sáng) và giải thích rõ vẫn có Dừng khẩn cấp 1 chạm | TC-03 |
| AC-04 | Vào Đấu trường G1 bấm bắt đầu / luyện lại | Đi qua màn `ArenaSection.loading` (precache asset, hiện đối đầu 2 tướng + sân đấu + nút `Vào trận ngay` / auto chuyển vào `ArenaSection.battle`), tương thích Reduce Motion và màn nhỏ `320dp` | TC-04 |
| AC-05 | Chạy game trên Android Emulator thật & xuất APK | `integration_test/arena_game_e2e_test.dart` chạy pass trên `emulator-5554`; có báo cáo game trong `test_demo_android/` và file APK + `scripts/build_android_apk.ps1` hỗ trợ `--ApiBaseUrl` | TC-05, TC-06 |

## Hợp đồng và trường hợp biên

- Giữ nguyên enum `AlarmMode` (`normal`, `challenge`), `AlarmSubjectRule`, Kotlin bridge `NativeAlarmModels.kt` và wire schema `/v1/alarms` để không làm gãy dữ liệu cũ đã lưu trên DB/SharedPreferences hay test contract T032/T051. Khi `MorningQuestionSelector` chạy offline hoặc user chưa có TKB, vẫn fallback tự động lấy môn ưu tiên / môn đầu trong hồ sơ (`selectedSubjectCodes`) hoặc câu dự phòng đã duyệt, không kẹt chuông.
- Ở `ArenaSection.loading`, nếu thiết bị bật `Reduce Motion` (`disableAnimations`) hoặc người dùng bấm `Vào trận ngay`, vẫn vào trận ngay không chờ timer nhân tạo; trong `widget_test`, `pumpAndSettle()` chuyển sạch sang `battle` không treo timer vô hạn.

## Quyết định/mâu thuẫn

- **Cập nhật UX `S06` (`AlarmConfigScreen`):** Yêu cầu người dùng hiện tại ưu tiên auto chế độ Thử thách + tự động chọn môn theo hồ sơ & TKB buổi sáng, loại bỏ chọn môn/chọn chế độ thừa trên màn `S06`. Quyết định giữ tương thích backend/domain enum nhưng đơn giản hóa 100% UI đặt chuông mới và cập nhật ghi chú vào `docs/01-product/09-giac-ngu-va-bao-thuc.md` theo `AGENTS.md §2`.
