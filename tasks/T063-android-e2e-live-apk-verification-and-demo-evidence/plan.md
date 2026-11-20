# Kế hoạch thực hiện T063

## Điểm bắt đầu

- Đã có `dist/mindclock-debug.apk` (`152.37 MB` từ T062), Docker `api-api-1` & `api-postgres-1` healthy trên `localhost:8000`, và Android Emulator `emulator-5554` đang chạy.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chạy Gradle `.\gradlew testDebugUnitTest` với JBR JDK của Android Studio | Kotlin unit tests pass toàn bộ (12/12 `:app` tests PASS) | [x] |
| 2 | Cập nhật kiểm tra timer `30s/lượt` trong `app/integration_test/arena_game_e2e_test.dart` và chạy trên `emulator-5554` | `arena_game_e2e_test.dart` pass trên emulator (`02:24 +1`) | [x] |
| 3 | Cài `dist/mindclock-debug.apk` lên `emulator-5554`, kiểm chứng kết nối `/v1/health` + tương tác màn Đấu trường/Luyện tập & chụp ảnh mới vào `test_demo_android/` | Ảnh/log thực tế sạch nhãn demo (`19`→`22`), Docker API OK | [x] |
| 4 | Chạy `check_docs_links.py`, `check_task_records.py`, cập nhật `docs/00-start/01-hien-trang.md`, commit & push lên `origin/main` | Remote SHA khớp và `handoff.md` cập nhật đầy đủ | [x] |

## Rủi ro và đường lui

- Nếu bật timer `30s` trong `arena_game_e2e_test.dart` làm `pumpAndSettle` chờ timer định kỳ: dùng `SoloArenaViewModel(initialSeed: 20261119, enableRoundTimer: false)` để test UI đồng hồ `Thời gian còn: 30s` mà không treo `pumpAndSettle`, vẫn kiểm chứng widget & state đồng hồ thật trên APK E2E.
