# Đặc tả T047 — G1: Đấu trường Luyện đơn cục bộ (PvE)

## Vấn đề và kết quả mong muốn

### Hiện trạng mã Flutter & Asset trước G1 (bảng kiểm tái dùng / sửa / thiếu)

| Hạng mục | Hiện trạng thực tế trong repo | Đánh giá |
| --- | --- | --- |
| Catalog & Models combat (`app/lib/domain/game/combat_catalog.dart`, `combat_models.dart`) | Đã có 3 tướng `ha_nhan`, `tuyet_dinh`, `han_boi_phap` (alias `han_boi_thap`), rule `solo-three-v0.1`, skill/passive specs | **Tái dùng trực tiếp** |
| Chuẩn hóa đáp án (`app/lib/domain/services/answer_normalizer.dart`) | Hỗ trợ số thập phân `,`/`.`, phân số, LaTeX `\frac`, biến số, đơn vị | **Tái dùng trực tiếp** |
| Danh mục môn học (`app/lib/domain/models/subject_catalog.dart`) | Có sẵn mã/tên tiếng Việt các môn THPT | **Tái dùng trực tiếp** |
| Design system (`mindclock_theme.dart`, `mindclock_cards.dart`, `mindclock_pressable.dart`, `mindclock_icon.dart`) | Có `ThemeExtension` token, `MindClockCard`, `MindClockButton`, `MindClockStatusPill`, `MindClockPressable` | **Tái dùng + bổ sung 2 icon vector (đấu trường, khiên/âm thanh)** |
| Điều hướng Flutter (`mindclock_shell_screen.dart`) | Chỉ có 3 tab (`Hôm nay`, `Luyện tập`, `Tôi`), chưa có lối vào `Đấu trường`; `guest_flow_widget_test.dart` dòng 85 còn assert `Đấu trường` không tồn tại | **Sửa**: thêm tab thứ 4 `Đấu trường` (`nav-arena`) và cập nhật `guest_flow_widget_test.dart` |
| Engine luyện đơn local & Bot deterministic | Chưa có ở Dart (`app/lib/domain/game/`) | **Thiếu → Tạo mới** (`solo_combat_engine.dart`) khớp 100% luật `solo-three-v0.1` với seed & replay log |
| Ngân hàng câu approved cache cho luyện đơn + chấm 3 trạng thái | Chưa có bộ câu đa môn cache có `revision`/`rubricRevision`/`approvedBy`/`oneStepHintVi`/`gradingRubricStepsVi` | **Thiếu → Tạo mới** (`solo_training_question_bank.dart`) |
| UI Đấu trường màn dọc (Hub 3 mode, Setup, Battle, Summary) | Chưa có màn Flutter nào | **Thiếu → Tạo mới** (`arena_screen.dart`, `arena_stage_widget.dart`, `solo_arena_view_model.dart`) |
| Asset nghiên cứu `assets/game/manifest.json` | Checker pass cơ học (`3 characters, 21 clips, 9 projectile FX, 17 cues, map, 6 avatars, 7 frames, 6 badges`), `logical_stage_px=[360,380]`, `actor_root_px` left `(92,350)` / right `(268,350)`, facing `ha-nhan: right`, `han-boi-phap: right`, `tuyet-dinh: left`. Tuy nhiên `status="research_demo_only"`, `reference_rights="commercial rights not assessed; originals absent"`, chưa đóng gói trong `app/assets/` hay `pubspec.yaml` | **Chưa đủ quyền thương mại → KHÔNG đóng gói vào release Flutter**; dùng **placeholder vector chuẩn design system** có nhãn rõ, hỗ trợ Reduce Motion, tắt âm mặc định và fallback tĩnh khi lỗi asset (chờ task G4 duyệt quyền & đóng gói) |

### Kết quả mong muốn
Người dùng trên Android mở tab **Đấu trường** → chọn **Luyện đơn** → chọn môn (mặc định theo hồ sơ hoặc đổi) và tướng (3 tướng core) → xem luật/độ khó/seed → giải câu approved đã cache kèm bước trình bày bằng chữ → nhận kết quả 3 trạng thái (`correct` / `incorrect` / `uncertain`) → khi `correct` chọn `Đánh thường` / `Chiêu 1` / `Chiêu 2` (nút vô hiệu hiển thị lý do rõ ràng) → xem HP/Giáp/Chắn/Qi, hiệu ứng (hoặc bản tĩnh khi bật Reduce Motion / Bỏ qua hiệu ứng) và `Xem cách chấm` sau khi nộp → hoàn thành trận và xem tổng kết cục bộ kèm `replay` cùng `seed` (0 RP, không bảng xếp hạng, không đối thủ online giả).

## Phạm vi

- **Trong phạm vi:**
  - Lối vào tab `Đấu trường` (`nav-arena`) trong `MindClockShellScreen`.
  - Màn Hub Đấu trường gồm 3 thẻ mode rõ ràng: `Luyện đơn` (mở), `Đấu đơn 1v1` (khóa — chờ G2), `Đấu đội 2v2` (khóa — chờ G3); không có nút Ranked/Đấu hạng.
  - Luồng dọc Luyện đơn cục bộ (offline-first từ câu approved đã cache): chọn môn/tướng/bot/seed → giải câu có bước trình bày → chấm 3 trạng thái (`correct | incorrect | uncertain`) → chọn chiêu theo luật `solo-three-v0.1` → phản hồi + `Xem cách chấm` → tổng kết & replay.
  - Khung sân màn dọc ưu tiên câu & ô giải lớn hơn sân; 3 tướng dùng `CombatCatalog`, nhãn rõ `Máy tập`, số/chữ cho HP/Giáp/Chắn/Qi, Reduce Motion, `Bỏ qua hiệu ứng`, `Tắt âm` (mặc định tắt), và fallback an toàn khi asset lỗi.
  - Unit test bot/rule, widget test luồng đầy đủ và chạy kiểm chứng thực tế trên Android emulator.
- **Ngoài phạm vi:** Đấu đơn 1v1 online (G2), Đấu đội 2v2 (G3), Ranked/RP/MMR/leaderboard, đóng gói art nghiên cứu chưa duyệt quyền (`assets/game/`) vào release APK (G4), gọi Gemini tự quyết HP/đáp án.
- **Dữ liệu/role/quyền liên quan:** Chạy 100% cục bộ trên máy; không gửi điểm/RP online; không cần đăng nhập hay internet để luyện; không ảnh hưởng báo thức/chuỗi sáng.
- **Tài liệu chuẩn:** `docs/04-game/01-pvp-gdd.md §2–§3`, `docs/04-game/02-nhan-vat-asset.md`, `docs/04-game/04-che-do-don-doi-va-asset-gap.md §1, §2, §5, §6`, `docs/04-game/05-prompts-trien-khai-dau-truong.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md`, `docs/02-engineering/06-ai-va-cham-bai.md`, `docs/03-quality/05-ca-nghiem-thu.md (GAME-06)`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Mở app Flutter trên Android | Thanh điều hướng có tab `Đấu trường` (`nav-arena`); mở ra thấy 3 thẻ mode (`Luyện đơn` khả dụng, `Đấu đơn 1v1` và `Đấu đội 2v2` khóa có lý do), không có Ranked/đối thủ online giả | TC-01, TC-06 |
| AC-02 | Thiết lập Luyện đơn | Chọn được môn có câu approved đã cache (môn chưa có pool báo rõ lý do và gợi ý chọn môn khác), chọn 1 trong 3 tướng (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Pháp` có vai/nội tại/chiêu/cost), chọn độ khó bot & `Không giới hạn thời gian`, thấy `seed` và nhãn `Máy tập` | TC-02, TC-05 |
| AC-03 | Giải câu approved có bước trình bày (3 trạng thái chấm) | Không lộ đáp án/rubric trước khi nộp; nhập đáp án + bước giải đúng → `correct` (mở chọn chiêu); sai hoặc thiếu bước giải → `incorrect` + gợi ý 1 bước, cho thử lại hoặc tiếp tục lượt (không trừ điểm uy tín); đầu vào chưa rõ/mơ hồ → `uncertain` với nút `Sửa bài` hoặc `Đổi câu khác` không mất HP/lượt | TC-03, TC-05 |
| AC-04 | Combat engine `solo-three-v0.1` & Bot deterministic | Khớp luật `ward → armor → HP`, hồi sau sát thương, HP 0 không hồi cứu, nội tại 3 tướng, cấm Chiêu 2 Tuyệt Đỉnh round 6, secret round 3 +1 qi, Double KO hòa, tie-break round 6; nút chiêu vô hiệu ghi rõ lý do (`Thiếu Qi`, `Đã dùng`, `Cấm ở round 6`); cùng `seed` & chuỗi hành động tạo kết quả bot giống hệt nhau (deterministic replay) | TC-02, TC-04 |
| AC-05 | UI màn dọc, trợ năng, Reduce Motion, tắt âm & fallback asset | Câu & ô nhập chữ lớn hơn sân khi giải; HP/Giáp/Chắn/Qi có số/chữ; không emoji hệ thống; không hardcode màu hex ngoài `MindClockTheme`; bật `Reduce Motion` / `Bỏ qua hiệu ứng` / `Tắt âm` (mặc định tắt) và fallback khi asset lỗi không làm sai số HP hay crash | TC-05, TC-06 |
| AC-06 | Tổng kết lượt luyện & Offline | Hiện kết quả (Thắng/Thua/Hòa + lý do), `seed`, `rule_version: solo-three-v0.1`, nhật ký round, `Xem cách chấm`, nút `Luyện lại cùng seed`; ghi rõ `Lượt luyện cục bộ · 0 RP / Không xếp hạng`, hoạt động hoàn toàn offline | TC-04, TC-05, TC-06 |

## Hợp đồng và trường hợp biên

- `SoloTrainingQuestionBank` chỉ cung cấp câu có `approvedBy`, `revision >= 1`, `rubricRevision >= 1`, `status = published`, `sourceType = approved_bank`; môn chưa có pool (ví dụ `Ngữ văn`, `Lịch sử`, `Địa lí`, `Công nghệ`) hiển thị thông báo rõ và không cho khởi chạy câu giả.
- `ArenaStageWidget` sử dụng đồ họa vector chuẩn token `MindClockTheme` (placeholder có nhãn rõ) thay vì đóng gói `assets/game/` đang mang trạng thái `research_demo_only` chưa duyệt quyền thương mại; khi bật mô phỏng lỗi asset (`assetLoadFailed`) vẫn hiển thị thẻ tướng tĩnh đầy đủ hướng nhìn (trái/phải), anchor chân và thông số số học.

## Quyết định/mâu thuẫn

- **Điều hướng tab Đấu trường:** Trước đây ở T014 (`guest_flow_widget_test.dart:85`), tab `Đấu trường` bị ẩn hoàn toàn. Theo yêu cầu G1 hiện hành (`04-che-do-don-doi-va-asset-gap.md §1` & prompt người dùng), mở thêm tab thứ 4 `Đấu trường` (`nav-arena`) trong `MindClockShellScreen` và cập nhật đồng bộ `guest_flow_widget_test.dart` (Welcome vẫn không có Đấu trường; MainTabs có 4 tab gồm `nav-arena`).
- **Quyền asset nghiên cứu:** `assets/game/manifest.json` ghi `commercial rights not assessed; originals absent`, nên tuyệt đối không đóng gói `assets/game/` vào `app/pubspec.yaml` ở G1; tách rõ phần chạy thật (logic combat, bot seed/replay, chấm 3 trạng thái, điều hướng, UI dọc, Android APK) với phần placeholder (đồ họa vector tướng & âm game tắt mặc định chờ G4).
