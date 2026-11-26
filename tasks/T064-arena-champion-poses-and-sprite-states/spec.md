# Đặc tả nhiệm vụ T064

## Vấn đề và kết quả mong muốn

1. Trong repo trước đó (`1aa6af7` -> `assets/game/`) đã có đầy đủ **3 nhân vật gốc của dự án** (`ha-nhan` gấu trúc nón lá, `tuyet-dinh` kiếm sĩ tóc trắng, `han-boi-phap` pháp sư cõng tháp) cùng 8 hành động (`idle`, `basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`) chia frame chi tiết + `study-courtyard.webp` + `ui/avatars/` + `audio/*.wav`. Ở `T054`/`T061` từng tạo bộ chân dung khác vì `assets/game/` chờ quyết định chủ dự án. Nay chủ dự án đã gửi lại ảnh sprite gốc và yêu cầu khôi phục bộ nhân vật ban đầu này vào app Flutter, đồng thời bổ sung **Sảnh chờ (Arena Lobby)**, **Bảng xếp hạng (Leaderboard)** và **Daily Shop**.

## Phạm vi

- **Trong phạm vi:** Đóng gói runtime files từ `assets/game/` (bỏ thư mục `source/` raw) vào `app/assets/game/`; cập nhật `CombatCatalog` dùng đúng sprite + `nativeFacingRight` chuẩn (`ha_nhan: true`, `han_boi_phap: true`, `tuyet_dinh: false`); nâng cấp `ArenaSpriteActor` phát chuỗi frame `f00..f05.webp` / `f03.webp` khi ra đòn/chịu đòn/thắng và `idle.webp` khi đứng chờ (`poses/idle.webp` khi Reduce Motion); xây dựng **Sảnh chờ Đấu trường**, **Bảng xếp hạng (lọc môn/khối, opt-in, không dùng giờ dậy)** và **Daily Shop mỹ thuật (khung viền, avatar sưu tầm, hào quang — 0 pay-to-win, persist qua `LocalKeyValueStore`)**.
- **Ngoài phạm vi:** Không mở G3 (2v2), không mở nạp tiền thật hay bán tăng sát thương/HP/giáp; không xóa `app/assets/avatars/` để giữ tương thích toàn bộ test avatar đã qua.
- **Tài liệu chuẩn:** `AGENTS.md §3–§4`, `docs/04-game/01-pvp-gdd.md`, `docs/04-game/02-nhan-vat-asset.md`, `docs/04-game/03-rank-mua-va-kinh-te.md`.

## Yêu cầu kiểm chứng được

| ID    | Điều kiện                                                            | Hành vi hệ thống phải làm                                                                                                                                                                                                                                                       | Bằng chứng/test |
| ----- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| AC-01 | Khôi phục bộ 3 nhân vật gốc vào `app/assets/game/` & `CombatCatalog` | `Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Pháp` dùng ảnh/pose/frame `assets/game/characters/<slug>/...` (`native_facing` đúng: `ha-nhan` right, `han-boi-phap` right, `tuyet-dinh` left), sân đấu dùng `assets/game/maps/study-courtyard.webp`                                          | TC-01           |
| AC-02 | `ArenaSpriteActor` diễn hoạt đúng frame trong trận & Reduce Motion   | Phát chuỗi frame theo từng action (`basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`) + đứng `idle.webp`; khi `disableMotion == true` hiển thị tĩnh `poses/*.webp` sắc nét                                                                                         | TC-02           |
| AC-03 | Sảnh chờ Đấu trường (Arena Lobby)                                    | Hiển thị thẻ hồ sơ người chơi (Khung trang bị + Xu MindCoin + Huy hiệu), sân khấu nhân vật đang `idle` chuyển động thật có khung mỹ thuật, nút đổi tướng nhanh tại Sảnh, 3 cửa chế độ (`Luyện đơn`, `Đấu đơn 1v1`, `Đấu đội 2v2`), và điều hướng `Bảng xếp hạng` / `Daily Shop` | TC-03           |
| AC-04 | Bảng xếp hạng (Leaderboard) công bằng                                | Lọc theo Môn học (`Toán`, `Vật lí`, `Tiếng Anh`, `Sinh học`, `Tổng hợp`) và Khối lớp (`Lớp 10/11/12`), chỉ dựa trên điểm kiến thức & số lượt đúng (KHÔNG dùng giờ dậy), có nút bật/tắt `Hiển thị tên tôi trên bảng (Opt-in)`                                                    | TC-04           |
| AC-05 | Daily Shop chỉ bán mỹ thuật & lưu bền vững                           | Xoay vòng mặt hàng theo ngày (`Khung bậc`, `Avatar linh vật`, `Hào quang`), hiển thị rõ nhãn `Chỉ mỹ thuật · 0 tăng sát thương/HP`, kiếm Xu từ hoàn thành trận/luyện tập, kiểm tra trừ Xu khi mua & Trang bị ngay lên Sảnh chờ (không mua lặp hay âm số dư)                     | TC-05           |
| AC-06 | Chất lượng phát hành dev & Android Emulator                          | `flutter analyze` 0 issues, `RAW_HEX_COLOR_HITS=0`, `flutter test -j 1` pass toàn bộ, `arena_game_e2e_test.dart -d emulator-5554` pass, rebuild `dist/mindclock-debug.apk` & chụp screenshots mới Sảnh chờ / Bảng xếp hạng / Daily Shop / Trận đấu                              | TC-06           |

## Hợp đồng và trường hợp biên

- Giữ nguyên luật chiến đấu `solo-three-v0.1`: **mọi vật phẩm Daily Shop tuyệt đối `statBonus = 0`**, không tăng HP/Armor/Ward/Damage.
- Thư mục `assets/game/` vẫn cần chủ dự án rà soát thương mại cho các thành phần meme (`ha-nhan`) nếu thương mại hóa Play Store đại trà (ghi rõ trong `handoff.md`), còn về mặt kỹ thuật & đóng gói thử nghiệm hiện tại đã khôi phục theo yêu cầu trực tiếp của chủ dự án.
