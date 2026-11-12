# Solo RPG mới — ba nhân vật, giao diện, tài sản và đồng bộ

**Trạng thái:** đặc tả v0.1 để prototype và playtest; đã có [asset và web demo nghiên cứu](49-sprite-ba-nhan-vat-va-web-demo.md), **chưa có trận/API chạy thật**. Tài liệu này thay **toàn bộ số HP, giáp, thẻ, kit và ví dụ combat 60 HP** ở docs/35, 37, 40. Docs/35 vẫn là nguồn cho nguyên tắc ghép cùng nội dung, chấm bài và đồng bộ; docs/39 là nguồn chấm; docs/37 là nguồn RP/coin; docs/43 là nguồn khung hạng/bảng. Mọi số ở đây là giả thuyết cần cân bằng trước ranked. `combat_rule_version=solo-three-v0.1`.

## 1. Trải nghiệm và vai chiến đấu

Trận là **cuộc giải bài có lớp chiến thuật**: hai người cùng câu/rubric, nộp đáp án **và trình bày**, server chấm, rồi chiêu được chọn mới có hiệu lực. Đề và vùng viết luôn lớn hơn phần game. Không dùng kỹ năng để làm đối thủ nhận đề khó hơn, mất khả năng trả lời hoặc lộ đáp án. Nhân vật không quyết định năng lực học. Ba working names do chủ dự án đưa ra; tạo hình phải **gốc**, không sao chép phim/diễn viên/trang phục/biểu tượng nhận diện. Tên cần kiểm tra quyền và thử với người học trước phát hành.

| ID tạm | Tên | Vai | Điểm mạnh | Đánh đổi |
| --- | --- | --- | --- | --- |
| `ha_nhan` | Hà Nhân | Đấu sĩ bền bỉ / sustain | Hồi ít giáp khi giải đều, sống qua đòn dài | Không có burst lớn |
| `tuyet_dinh` | Tuyệt Đỉnh | Kiếm sĩ sát thương | Dồn damage sau chuỗi đúng, kết trận nhanh | Ít phòng thủ, dễ thua nếu sai liên tiếp |
| `han_boi_thap` | Hàn Bối Tháp | Hộ pháp tanker / phòng thủ phép | Chắn và hồi giáp, phản công vừa phải | Damage thấp, khó hạ đối thủ sớm |

**Tên hiển thị trong web demo:** theo yêu cầu ngày 12/11/2026, ảnh 2 dùng tên “Hàn Bối Pháp”. ID và luật kit vẫn là `han_boi_thap` cho prototype; tên cuối cùng phải chốt trước catalog/backend. Xem [docs/49](49-sprite-ba-nhan-vat-va-web-demo.md).

“Phép” là ngôn ngữ hình ảnh (vệt mực, vòng tháp), **không là loại sát thương thứ hai** ở v0.1. Chỉ có `damage` chung để người học hiểu một công thức; sau playtest mới cân nhắc physical/magic/resistance. Không có chí mạng, né ngẫu nhiên, may rủi damage, vật phẩm tăng sức mạnh hay pay-to-win.

## 2. Luật trận có thể lập trình

- Mỗi bên bắt đầu `HP=100`, `armor=50`, `ward=0`, `qi=0`. `HP` và `armor` không vượt mốc đầu trận; `ward` là chắn tạm tối đa 20 và hết sau round hiện tại. Không mang chỉ số sang trận khác.
- Tối đa **6 round**, một câu đã duyệt/round. Mỗi câu dự kiến 60–120 giây theo rubric, có deadline server. Cùng round, hai người nhận đúng một `question_id + revision`, rubric và độ khó giống nhau. Bộ câu phải đủ rộng, không lặp `variant_family_id` trong một trận.
- Mỗi người chọn **một hành động** sau khi nộp; chỉ `correct` rõ mới thi triển. `incorrect` hoặc timeout = 0 damage/0 buff, nhưng không trừ XP hay gán gian lận. `uncertain`, câu lỗi hoặc AI bất đồng = void round; ranked void cả trận, không đổi RP/MMR. Giao hữu có thể phát câu thay thế nếu chưa lộ chấm/chiêu; nếu không thì void trận.
- Chọn hành động trong 6 giây sau khi server xác nhận grade cho **cả hai**. Client không thấy grade, lựa chọn hay bài riêng của đối thủ trước reveal. Nếu không chọn đúng hạn, server chọn **Đánh thường**. Skill không đủ khí lực/cooldown/hết lượt bị từ chối, không âm thầm đổi thành chiêu khác; người chơi còn thời gian chọn lại. Qi của round này được cộng **sau settle**, không thể dùng cho chiêu cùng round. `correct` +1 qi, tối đa 3; round bí mật đúng +1 qi thêm. Khi dùng skill, trừ qi trong settle; sai/void không tiêu qi.
- Damage xử lý **đồng thời từ snapshot đầu round**, theo thứ tự: `ward → armor → HP`; không xuyên giáp ở v0.1. Chắn tạo trong round chặn damage của chính round đó; hồi HP/armor áp sau damage từ cùng snapshot, nhưng nếu HP chạm 0 do damage thì **không hồi cứu**. Hút máu nếu sau này có chỉ tính damage thật đã trừ vào armor/HP, không tính ward; v0.1 chưa có hút máu.
- Nếu một HP về 0 sau settle, trận kết thúc; cả hai về 0 = hòa. Sau round 6: so HP, rồi armor, còn bằng thì hòa. Không dùng thời gian nộp để phân thắng. RP/MMR chỉ theo kết quả hợp lệ, không theo damage/HP/camera/tốc độ. Chấm bài theo [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), không thưởng cho lời giải dài hơn nếu cùng đúng.

**Câu bí mật:** trước trận server dùng seed khóa để chọn **round 3 hoặc 5** và một câu đã duyệt có nhãn `secret=true`, cùng độ khó công bố cho hai bên. Hai người nhận cùng câu. Trả lời đúng nhận thêm 1 qi **sau round** và một hiệu ứng cosmetic; không thêm damage trực tiếp. Seed, pool revision và câu được lưu server; không để client chọn round hoặc reroll. Nếu pool không có câu đạt chuẩn, trận không có round bí mật và UI báo trước; không tạo câu bằng Gemini lúc đấu.

## 3. Hành động chung và ba bộ chiêu

Đánh thường: `28 damage`, `0 qi`, không cooldown. Mỗi skill chỉ dùng **một lần mỗi trận** trong v0.1; giảm vấn đề lặp hồi/chắn. Mỗi kit có một nội tại và hai chiêu. Nút chiêu hiện trước trận để người chơi đọc; không có “chiêu ẩn” đổi luật giữa trận.

| Nhân vật | Nội tại | Chiêu 1 · 1 qi | Chiêu 2 · 2 qi |
| --- | --- | --- | --- |
| Hà Nhân | **Giữ Nhịp:** sau hai round `correct` liên tiếp, hồi 8 armor sau settle; tối đa 2 lần/trận, không kích hoạt trên void | **Bước Vững:** 25 damage + hồi 6 armor sau damage | **Tĩnh Tâm Phản Kích:** 32 damage + hồi 8 HP sau damage nếu còn sống |
| Tuyệt Đỉnh | **Kiếm Ý:** sau hai round `correct` liên tiếp, đòn **Đánh thường kế tiếp** +6 damage; tối đa 2 lần/trận, không cộng dồn và mất sau một lần dùng | **Một Nét Thành Chiêu:** 38 damage, không chắn/hồi | **Đường Kiếm Cuối Trang:** 46 damage; round sau Đánh thường chỉ 22 damage (nếu còn round); không dùng ở round 6 để bỏ đánh đổi |
| Hàn Bối Tháp | **Tháp Còn Đứng:** lần đầu armor về 0, tạo 12 ward cho **round kế**; một lần/trận; nếu trận kết thúc thì không kích hoạt | **Dựng Tháp:** 18 damage + 14 ward trong round | **Trấn Tháp:** 28 damage + hồi 16 armor sau damage |

**Cân bằng nội tại:** chuỗi đúng tính theo `correct` đã settle, round void không phá chuỗi; `incorrect`/timeout phá chuỗi. Buff của Tuyệt Đỉnh chỉ áp cho đòn thường hợp lệ, không cộng vào skill; không nổ lần nữa khi đang giữ buff. Ward nội tại của Hàn Bối Tháp không chồng ward chủ động và tổng ward vẫn ≤20. Mọi hiệu ứng server gửi số trước/sau để client render, client không tính damage có thẩm quyền.

**Ví dụ chuẩn:** cả hai đúng round 1 và chọn Đánh thường: mỗi bên từ `100 HP/50 armor` thành `100 HP/22 armor`, rồi qi 1. Round 2 Hà Nhân dùng Bước Vững (25), Tuyệt Đỉnh dùng Một Nét Thành Chiêu (38): từ snapshot `armor=22`, Hà Nhân nhận 38 → armor 0, HP 84; hồi 6 armor từ chiêu **và 8 armor từ nội tại hai câu đúng**, thành 14 armor; Tuyệt Đỉnh nhận 25 → armor 0, HP 97 và tích một buff Kiếm Ý cho Đánh thường kế tiếp. Đây là ví dụ settle v0.1, không chứng minh kit cân bằng. Khi damage đủ hạ HP, hồi sau damage không cứu nhân vật.

## 4. UI trận và nút chiêu

**Màn chọn nhân vật:** 3 card cùng diện tích; trên card: silhouette 2D, tên, vai `Bền bỉ/Sát thương/Phòng thủ`, một câu điểm mạnh/đánh đổi, nút `Xem chiêu`. Trang chi tiết: Đánh thường, nội tại, chiêu 1/2 với damage, qi, điều kiện, ví dụ một round; nhãn `Thông số đang thử nghiệm`. Chọn một nhân vật trước ghép trận; đổi sau `ready` bị từ chối. Nếu cửa hàng chưa mở, cả ba dùng được trong giao hữu prototype; **không giả đã mua/sở hữu**.

**Phòng chờ:** môn/lớp/bộ nội dung/rule version, hai biệt danh và vai, ping trạng thái, `Sẵn sàng`, `Rời phòng`. Không lộ trường, thời khóa biểu hoặc câu tương lai. Màn trận ưu tiên theo thứ tự: (1) round/deadline; (2) hai thanh HP số `100/100`, armor `50/50`, ward nếu có; (3) đề và vùng viết; (4) nộp; (5) sau chấm mới mở action tray. Không che đề bằng nhân vật/FX. Khi khung nhỏ, avatar 40–48 dp và action tray cuộn ngang có nhãn chữ.

**Action tray sau nộp:** ba nút kích thước chạm ≥48 dp: `Đánh thường · 28`, `Chiêu 1 · 1 khí`, `Chiêu 2 · 2 khí`; icon vector riêng, khí hiện `1/3`. Nút disabled ghi lý do `Thiếu khí`, `Đã dùng`, `Không dùng vòng cuối`; `Xem chiêu` mở sheet gọn không mất lựa chọn. Một nút `Chốt chiêu` xác nhận trong 6 giây. Sau chốt hiện `Đang chờ xử lý`; không công bố chọn của đối thủ. Nếu người dùng chưa nộp hoặc bài sai rõ, action tray chỉ hiện `Lượt này chưa có đòn`; vẫn xem lời giải sau reveal. `uncertain` hiện `Cần kiểm tra bài`, không kéo đồng hồ chọn chiêu vô hạn.

**Kết quả round:** hiển thị chữ trước FX: `Hà Nhân · Bước Vững · 25 sát thương`, `Giáp 22 → 0`, `HP 100 → 84`, `+1 khí`; kết quả cập nhật từ event server. Cho bỏ qua FX và xem câu/giải thích. Thua trận có `Xem cách làm`, không có chế giễu, bệnh tật, biểu cảm đau đớn. Màn báo thức và Không gian học **không** hiển thị combat UI.

## 5. Asset 2D, hiệu ứng và prompt giao họa sĩ/AI ảnh

Phong cách: **sprite 2D gốc**, nét sạch, silhouette rõ 48 dp, ít chi tiết, vật liệu giấy/mực nhưng có cảm giác tu luyện nhẹ; không 3D, không emoji/GIF mạng, không phong cách giống một phim cụ thể. Nhân vật mới mang ngoại hình người trưởng thành hư cấu, không dùng ảnh học sinh. Mỗi master cần front, 3/4, silhouette đơn sắc, portrait 1:1, avatar 48 dp, battle sprite 96–128 dp và bản tĩnh. Pose: `idle, ready, basic, skill1, skill2, guard, win, rest`; không cần `hurt` đau đớn. Source và quyền sử dụng ghi manifest. Prompt chỉ tạo **concept**, người duyệt sửa tay trước khi export runtime.

| Tên | Brief ngoại hình nguyên gốc | Màu phụ, hình khối | FX riêng |
| --- | --- | --- | --- |
| Hà Nhân | Người luyện võ áo vải giản dị, tóc buộc thấp, đứng vững, tay giữ tập ghi chép đóng dây; dáng không giống nhân vật phim | xanh rêu `#55766A`, kem `#E9DFC9`; tam giác thấp, vai rộng vừa | vòng bút chì bảo vệ, vệt giáp mỏng |
| Tuyệt Đỉnh | Kiếm sĩ hư cấu áo khoác ngắn, kiếm **gỗ/từ nét mực** không sắc, tóc dựng hơi quá tự tin; đường nét hướng chéo rõ | tím mực `#665C85`, cam nhạt `#D9A46B`; silhouette chéo | một đường mực nhanh, không flash mạnh |
| Hàn Bối Tháp | Hộ pháp trầm, mang mô hình tháp giấy nhỏ sau lưng, áo choàng thẳng; tháp là đồ vật gốc không giống đạo cụ phim | xanh lam đậm `#496A78`, vàng nhạt `#D8BC7F`; hình chữ nhật vững | tháp giấy xếp lớp, khiên bán trong suốt |

**Prompt chung (chèn trước từng prompt):** `Thiết kế nhân vật 2D nguyên gốc cho app học tập tiếng Việt MindClock, tuổi người xem 13–18. Flat illustrated sprite, clear silhouette at 48 px, 2–3 color blocks, clean outlines, transparent background, full body 3/4 view, neutral friendly expression, no text, no logo, no film/game resemblance, no celebrity face, no school uniform, no photorealism, no weapon injury, no 3D render. Keep a consistent baseline and margin for sprite atlas.`

| Nhân vật | Prompt bổ sung cho concept/master |
| --- | --- |
| Hà Nhân | `Calm original martial learner in simple layered cloth, low tied hair, notebook bound with cord at waist, grounded balanced stance, moss green and warm paper palette. Subtle pencil-circle shield motif; expression focused, modest. Create front and three-quarter views with same costume and proportions.` |
| Tuyệt Đỉnh | `Original playful ink swordsman, short asymmetrical cloak, wooden practice sword shaped like a calligraphy stroke, slightly overconfident eyebrows, diagonal dynamic stance, muted violet and apricot palette. No steel blade, blood or flashy magical explosion. Front and three-quarter views.` |
| Hàn Bối Tháp | `Original quiet guardian carrying a small folded-paper tower on the back, straight cloak, broad stable silhouette, deep blue and pale gold palette. Paper tower opens into geometric shield panels, calm expression. Front and three-quarter views.` |

**Prompt FX riêng:** Hà Nhân `six-frame thin pencil circle forms around character then fades, transparent background, no glow bloom`; Tuyệt Đỉnh `six-frame single ink slash across edge of battle panel, no contact injury, no flashing`; Hàn Bối Tháp `six-frame folded paper tower shield rises then settles, transparent background, no particles over question text`. Xuất riêng PNG/WebP RGBA, sprite sheet 4–8 frame, 8–12 fps, anchor chân cố định; FX 300–500 ms, một FX tại một thời điểm, không chờ FX để mở thao tác kế. `Reduce Motion` dùng frame tĩnh + chữ/số. Không dùng hình ảnh từ nguồn ngoài làm reference cho asset phát hành nếu chưa có quyền; bộ ảnh người dùng cung cấp ở docs/49 chỉ dùng để nghiên cứu/demo và cần kiểm quyền trước phát hành. Đội phải lưu prompt, model/công cụ, tác giả chỉnh sửa, ngày, giấy phép/quyền đầu ra và asset version.

**Asset manifest đề xuất:** `character_id`, `asset_version`, `master_source`, `avatar_48`, `battle_idle`, `basic`, `skill1`, `skill2`, `static_fallback`, `anchor_x/y`, `frame_size`, `fps`, `duration_ms`, `alt_text_vi`, `credit`, `rights_status`. Thiếu một asset → dùng silhouette trung tính, không tải ảnh mạng giữa trận. Không tạo sprite chỉ từ một ảnh rồi tuyên bố các pose đã nhất quán nếu chưa review từng frame.

## 6. Networking và server authoritative

**Ghép trận:** queue theo `{subject_code, grade_band, curriculum_id, content_version, question_pool_version, locale}`; người chơi tự chọn môn đang có trong hồ sơ/tổ hợp, không bắt trùng toàn bộ tổ hợp. Ranked dùng MMR gần nhau trong **cùng scope**, nới dần dải rating nhưng không nới môn/chương trình/phiên bản câu. 30 giây chưa ghép thì cho `Tiếp tục chờ`, `Mời bạn`, `Luyện môn này`; giao hữu mã mời trước ranked. Một ticket và một active match/người. Trước khi queue, backend kiểm consent/độ tuổi/quyền ranked; không đưa tên thật, trường, giờ dậy vào presence.

**Luồng server:** `queued → matched → ready → round_prepare → round_active → grading_pending → action_select → round_settle → [round_prepare | match_settle] → settled`, nhánh `cancelled/voided/needs_review`. Server khóa character/kit/rule version/pool/revision khi `ready`, lấy 6 câu trước trận, không gửi đáp án/rubric xuống client. Khi round chuẩn bị, hai máy ack nhận cùng payload; server gửi `starts_at/deadline_at`. Nếu một máy trễ sau start, hủy câu đã lộ và thay revision khác hoặc void, không cho bên kia thắng vì mạng. Không gọi Gemini để sinh câu live.

**Transport:** HTTPS cho queue, ready, submit, action, snapshot; WebSocket đẩy state/event. Poll `GET snapshot/events?cursor=` là fallback khi WebSocket mất, nhưng cùng một deadline server. Mỗi event có `match_id, sequence, round_no, server_time, combat_rule_version, payload_public`; snapshot có `last_sequence` và hash. Client bỏ event lặp, nếu sequence nhảy thì tải snapshot, render trạng thái server, **không tự chạy damage**. Sau reconnect, draft đáp án local chỉ khôi phục trong phạm vi deadline; không tự nộp ảnh. Ping chỉ để thông báo mạng, không tính điểm.

**API dự kiến:** `POST /v1/matches/queue`, `DELETE /v1/matches/queue/{ticket}`, `POST /v1/matches/{id}/ready`, `POST /v1/matches/{id}/rounds/{n}/submission`, `POST /v1/matches/{id}/rounds/{n}/action`, `GET /v1/matches/{id}`, `GET /v1/matches/{id}/events?cursor=`, `GET /v1/game/characters?ruleVersion=`, `WS /v1/matches/{id}/stream`. Submit/action cần `Idempotency-Key`; action nhận `action_id` allowlist và `expected_round_version`, **không nhận damage/HP/qi từ client**. Backend xác minh Firebase ID token/participant cả HTTP và WebSocket; skill/character phải thuộc kit đã khóa. Không lộ bài làm riêng của đối thủ, đáp án/rubric/seed bí mật trước reveal. Rate limit queue/action/reconnect. Retry action cùng key+payload trả cùng chốt; khác payload sau lock trả 409.

**SQL dự kiến, migration chưa có:** `character_catalog(character_id,kit_version,status)`, `character_skills(character_id,skill_id,cost,uses_per_match,effect_json,rule_version)`, `match_players(...,hp,armor,ward,qi,character_id,kit_version)`, `match_rounds(...,question_revision,secret,starts_at,deadline_at,state)`, `round_submissions`, `round_actions(match_id,round_no,user_id,action_id,idempotency_key,locked_at)`, `round_results(...,hp/armor/ward/qi before_after,damage,heal,buffs,rule_version)`, `match_events(match_id,sequence,public_payload)`, `match_results`. Unique `(match_id,round_no,user_id)` cho submission/action và `(match_id,round_no)` cho settle. Một transaction có khóa match tính cả hai bên, append event theo thứ tự, settle result/ledger đúng một lần. `rank_ledger` duy nhất cho RP/MMR theo docs/44. Số chiêu có thẩm quyền từ catalog/rule version server, không từ JSON client.

**Thời gian/AI:** đề preselect và cache trước; Gemini chỉ chấm sau nộp theo cùng model/prompt/rubric version cho hai bên. Có timeout và `uncertain`, không dùng kết quả AI đơn lẻ để phạt. Ngân sách mục tiêu thử nghiệm: queue/presence <2 giây trong mạng tốt, phát cùng đề lệch <500 ms sau ack, action settle <1 giây sau khi đã có grade; đây là **mục tiêu đo**, không lời hứa. Nếu chấm ảnh dài hơn, UI hiển thị `Đang kiểm tra bài`, không hiện phần trăm giả. Giao hữu có thể dùng bài chữ trước để giảm độ trễ.

## 7. Cân bằng, test và cổng mở ranked

**Trước playtest:** chạy mô phỏng mọi cặp kit × chuỗi 6 round (`all correct`, `alternate`, `2 errors`, `secret correct/incorrect`) với cùng chuỗi grade cho hai bên; chiến lược dùng qi tối ưu/giữ qi/đánh thường. Bất biến: HP 0–100, armor 0–50, ward 0–20, qi 0–3, không hồi cứu tử vong, không dùng skill lần hai, không extra damage khi sai/void, kết quả không phụ thuộc thứ tự xử lý A/B. Seed bí mật không ưu ái nhân vật nào. Target ban đầu: khi **hai bên cùng tỷ lệ đúng và chiến lược tương đương**, mỗi cặp kit thắng không quá 55% trong tập mô phỏng đa kịch bản; target này chỉ là gate thiết kế, cần người chơi thật để xác nhận.

**Playtest:** ít nhất 30 trận giao hữu/kit với người học đồng ý phù hợp; chia trình độ/môn, đổi bên/thiết bị, lưu win rate theo matchup **sau khi chuẩn hóa tỷ lệ đúng** và tỷ lệ chọn skill, độ dài trận, số void, người chơi hiểu UI sau 30 giây, mức đọc lời giải sau thua. Nếu một matchup vượt 60% thắng có điều kiện hoặc một skill được chọn >85% khi có thể dùng, điều chỉnh **một tham số một lần**, tăng `combat_rule_version`, mô phỏng lại. Không chỉnh kit đang giữa trận. Kiểm tra thêm bài viết tay với người chấm độc lập theo docs/39 trước ranked.

| ID | Test bắt buộc | Kỳ vọng |
| --- | --- | --- |
| P01 | Hai người cùng câu/grade, lần lượt đổi slot A/B | HP/armor/qi đối xứng và cùng result |
| P02 | Damage qua ward/armor/HP, hồi sau lethal | Đúng thứ tự, không vượt cap/không hồi cứu |
| P03 | Buff nội tại, round bí mật, dùng skill lần hai/không đủ qi | Đúng giới hạn; seed chung; server từ chối action sai |
| P04 | Correct/incorrect/uncertain, chấm timeout | Sai không bật skill; uncertain void ranked/không RP |
| P05 | Hai máy nhận trễ, rớt mạng, reconnect, event lặp/nhảy sequence | Đổi câu hoặc void; snapshot phục hồi; damage không lặp |
| P06 | Retry/concurrent submit/action/settle | Một action/result/event sequence/ledger hợp lệ |
| P07 | Token người ngoài trận, client gửi HP/qi/damage giả | 403/validation, không lộ dữ liệu hoặc đổi state |
| P08 | 320 dp, chữ 200%, TalkBack, Reduce Motion, asset thiếu | Đề/nút/HP/chiêu/kết quả vẫn hiểu và thao tác được |
| P09 | Demo một round trên hai máy thật | Ghi rõ live hay mô phỏng; cùng câu/deadline/result |

**Lát cắt:** (1) storyboard ba nhân vật + icon/nút/FX tĩnh, (2) giao hữu hai máy một round với Đánh thường và bài chữ, (3) 6 round/giáp/qi/skill, (4) reconnect/void/AI chấm ảnh, (5) mô phỏng và playtest cân bằng, (6) ranked/RP/bảng. Không đưa cửa hàng/cosmetic mua coin vào trước khi luật và quyền sở hữu được chốt. Mỗi bước là task coding riêng có spec/plan/tests theo `tasks/README.md`.
