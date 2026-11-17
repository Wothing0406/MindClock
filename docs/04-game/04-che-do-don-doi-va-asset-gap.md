# Đấu trường: luyện đơn, đấu đơn và đấu đội

**Trạng thái:** thiết kế, chưa có arena Flutter/API production. “Chơi đơn” được hiểu là **luyện một người với đối thủ máy**; “đấu đơn” là 1v1 người thật; “chơi đội” là **2v2** sau cổng 1v1. [GDD 1v1](01-pvp-gdd.md) là nguồn combat hiện tại. Android màn dọc đầu tiên. PvP tự nguyện, không ảnh hưởng báo thức/pet nhóm. [PRD](../01-product/01-prd.md), [asset](02-nhan-vat-asset.md), [rank](03-rank-mua-va-kinh-te.md).

## 1. Ba cửa vào

| Cửa | Đối thủ | Kết quả |
| --- | --- | --- |
| `Luyện đơn` | Bot có luật hành động công khai | Học chiêu/tướng; không RP/MMR/leaderboard. |
| `Đấu đơn` | 1 người thật cùng môn/khối/chương trình | Giao hữu 1v1; ranked sau cổng riêng. |
| `Đấu đội` | 2 người/bên, ưu tiên mời bạn | Giao hữu 2v2; ranked đội là release khác. |

Luyện đơn có thể dùng offline **nếu** câu/luật/asset đã cache; kết quả offline không cấp điểm online. PvP cần online, Auth/consent và ngân hàng câu approved chung. Thiếu pool phù hợp: giải thích và cho luyện, không dựng đối thủ giả. Mỗi thẻ có nhãn rõ và `Luật chơi`.

## 2. Luyện đơn PvE

`Chọn môn từ hồ sơ hoặc đổi → chọn tướng → xem luật/độ khó → câu approved → nộp đáp án + bước giải → chấm rõ → chọn đòn/chiêu → xem phản hồi → round kế → tổng kết`.

Bot là **đối thủ mô phỏng theo rule version**, không giả là AI đang giải bài hay người thật. Hành động bot deterministic có seed/replay. Chọn `Không giới hạn thời gian` khi luyện. Đúng rõ mới kích hoạt chiêu; sai cho gợi một bước/thử lại theo chính sách luyện, không trừ uy tín. `uncertain` cho nhập chữ/sửa ảnh/đổi câu không phạt. AI không tự quyết HP. Sau lượt có `Xem cách chấm`, không lộ đáp án trước nộp. Luyện đơn dạy qi, nội tại, target và nút chiêu trước PvP.

## 3. Đấu đơn 1v1

Giữ [luật v0.1](01-pvp-gdd.md): cùng question ID/revision/rubric/deadline; mỗi người nộp đáp án/bước giải riêng, server chấm rồi mở action, chốt HP/armor/event/result. Giao hữu trước ranked. Queue có hủy/timeout/lý do thiếu pool. Kết trận hiện câu, action, HP và đường kháng nghị; không lộ ảnh đối thủ nếu chưa cho phép. Tốc độ nộp không thêm sát thương. `uncertain`/lỗi hệ thống void round/trận theo policy, không tự xử thua.

## 4. Đấu đội 2v2 — luật nháp để playtest

**Ghép:** hai bạn lập đội qua lời mời, xác nhận môn chung, khối/chương trình và tướng. Ghép đội đối thủ chỉ khi cả hai sẵn sàng. Không dùng giờ dậy/pet/rank nhóm học để ghép. V0.1 không trùng tướng trong cùng đội để đọc vai rõ; ba tướng core miễn phí. Đội PvP không tự lộ lịch học/chuông của nhóm pet.

**Round:** cả bốn nhận **cùng câu/rubric/deadline**. Mỗi người nộp đáp án + lý do riêng; không xem bài đồng đội trước hết hạn. Server chấm bốn submission; mỗi người `correct` rõ có một action, người sai không kích hoạt nhưng vẫn vào round sau. Hai action mỗi đội khóa trước resolve đồng thời từ snapshot đầu round. Khi một bài `uncertain` vì AI/câu/ảnh, round void/review **cho cả bốn**. Không tăng damage vì nhanh.

**Combat nháp:** mỗi tướng vẫn `100 HP/50 armor`; action chọn một đối thủ còn sống làm target, heal/buff/passive dùng theo kit trên bản thân. Thắng khi cả hai đối thủ 0 HP; tối đa 6 round rồi so tổng HP, tổng armor, bằng thì hòa. Người bị hạ không action round sau nhưng vẫn xem trận/rời an toàn; chưa hồi sinh. Focus fire, ward/heal và thời gian ngồi chờ **chưa cân bằng**: mô phỏng/playtest rồi chốt `team_rule_version`, không bật ranked từ luật nháp.

**Mạng:** server giữ match/event sequence, reconnect snapshot đúng account. Submit/action idempotent, đồng đội không sửa action của nhau. Hết hạn reconnect xử theo giao hữu đã công bố; lỗi hệ thống không trừ RP. Chat đội đầu chỉ tín hiệu cố định `Chờ mình`, `Mục tiêu trái/phải`, `Sẵn sàng`; chat tự do/voice là task moderation riêng. AI không phát câu giữa round hoặc điều khiển kết quả.

## 5. UI màn dọc

Màn đầu có ba thẻ mode. Chọn tướng có vai `Bền bỉ/Sát thương/Phòng thủ`, nội tại, hai chiêu, qi/giới hạn. Trong trận **câu và ô trình bày lớn hơn sân**; sân thu gọn khi giải, bung khi resolve. 1v1 có hai actor theo manifest hiện tại; 2v2 có bốn actor và nhãn đội/target, không lật cả sân. Sau chấm mới mở ba nút action/target; nút vô hiệu ghi lý do. HP/armor/qi có số/chữ, không chỉ màu. Có `Bỏ qua hiệu ứng`, Reduce Motion và tắt âm game; không đổi HP/deadline. Màn luyện ghi `Lượt luyện`, không giả rank.

## 6. Asset đang có và khoảng thiếu

`assets/game/manifest.json` ghi `research_demo_only`. [Checker](../../scripts/check_game_assets.py) kiểm cơ học **3 tướng, 21 clip, 9 FX chiêu, 17 cue âm, 1 map, 6 avatar, 7 khung, 6 badge**. Đây là kiểm file/anchor, chưa duyệt quyền thương mại, chuyển động hay tích hợp Flutter. [Cây asset](02-nhan-vat-asset.md).

| Ưu tiên | Cần | Hiện trạng/việc tạo |
| --- | --- | --- |
| G1 | Thẻ mode/icon vector, HUD câu/qi/HP/armor, nút action/disabled, tổng kết | Chưa có UI runtime Flutter đồng bộ; không emoji hệ thống. |
| G1 | Marker `Máy tập`, hướng dẫn qi/target và uncertain | Tái dùng một tướng làm bot; không cần tướng thứ tư. |
| G2 | Hai slot/target/impact, map dọc, FX/audio/victory tướng | Art nghiên cứu có; cần QA pose/facing/quyền, đóng gói Flutter/máy thật. |
| G3 | Layout/manifest bốn slot, HUD bốn người, marker ally/enemy/target/KO | **Thiếu**. Tái dùng sprite tướng ở tỷ lệ nhỏ sau QA. |
| G3 | FX target bốn actor, chắn/heal đúng người, hai action đồng thời, kết quả đội | **Thiếu** timeline/anchor/event map; không dùng tia chung thay FX từng tướng. |
| Sau cổng | Map biến thể, skin, emote, âm/rank đội | Chưa cần cho giao hữu đầu. |

Mỗi asset mới có `source/` master, `runtime/` export, manifest anchor/facing/duration/hash, still Reduce Motion, provenance/license/reviewer. Prompt art mô tả **tướng gốc** và vai/FX riêng, không “giống phim X”. Kiểm 320/360/390dp, chữ 200%, nhân vật nhìn vào nhau, chân cùng baseline, hit đúng target, âm đúng tướng. Đo frame/memory Flutter profile mode trên Android mục tiêu; [Flutter hướng dẫn đo profile mode](https://docs.flutter.dev/perf/rendering-performance). Script pass không chứng minh hiệu năng/quyền phát hành.

## 7. Trình tự coding

1. **G1 luyện đơn local:** Flutter dọc, câu cache approved, chấm luyện/fallback, bot replay, ba tướng/chiêu, không RP. Unit/widget/Android một máy.
2. **G2 giao hữu 1v1:** API/PostgreSQL/Auth, queue/submit/grade/action/settle/events, hai máy A/B/duplicate/reconnect/void. Không ranked.
3. **G3 giao hữu 2v2:** invite đội, bốn submission/action/target, team settle, layout/FX, bốn máy/reconnect/AFK/uncertain; chỉ sau G2 playtest.
4. **G4 ranked:** content/eval/appeal/anti-farm/balance/quyền asset đạt. 1v1 trước, ranked đội quyết định riêng.

Không gộp G1–G4 trong một task. Ca nghiệm thu ở [quality](../03-quality/05-ca-nghiem-thu.md); prompt ở [tài liệu tiếp](05-prompts-trien-khai-dau-truong.md).
