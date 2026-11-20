# Đặc tả nhiệm vụ T063

## Vấn đề và kết quả mong muốn

Sau T062, các unit/widget test Flutter (98/98) và PG16 pytest (65/65) đã chạy qua và `dist/mindclock-debug.apk` đã được build, nhưng chưa chạy kiểm chứng Android Gradle Kotlin (`testDebugUnitTest`), chưa chạy lại `arena_game_e2e_test.dart` trên Android Emulator sau T062, và chưa cài APK T062 lên `emulator-5554` kết nối trực tiếp tới Docker API `10.0.2.2:8000` để ghi nhận bằng chứng UI chạy thật.

## Phạm vi

- **Trong phạm vi:** Chạy Gradle `:app:testDebugUnitTest` (với JBR JDK 17+); bổ sung bước chọn timer T062 và chạy `integration_test/arena_game_e2e_test.dart` trên `emulator-5554`; cài đặt APK T062 lên `emulator-5554`, kiểm chứng luồng kết nối API live + các màn T058–T062 trên UI sống; cập nhật ảnh chụp mới vào `test_demo_android/` & `docs/00-start/01-hien-trang.md`.
- **Ngoài phạm vi:** Không sửa `assets/game/`, không bật Ranked PvP, không phát hành keystore production.
- **Tài liệu chuẩn:** `AGENTS.md §3–§4`, `docs/03-quality/01-ke-hoach-kiem-thu.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Chạy Kotlin native unit tests (`:app:testDebugUnitTest`) | Pass 100% các test báo thức, lock-screen privacy, schedule widget provider & audio boundaries | TC-01 |
| AC-02 | Chạy `integration_test/arena_game_e2e_test.dart` trên `emulator-5554` | Đi trọn luồng Hub -> Setup (kèm chọn timer `30s/lượt` mới của T062) -> Loading -> Battle (đồng hồ đếm ngược hiển thị) -> Summary (0 RP) -> Replay | TC-02 |
| AC-03 | Cài APK `dist/mindclock-debug.apk` lên `emulator-5554` kèm Docker `api-api-1` đang chạy | App khởi chạy ổn định, kết nối được backend qua `10.0.2.2:8000`, chụp được screenshot UI sạch nhãn demo trên `test_demo_android/` | TC-03 |

## Hợp đồng và trường hợp biên

Không thay đổi hợp đồng API hoặc dữ liệu SQL; chỉ cập nhật E2E assertion & bằng chứng kiểm chứng emulator thật sau T062.

## Quyết định/mâu thuẫn

Không phát sinh mâu thuẫn; tuân thủ `AGENTS.md §3` (emulator không thay cho bước thử nghiệm 2 máy Android vật lý về Doze/permissions, sẽ ghi rõ giới hạn này trong `handoff.md`).
