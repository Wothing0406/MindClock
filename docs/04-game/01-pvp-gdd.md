# Đấu trường 1v1 — GDD và networking v0.1

**Trạng thái:** đặc tả thử nghiệm **chưa có PvP Flutter/API live**. Mở giao hữu sau khi câu/chấm/consent đạt [cổng R8](../00-start/02-lo-trinh.md); ranked/rank/coin sau playtest và quyền. Không biến game thành cách tắt báo thức hoặc lấy giờ dậy xếp hạng. [PRD](../01-product/01-prd.md), [content](../02-engineering/05-ngan-hang-cau-hoi.md), [AI/chấm](../02-engineering/06-ai-va-cham-bai.md).

Tài liệu này là luật **1v1**. Ba cửa vào `Luyện đơn` (PvE), `Đấu đơn` (1v1) và `Đấu đội` (2v2) cùng asset gap ở [modes](04-che-do-don-doi-va-asset-gap.md); [prompt triển khai](05-prompts-trien-khai-dau-truong.md) buộc làm theo từng lát cắt. Team rule hiện là nháp playtest, không được dùng để mở ranked.

## 1. Vòng chơi và ghép trận

Người chơi opt-in, chọn môn/khối/chương trình/nhân vật. Server ghép **một môn chung** cùng khối/curriculum/content pool version và độ khó đã duyệt; không cần trùng toàn bộ tổ hợp. Hai bên nhận **cùng question ID + revision + rubric + deadline** mỗi round, loại câu tự luận ngắn đã duyệt/chuyển thể và nộp đáp án cùng một bước trình bày bằng chữ hoặc ảnh mới tùy mode. Server chấm cả hai trước khi cho chọn action. Không phát câu bằng Gemini lúc ghép/trong round. Bài, lựa chọn và grade của đối thủ không lộ trước reveal.

Chỉ khoanh A/B/C/D không đủ kích hoạt skill; trắc nghiệm nếu có phải kèm lý do hợp lệ và rubric. Giới hạn thời gian đủ để viết một bước, không thưởng sát thương vì nộp sớm. Ảnh thư viện không dùng trong ranked; camera/permission lỗi vẫn có đường chữ nếu luật mùa cho phép, nếu không thì round void chứ không tự xử thua. Anti-abuse gồm pool đa dạng, câu cùng phiên bản, duplicate detection, rate/idempotency, review trường hợp bất thường; **không thể ngăn điện thoại thứ hai hay người khác giúp tuyệt đối**. AI không gắn nhãn gian lận dựa trên nét chữ/tốc độ một mình.

```text
opt-in → queue → match_found → round_question → submit → grading_both
→ action_window → settle_server → event_stream → next_round | result
```

Trận tối đa 6 round. Khi AI `uncertain`, câu lỗi, model/rubric đổi giữa trận hoặc một bên mất điều kiện công bằng: round/trận `needs_review`/`void`; ranked không đổi RP. Reconnect lấy snapshot + event sequence, không cho client tự tính lại HP/rank. Giao hữu trước ranked.

## 2. Luật combat v0.1 (chỉ để playtest)

- Mỗi bên `HP=100`, `armor=50`, `ward=0`, `qi=0`; ward tối đa 20 và hết theo round, HP/armor không vượt mức đầu. Không có chí mạng/né ngẫu nhiên, vật phẩm tăng sức mạnh hoặc loại sát thương “phép” riêng.
- Đúng rõ mới kích hoạt action; sai/timeout không damage/buff và không phạt học tập. Trả lời đúng 1 câu chuẩn xác cho phép thực hiện **Đánh thường (28 damage, 0 qi)** và tích lũy **+1 qi** sau settle (tối đa 3 qi); khi đủ qi (1 qi cho **Chiêu 1**, 2 qi cho **Chiêu 2**), người chơi mới được kích hoạt các chiêu thức đặc biệt (có hiệu ứng sprite + FX + SFX riêng từng tướng). Secret round đúng +1 qi thêm **sau** round. Qi round này không dùng ngay round đó. Action chọn trong 6 giây sau khi cả hai grade rõ; không chọn → Đánh thường, skill thiếu qi/hết lượt phải báo lỗi để chọn lại.
- Đánh thường `28 damage`, 0 qi. Mỗi skill dùng tối đa 1 lần/trận. Damage đồng thời từ snapshot đầu round: `ward → armor → HP`, buff chắn trong round chặn damage cùng round; hồi sau damage, HP 0 không hồi cứu. Cả hai HP 0 hòa; sau round 6 so HP, rồi armor, còn bằng hòa. Tốc độ nộp không cộng damage/RP.
- Secret round 3 hoặc 5 do server chọn trước bằng seed/pool khóa; cùng câu cho hai bên, bonus qi cosmetic, không damage thêm. Thiếu pool chuẩn thì bỏ secret và báo trước.

| Nhân vật (ID tạm) | Vai/đánh đổi | Nội tại | Chiêu 1 · 1 qi | Chiêu 2 · 2 qi |
| --- | --- | --- | --- | --- |
| Hà Nhân `ha_nhan` | Bền bỉ, burst thấp | 2 round đúng liên tiếp hồi 8 armor sau settle, tối đa 2 lần | Bước Vững: 25 damage + hồi 6 armor | Tĩnh Tâm Phản Kích: 32 damage + hồi 8 HP nếu sống |
| Tuyệt Đỉnh `tuyet_dinh` | Sát thương, ít thủ | 2 round đúng liên tiếp buff Đánh thường kế +6, tối đa 2 lần, không cộng dồn | Một Nét Thành Chiêu: 38 damage | Đường Kiếm Cuối Trang: 46 damage, Đánh thường round sau 22; không dùng round 6 |
| Hàn Bối Pháp `han_boi_phap` (alias `han_boi_thap`) | Tanker, kết trận chậm | Armor về 0 lần đầu tạo 12 ward round kế, một lần/trận | Dựng Tháp: 18 damage +14 ward trong round | Trấn Tháp: 28 damage + hồi 16 armor |

Đã chuẩn hóa ID chính thức là `han_boi_phap` (khớp slug `han-boi-phap` trong `assets/game/manifest.json`), đồng thời backend và client duy trì bộ giải mã alias tương thích ngược 100% với định danh legacy `han_boi_thap`. Phiên bản luật chính thức: `combat_rule_version=solo-three-v0.1`; server lưu version trong match/event và không thay đổi giữa trận.

## 3. Giao diện trận

Màn dọc: sân đấu với map nền (`study-courtyard`), bộ sprite animation nhiều frame của 2 tướng đối mặt theo đúng `anchor/facing` (`idle`, `basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`) + 6 avatar hồ sơ phân biệt (`ca-chep`, `cao-giay`, `cu-meo`, `may-nho`, `rua-xanh`, `tho-so`) — phần dùng file `assets/game/` chỉ đóng gói phát hành sau khi chủ dự án hoàn tất cổng rà soát/duyệt quyền; thanh HP/giáp/qi và trạng thái chữ rõ; ba nút `Đánh thường (0 qi)`, `Chiêu 1 (1 qi)`, `Chiêu 2 (2 qi)` ghi cost, used/disabled reason; thẻ tướng có vai/nội tại/đánh đổi. Sau khi nộp, UI hiện `Đang kiểm tra bài làm`, action window chỉ mở theo event server. FX xuất phát từ attacker, projectile chạm defender, self-heal/buff ở chủ, passive đúng nhân vật; giảm chuyển động/bỏ qua hiệu ứng không đổi số. Không dùng animation để giả có kết quả sớm. [Asset](02-nhan-vat-asset.md).

## 4. Server authoritative và data/API cần làm

Các bảng đề xuất: `character_catalog`, `character_skills`, `matches`, `match_players`, `match_rounds`, `round_submissions`, `round_actions`, `round_results`, `match_events`, `match_results`, `rank_ledger` **chỉ khi ranked**. Unique `(match_id,round_no,user_id)` cho submit/action; settle theo transaction khóa match, append sequence, ledger một lần. API mục tiêu: queue/cancel, match snapshot, submit, chọn action, event stream/reconnect, result/appeal; đều auth participant, rate/idempotency/version. Client nhận event `round_started`, `submission_accepted`, `grading_pending`, `action_window`, `settled`, `void`, `match_finished`; không gửi damage/HP/RP từ client. Khi network đứt, server deadline vẫn chạy; reconnect từ last sequence, nếu không đủ dữ liệu thì void theo policy, không xử thua do AI lỗi.

## 5. Rank, avatar và an toàn

Giao hữu không đổi RP. Ranked chỉ mở theo môn/khối/pool khi chấm công bằng và playtest đạt; `rank_ledger` là nguồn duy nhất, không tạo thêm `rating_ledger`. Bảng theo mùa/môn/khối, opt-in/ẩn, không lộ giờ dậy/trường/bài riêng. Avatar có sẵn hoặc upload + duyệt; khung chỉ mỹ thuật, badge rank từ server; không bán sức mạnh. Tên/avatar/phát ngôn được moderation và kháng nghị; không chat tự do ban đầu. [Privacy](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 6. Cổng playtest

Ít nhất hai thiết bị/tài khoản, cùng câu/rubric/deadline, đáp án đúng nhưng bước sai, bước đúng nhưng kết quả sai, ảnh mờ/permission từ chối, `uncertain`, duplicate submit/action, disconnect/reconnect, simultaneous KO, qi/ward/heal, round 6, secret, rule version, ledger/idempotency/appeal. Theo dõi win rate từng tướng theo cùng trình độ và thứ tự đi; chỉnh kit bằng rule version sau playtest, không cân bằng chỉ bằng cảm giác. Quyền tên/hình/sprite/audio và độ trễ trên máy yếu phải được duyệt trước phát hành. [Test plan](../03-quality/01-ke-hoach-kiem-thu.md).
