# Kinh tế Đồng Mực, bậc hạng và nhân vật sprite 2D

**Trạng thái:** đặc tả để coding và playtest; chưa có ví, cửa hàng, ảnh sprite hoặc rank chạy thật. Tài liệu này là nguồn chuẩn cho **Đồng Mực, RP và sở hữu nhân vật**; kit/FX/map mới nhất ở [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md), bài giải ở [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), đồng bộ ở [docs/35](35-solo-rpg-dong-bo-va-ky-nang.md). Thông số là giả thuyết thử nghiệm, lưu `economy_rule_version`, `combat_rule_version`, `rank_rule_version`.

## 1. Ba loại điểm không trộn nhau

| Loại | Dùng để | Có thể tiêu? | Nguồn thẩm quyền |
| --- | --- | --- | --- |
| **Đồng Mực** (`ink_coin`) | Mở nhân vật/phụ kiện/hiệu ứng 2D | Có; không quy đổi tiền thật, không chuyển người khác | `coin_ledger` server |
| **XP học tập** | Mốc học cá nhân, không quyết định sức mạnh/rank | Không | `xp_ledger` server theo docs/28, 35 |
| **Điểm hạng** (`RP`) | Bậc Đồng 1 → Tinh Anh 5 theo môn/lớp/mùa | Không; tăng/giảm theo trận ranked hợp lệ | `rank_ledger` server |

Không bán coin/nhân vật bằng tiền thật ở bản học sinh; không có loot box, gacha, trả phí để hồi máu, mua lượt thêm hoặc nhân hệ số RP. Cụm “kiếm tiền” trong UI là **kiếm Đồng Mực**, luôn ghi rõ `điểm trong game, không đổi thành tiền`. Không thưởng coin chỉ vì mở app hay buộc streak liên tục; có thể nghỉ mà không mất nhân vật/coin. Hoạt động báo thức và Dừng khẩn cấp không bị khóa bởi kinh tế game.

## 2. Nhiệm vụ ngày và ví

Ngày nhiệm vụ tính theo múi giờ người dùng đã xác nhận; server ghi `local_date`, `time_zone`, `rule_version`. Mỗi nhiệm vụ chỉ nhận một lần/ngày qua khóa unique. Mặc định tối đa **60 Đồng Mực/ngày** từ nhiệm vụ và trận; số này cần hiệu chỉnh pilot.

| Mã | Điều kiện thật, không chỉ bấm nút | Thưởng đề xuất |
| --- | --- | --- |
| `daily_review` | Hoàn thành 1 câu ôn đã duyệt, có bài nộp hợp lệ | +10 |
| `daily_three_topics` | Hoàn thành 3 câu thuộc ≥2 chủ đề, có phản hồi | +15 |
| `daily_explanation` | Xem giải thích sau một câu sai/uncertain hoặc một trận; không yêu cầu phải sai | +5 |
| `daily_friendly` | Hoàn thành một trận giao hữu với hai người thật, ≥2 vòng hợp lệ | +10 |
| `daily_ranked` | Hoàn thành trận ranked hợp lệ đầu tiên trong ngày | +10 |
| `daily_ranked_win` | Thắng ranked hợp lệ đầu tiên trong ngày | +10 |

Tổng tối đa 60/ngày. Nếu người dùng không bật đấu trường vẫn có đường kiếm 30/ngày từ học tập; thêm nhiệm vụ học khác sau pilot nếu giá nhân vật quá xa. Trận void/đấu bot/mã mời tạo lại với cùng cặp nhiều lần không thưởng trận; chỉ trận ranked hợp lệ đầu tiên/ngày có thưởng. Không lấy “đúng” làm điều kiện nhận toàn bộ coin học tập để tránh phạt người yếu. Coin cộng **sau** khi sự kiện được xác thực; màn hoàn thành hiện `+10 Đồng Mực · Ôn 1 câu`, không hiện tiền thật.

**Cửa hàng thử nghiệm:** khi tạo tài khoản/chọn nhân vật, chọn **một trong bốn nhân vật miễn phí**; ba nhân vật còn lại mỗi nhân vật 300 Đồng Mực, phụ kiện 100, đổi hiệu ứng cùng kỹ năng 80. Tất cả thẻ chung miễn phí; không bán HP, lượt, sát thương hoặc hồi thêm. Không tính phí đổi nhân vật đã sở hữu. Màn nhân vật cho `Xem thử` bộ kỹ năng trong luyện/giao hữu; trận ranked chỉ dùng nhân vật đã sở hữu và được bật cân bằng. Ví có số dư, lịch sử nhận/chi, giá cố định hiện trước xác nhận; không quảng cáo gây áp lực. Bản demo có thể dùng tài khoản thử đã cấp coin bằng fixture **có nhãn**, không giả là coin người dùng kiếm thật.

Server xử lý mua trong transaction: kiểm tra ID token, tuổi/consent nếu cần, giá catalog version, số dư, unique ownership; khóa ví, ghi `coin_ledger` âm và `character_ownership` cùng transaction. `purchase_idempotency_key` lặp trả cùng kết quả; thiếu coin trả `INSUFFICIENT_COIN` không trừ; nhân vật đã có trả trạng thái `owned` không trừ lần hai. Không tin số dư/giá do client gửi. Không để ví âm. Hoàn coin/thu hồi nội dung bằng ledger bù trừ có audit, không sửa lịch sử.

## 3. HP và kỹ năng theo nhân vật

**Luật PvP hiện hành** ở [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md): 60 HP/3 vòng, bốn thẻ chung (tấn công, chặn, hồi, hút), bốn thẻ riêng của Cú Mực/Cáo Nắng/Rồng Giấy/Hiệp Sĩ Bìa Vở, choáng khóa thẻ riêng một vòng nhưng người học vẫn trả lời. Chọn 2 thẻ chung + 1 thẻ riêng trước trận. Hai hành động cùng chốt; không cộng tốc độ trong bài viết/chụp. `correct` cần đáp án **và** trình bày theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). Sai/AI không chắc không bị phạt XP; `uncertain` làm void ranked. HP không mang qua trận, không có vật phẩm mua để hồi.

Mọi nhân vật phải có cách chơi khác nhưng cùng ngân sách sức mạnh. Trước ranked, thử nhiều cặp người chơi, đo tỷ lệ thắng theo trình độ và lượt đi; nếu mất cân bằng tắt thẻ riêng bằng feature flag, giữ thẻ chung giống nhau. Không bán lợi thế sức mạnh. Version hóa `combat_rule_version`; không đổi thông số giữa trận.
## 4. Điểm hạng và 30 bậc

Phạm vi RP: `{subject_code, grade_band, curriculum_id, content_version, season_id}`. RP là thang mùa **riêng với XP và Đồng Mực**. Ghép trận dùng rating kỹ năng nội bộ `MMR` để tránh ghép lệch; UI không gọi MMR là RP. Server cập nhật RP và MMR từ **kết quả thắng/hòa/thua đã chốt**, không từ HP còn lại, tốc độ, số câu đúng riêng lẻ hay nhân vật. Trận void/uncertain không đổi RP/MMR.

**Thông số mùa thử 8 tuần:** RP khởi đầu 100 (Đồng 3), 5 trận đầu hiện `Đang xếp hạng` và ghi RP ẩn; sau trận 5 mới hiện bậc. Thắng **+20 RP**, hòa **0**, thua **−20**, chặn đáy 0 và trần 1199. Những con số cần mô phỏng/phỏng vấn người học; không tuyên bố đã cân bằng. Cùng cặp chỉ một trận ranked có RP trong 24 giờ; trận tiếp theo chuyển giao hữu hoặc không thưởng/không đổi RP với nhãn rõ **trước** khi vào. Rời trận do lỗi mạng không tự trừ RP; forfeit chỉ sau quy trình chứng cứ/khiếu nại ở docs/35.

| RP mùa | Bậc hiển thị |
| --- | --- |
| 0–199 | Đồng 1–5, mỗi bậc 40 RP |
| 200–399 | Bạc 1–5 |
| 400–599 | Vàng 1–5 |
| 600–799 | Bạch Kim 1–5 |
| 800–999 | Kim Cương 1–5 |
| 1000–1199 | Tinh Anh 1–5 |

`tier_index = floor(RP/200)` (0..5); `division = floor((RP % 200)/40)+1` (1..5). Ví dụ RP 139 = Đồng 4; thắng → 159 vẫn Đồng 4, còn 1 RP đến Đồng 5; thắng tiếp → 179 = Đồng 5. RP 199 thắng → 219 = Bạc 1. RP 5 thua → 0, không âm. Màn kết quả: `Thắng · +20 RP · Đồng 4 (159/160)`, đồng thời hiển thị coin/XP trên hàng **riêng**. Người dùng có thể xem lịch sử ledger và lý do điểm. Thua có thể tụt bậc, nhưng không mất coin, XP, nhân vật; thông báo trung tính.

MMR dùng ELO nền thử nghiệm (khởi tạo 1000, K thử nghiệm 24, `S=1/0.5/0`) trong scope môn/mùa. RP và MMR chốt cùng result transaction; MMR có thể khác RP nên ghép theo kỹ năng, còn RP thể hiện tiến trình mùa. Bảng mùa công khai chỉ sau opt-in/đủ 5 trận và ngưỡng riêng tư ở [docs/21](21-dau-truong-xep-hang.md); xếp theo RP, hòa RP cùng **số hạng**, thứ tự hàng ổn định theo ID nội bộ, không dùng MMR để quyết hạng theo [docs/44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md). Tránh thưởng số trận liên tục làm bảng chỉ đo cày cuốc. Cuối mùa giữ huy hiệu lịch sử; mùa mới reset RP về 100, MMR có soft reset có version, coin/XP/ownership không reset. Chỉ mở ranked sau cổng docs/35 §10.

## 5. Sprite 2D và bộ asset kỹ năng

Phong cách **2D phẳng, nét giấy/bút rõ**, không dựng/render nhân vật 3D. Có thể vẽ vector rồi xuất PNG/WebP; nhân vật gốc và hiệu ứng phải có source/licence. Một nhân vật gồm `idle`, `ready`, `think`, `attack`, `guard`, `heal`, `stunned`, `win`, `rest`; không có `hurt` đau đớn, chỉ chớp mắt/giấy rung khi mất HP. Mỗi trạng thái 4–8 frame nếu cần, 8–12 fps; cỡ hiển thị trận 64–96 dp, avatar 40–48 dp. Frame giữ chân/điểm neo cố định để không nhảy vị trí. `prefetch` và giải mã asset ở phòng chờ, không tải khi đang chạy đồng hồ câu.

Mỗi kỹ năng có `skill_id`, `effect_id`, `sprite_sheet`, `frame_width/height`, `frame_count`, `fps`, `loop=false`, `hit_frame`, `duration_ms`, `alt_text_vi`, `static_fallback`, `asset_version`, `source_credit`. FX gồm nét bút, quyển vở, băng giấy hồi, giọt mực hút, kẹp giấy choáng, lọ mực nạp, trang giấy lách, giấy gấp theo docs/40. Một hiệu ứng sau reveal tối đa 500 ms; hiệu ứng cosmetic không quyết định hit time/damage. Nếu asset không tải, vẫn hiện tên kỹ năng/số HP bằng chữ. Không dùng GIF mạng/emoji mặc định/ảnh có bản quyền. Test cỡ chữ 200%, Reduce Motion, máy Android yếu và máy nóng; nếu rớt khung thì dùng fallback tĩnh.

Các skill trong `.agents/skills/` chỉ giúp **tạo và kiểm tra asset**, không phải runtime: `generate2dsprite` cho master/FX, `video2dsprite` chỉ khi thật cần nhiều khung, `codeart2d` nếu muốn art vẽ bằng mã và phù hợp phong cách, `generate2dmedia` là đường tạo media, `generate2dmap` dành cho nền/bản đồ **không cần cho MVP**. Không chạy API/CLI tạo ảnh khi chưa kiểm tra tuyến chi phí. Bộ skill [Agent Sprite Forge](https://github.com/0x0funky/agent-sprite-forge) có mã MIT; quyền đối với **ảnh sinh ra** theo công cụ tạo ảnh/nguồn từng asset, không tự động là MIT.

## 6. SQL/API và test để coding

Thêm `wallets(user_id,balance,version)`, `coin_ledger(id,user_id,source_type,source_id,local_date,delta,rule_version,created_at)` với unique theo nguồn; `character_catalog(character_id,price_coin,kit_version,status)`, `character_ownership(user_id,character_id,acquired_at,source)`, `purchase_receipts(user_id,idempotency_key,catalog_version,character_id,coin_delta,result)`; `daily_mission_claims(user_id,mission_id,local_date,rule_version,claimed_at)`; `rank_profiles(user_id,scope,season_id,rp,mmr,placement_count,version)`, `rank_ledger(entry_id,match_id,user_id,scope_id,season_id,entry_kind,review_id_nullable,rp_before,rp_delta,rp_after,mmr_before,mmr_delta,mmr_after,rule_version)`. Một settle/người/trận, correction là dòng riêng unique theo review như [docs/44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md). `match_players` khóa `character_id`/`kit_version` từ ownership lúc ready; `round_skills` chỉ nhận skill thuộc kit đã khóa. Index và FK bắt buộc; hai rank settle ledger + coin/XP ledger + match result chốt trong transaction ngắn.

API dự kiến: `GET /v1/game/wallet`, `GET /v1/game/missions/today`, `POST /v1/game/missions/{id}/claim`, `GET /v1/game/characters`, `POST /v1/game/starter-character`, `POST /v1/game/characters/{id}/purchase`, `PUT /v1/game/characters/equipped`, `GET /v1/competition/rank?scopeId=&seasonId=`, `GET /v1/game/ledger?cursor=...`. Payload, bảng và hợp đồng bảng hạng ở [docs/44](44-backend-nhan-vat-rank-bang-xep-hang-va-kiem-thu.md). Tất cả write lấy user từ token, không tin giá, coin, RP, kit từ client. `claim`/`purchase` có idempotency; báo lỗi thiếu coin, nội dung hết bán, nhân vật đã sở hữu, hết hạn mùa bằng mã ổn định. Không lưu số dư trong thiết bị làm nguồn chuẩn; offline hiển thị snapshot có nhãn `Chưa đồng bộ` và không cho mua/ranked.

| ID | Test bắt buộc |
| --- | --- |
| E01 | Mỗi người chọn miễn phí một trong bốn nhân vật; bấm lại/đổi máy không được nhận nhiều lần |
| E02 | Nhiệm vụ lặp hoặc race hai worker: một ledger/claim, tổng ≤60 coin/ngày |
| E03 | Mua đủ/thiếu coin, retry key, hai mua đồng thời: không âm ví/không trừ hai lần |
| E04 | Đối thủ gửi skill không thuộc kit/kit không sở hữu: từ chối trước chốt vòng |
| E05 | Tính ví dụ HP 60, block/buff/hồi/hút/choáng; hai hành động đồng thời và cùng 0 là hòa; không có speed bonus mode viết |
| E06 | RP 139/159/199/0, thắng/hòa/thua/void: đúng bậc và delta; XP/coin không bị trừ khi thua |
| E07 | Match settle retry/concurrent: một result, hai rank ledger và coin/XP đúng một lần |
| E08 | Giảm chuyển động, asset mất, máy yếu: đề, nút, HP và kết quả vẫn dùng được |

Thứ tự xây: ví + một nhân vật miễn phí → giao hữu hai máy với hai thẻ chung → hồi/hút → bốn kit/asset 2D/choáng → nhiệm vụ/cửa hàng → đo cân bằng và kiểm định chấm trình bày → ranked/RP/bảng. Không quảng cáo cửa hàng trước khi vòng học tập cơ bản dùng được.
