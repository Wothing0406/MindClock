# Kế hoạch thực hiện T064

## Điểm bắt đầu

- Đã xác nhận `assets/game/` chứa 204 runtime files (`.webp`, `.svg`, `.wav`, tổng `9.73 MB`) cho `ha-nhan`, `tuyet-dinh`, `han-boi-phap`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến                                                                                                                                                                           | Điều kiện xong                                                              | Trạng thái |
| ---- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ---------- |
| 1    | Copy runtime files từ `assets/game/` sang `app/assets/game/` (loại trừ `source/`) & cập nhật `app/pubspec.yaml`                                                                                    | Đủ 204 asset khai báo sạch trong Flutter bundle                             | [x]        |
| 2    | Cập nhật `CombatCatalog` + `ArenaSpriteActor` + `ArenaStageWidget` phát animation theo frame (`basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`, `idle`) & map `study-courtyard.webp` | Đúng 3 nhân vật gốc, lật mặt đối diện chuẩn, Reduce Motion sạch             | [x]        |
| 3    | Tạo model & store cho Ví Xu MindCoin, Daily Shop mỹ thuật, Trang bị khung/hào quang, và Bảng xếp hạng opt-in (`arena_lobby_models.dart`, `arena_cosmetic_store.dart`)                              | Lưu bền vững qua `LocalKeyValueStore`, 0 pay-to-win, không dùng giờ dậy     | [x]        |
| 4    | Nâng cấp `ArenaScreen` thành Sảnh chờ game hoàn chỉnh + tab/view `Bảng xếp hạng` + `Daily Shop` + cập nhật `ArenaPvpLobby`                                                                         | UI responsive 320dp/390dp 200%, chuyển mượt giữa Sảnh/Shop/BXH/Setup/Battle | [x]        |
| 5    | Viết test, chạy `flutter analyze`, `flutter test`, build APK, chạy `arena_game_e2e_test.dart` trên `emulator-5554`                                                                                 | Flutter analyze 0 lỗi, 160/160 unit/widget pass, E2E pass trên API 37       | [x]        |
| 6    | Đợi xác nhận người dùng trước khi commit/push (`Do not commit or push code unless explicitly authorized`)                                                                                          | Giữ trạng thái `verifying` đến khi commit & xác minh `origin/main`          | [ ]        |
