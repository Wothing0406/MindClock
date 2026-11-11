# Solo RPG v2 — luật trận, ghép môn và đồng bộ

**Trạng thái:** đặc tả để coding, chưa có trận online chạy thật. Đây là nguồn chuẩn cho Solo, thay luật tính điểm ở [docs/33 v1](33-dau-truong-solo-ranked-gdd.md) và luật một câu ở [docs/21](21-dau-truong-xep-hang.md). Ngân hàng câu theo [docs/34](34-ngan-hang-cau-hoi-da-mon.md), hồ sơ môn theo [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md), SQL nền theo [docs/28](28-backend-sql.md). HP/sát thương là giả thuyết phải playtest; mọi trận lưu `combat_rule_version`.

## 1. Vòng lặp sản phẩm

`Chọn môn → tìm bạn/chia sẻ mã mời → sẵn sàng → chọn kỹ năng → cùng nhận câu → nộp một lần → xem đòn/HP và cách giải → vòng sau → kết quả và chủ đề cần ôn`. Giao hữu bằng mã mời là bản online đầu tiên. Ghép người lạ, ELO và bảng công khai chỉ mở sau cổng chất lượng §10. Không dùng bot giả người thật; không ép đấu khi chuông reo; không lấy giờ dậy làm điểm.

## 2. Ghép cùng nội dung, không cần trùng toàn bộ tổ hợp

Ranked bắt buộc trùng `{subject_code, grade_band, curriculum_id, content_version, question_pool_version, locale}`. `curriculum_id` là mã bộ nội dung do đội biên tập duy trì, không suy ra chỉ từ lớp hoặc năm. Ví dụ `Toán · Lớp 9 · Bộ nội dung 2026` chỉ hiển thị sau khi nội dung đã được xác nhận. Mỗi match khóa ba `question_id + revision` cùng thứ tự cho hai người.

Tổ hợp/môn ưu tiên trong hồ sơ chỉ gợi ý môn nên đấu. Hai người đều chọn Toán 12 và cùng bộ nội dung thì ghép được dù các môn ưu tiên còn lại khác nhau. Bắt trùng cả tổ hợp sẽ làm hàng chờ quá mỏng. Người dùng chọn môn thi đấu; app không tự đổi môn/lớp/bộ câu để tìm đối thủ. Giao hữu bằng mã có thể dùng bộ câu chung khác hồ sơ nếu cả hai xác nhận và có nhãn `Giao hữu · không tính hạng`. Thiếu câu hoặc đối thủ: `Chưa có trận phù hợp. Bạn có thể luyện môn này.`

Rating band thử nghiệm ±100 rồi ±200 sau 15 giây trong cùng scope; sau 30 giây đề nghị tiếp tục chờ/luyện. Chỉ một queue ticket và một match active/người; ticket TTL và hủy idempotent. Region chỉ điều phối độ trễ, không hiện vị trí.

## 3. Luật HP và ba kỹ năng

- Hai nhân vật bắt đầu **60 HP**. Ba vòng, một câu cấu trúc đã duyệt/vòng, hạn theo server khoảng 45–75 giây/câu. Sau ba vòng ai còn nhiều HP hơn thắng; bằng HP hoặc cùng về 0 trong một vòng là hòa. Có thể kết thúc sớm khi một bên về 0 sau một vòng. Không có tiebreak vô hạn.
- Mỗi vòng có 5 giây chọn một kỹ năng **trước khi hiện đề**; không chọn mặc định `quick_pen`. Kỹ năng khóa trên server và chỉ tiết lộ hai bên sau reveal. Câu đúng mới kích hoạt kỹ năng. Sai/hết giờ không gây sát thương, không kích hoạt buff. Hai đòn tính **đồng thời**, người nộp sớm không hủy lượt người kia.
- Một lần nộp/người/vòng. Chỉ reveal đáp án/giải thích khi cả hai nộp hoặc hết hạn. Câu lỗi/mơ hồ → void trận có hạng, không đổi rating; AI không chấm trực tiếp ranked.

| Mã | Tên và hoạt họa gốc | Khi trả lời đúng |
| --- | --- | --- |
| `quick_pen` | **Bút Chớp**: bút lướt một nét giấy | Gây 20 sát thương |
| `notebook_guard` | **Che Vở**: quyển vở bật thành khiên giấy | Gây 8 sát thương; giảm 12 sát thương nhận trong vòng, tối thiểu 0 |
| `ink_charge` | **Nạp Mực**: lọ mực rung nhẹ một nhịp | Gây 12 sát thương; cộng 5 sát thương cho một đòn đúng ở vòng kế |

Buff Nạp Mực tối đa một tầng, không cộng dồn. Buff từ vòng trước áp dụng cho đòn đúng hiện tại rồi tiêu thụ, kể cả chọn Nạp Mực tiếp. Nếu sai/hết giờ, buff cũ mất cuối vòng; buff không mang qua trận. Công thức: `damage_to_B = max(0, base_attack_A + old_buff_A + speed_bonus_A - guard_B)`; `hp_B_after = max(0, hp_B_before - damage_to_B)`. Server tính từ hai submission đã khóa; client không gửi HP/sát thương có thẩm quyền.

**Ví dụ kiểm tra:** A đúng Bút Chớp, B đúng Che Vở, không thưởng tốc độ → A mất 8 HP, B mất `20−12=8` HP; cả hai còn 52. Nếu B sai → Che Vở không bật; A còn 60, B còn 40.

### Thưởng nhanh có giới hạn

Nếu **cả hai đúng**, một người được +5 sát thương khi nộp sớm hơn ít nhất 2 giây theo thời điểm server nhận. Chênh dưới 2 giây không thưởng. Chỉ áp dụng khi **cả hai** xác nhận đã nhận đề trong cửa sổ đồng bộ, không reconnect trong vòng, độ lệch nhận đề và độ trễ mạng đạt ngưỡng thử nghiệm. Nếu mạng không đạt, vòng vẫn tính kiến thức/kỹ năng nhưng **không ai** có thưởng nhanh. Không dùng thời gian phá hòa sau trận. Ngưỡng 2 giây/+5 chỉ là cấu hình thử; phải đo hai máy/mạng khác nhau trước khi bật ranked. Nếu không chứng minh được công bằng, ranked tắt speed bonus.

## 4. Đồng bộ hai người, không gọi Gemini trong trận

Máy trạng thái: `queued → matched → ready → skill_select → round_prepare → round_active → round_settle → (skill_select | match_settle) → settled`, nhánh `cancelled/voided/needs_review`. Mỗi event có `event_id, match_id, round_no, sequence, server_time, rule_version`. Client bỏ event lặp, tải snapshot nếu thiếu sequence. Server khóa bộ câu tại `matched` nhưng không gửi stem/đáp án sớm.

1. Hai người ready; chọn kỹ năng. Hết 5 giây, server khóa lựa chọn hoặc kỹ năng mặc định.
2. Server gửi `round_prepare` chỉ có số vòng/thời lượng; nhận ready-to-receive của hai client. Server phát cùng payload đề qua WebSocket, kèm `starts_at` tương lai gần và `deadline_at`. Client gửi `question_received`; chỉ hiển thị câu từ `starts_at`.
3. Nếu một máy không xác nhận trong cửa sổ hoặc nhận sau `starts_at`, **hủy câu đã lộ**, chọn revision khác và chuẩn bị lại; không dùng lại câu cũ. Không phục hồi được thì void trận không rating. Không thể bảo đảm hai màn hình sáng cùng một mili giây; chỉ dùng mốc server và đo sai lệch thực tế.
4. Nộp bài với `Idempotency-Key`; server xác thực participant, revision, thời hạn. Cùng key/payload trả kết quả cũ; answer khác/key khác sau khi khóa trả 409. Backend chấm deterministic theo answer spec khóa, không nhận cờ `correct` từ client.
5. Hai bài nộp hoặc hết giờ → một transaction/worker có lock match chốt grade, buff, damage, HP, event reveal. Animation chạy **sau** state đã chốt. Reconnect lấy snapshot + events từ cursor, không phát lại damage.
6. Match settle khóa result, XP ledger và (nếu ranked hợp lệ) hai rating ledger trong cùng transaction. Retry/worker song song không tạo kết quả thứ hai. Không log token, đáp án cá nhân hoặc ảnh.

WebSocket dùng để đẩy trận; `GET snapshot/events` là đường phục hồi và có thể dùng polling cho demo nếu hai máy chứng minh cùng deadline. Không gọi Gemini hoặc tạo đề lúc `round_prepare`; bộ câu đã duyệt được chọn/khóa trước trận. Mất kết nối trước khi đề hiện đủ → void vòng/trận; mất sau đó cho reconnect/nộp trước deadline nhưng tắt thưởng nhanh vòng đó. Mất mạng không tự động là gian lận. Giao hữu v1 rời trận thì hủy không phạt; quy tắc forfeit ranked cần khiếu nại và playtest riêng.

## 5. XP, ELO và quyền riêng tư

HP chỉ sống trong trận, reset 60; không mua và không đổi thành XP/rating. XP học tập thử nghiệm: +5 khi hoàn tất ít nhất 2 vòng hợp lệ, +2 mỗi câu đúng, tối đa 11/trận và 3 trận cấp XP/ngày; người thua vẫn nhận. Rating ELO theo thắng/hòa/thua **toàn trận**, khởi đầu 1000, K thử nghiệm 24, scope `{subject,grade_band,curriculum_id,content_version,season_id}`. Trận `voided/needs_review` không đổi rating. HP không cộng thẳng vào rating; ELO không chọn độ khó báo thức. Bảng mùa chỉ hiện khi đủ người opt-in/đủ trận như [docs/33](33-dau-truong-solo-ranked-gdd.md) §7. Biệt danh/avatar whitelist, không tên thật, ảnh thật, trường/lớp cụ thể hay thời khóa biểu. Consent/độ tuổi theo [docs/24](24-dang-ky-va-quan-ly-tai-khoan.md) và [docs/25](25-bao-mat-va-du-lieu.md).

Không thể chống giải hộ bằng camera hay đo tốc độ tuyệt đối. Giới hạn đấu lại tính hạng cùng cặp, rate limit và rà soát hành vi bất thường; không gán nhãn gian lận tự động. Có nút báo câu lỗi/khiếu nại; câu lỗi được thu hồi revision và void trận liên quan có audit.

## 6. Avatar, UI và hiệu ứng vui

Ba avatar Cú Mực, Cáo Nắng, Rồng Giấy có **cùng** kỹ năng/thông số; đổi miễn phí. Humor đến từ phản ứng nhỏ theo tính cách, không từ chế giễu người thua: `Cú Mực mở vở.`, `Rồng Giấy gấp khiên.`, `Hai bên đều giữ được nhịp.` Không dùng emoji hệ thống, meme có bản quyền, GIF mạng, 3D runtime hoặc tiếng kêu chen vào đề. Asset là minh họa gốc 3D render sẵn thành WebP/sprite nhỏ; bản tĩnh luôn có. Không có nhân vật bị thương/ốm. Có tắt âm và giảm chuyển động.

Màn vòng: `Cú Mực 52/60 HP | Vòng 2/3 | Cáo Nắng 40/60 HP`; ba thẻ kỹ năng trước câu; sau đó đề chiếm phần lớn màn hình, nút `Nộp bài` rõ. Sau reveal chỉ một hiệu ứng 300–500 ms, số HP và tên kỹ năng vẫn hiện bằng chữ khi animation tắt. Không chờ animation để mở vòng tiếp theo. Khung rank chỉ cosmetic, không đổi hitbox/sức mạnh.

## 7. Hợp đồng API/SQL để lập task

Endpoint dự kiến: `GET /v1/competition/subjects`, `POST/DELETE /v1/matches/queue`, `POST /v1/matches/{id}/ready`, `POST /v1/matches/{id}/rounds/{n}/skill`, `POST /v1/matches/{id}/rounds/{n}/received`, `POST /v1/matches/{id}/rounds/{n}/submission`, `GET /v1/matches/{id}`, `GET /v1/matches/{id}/events?cursor=`, `GET /v1/matches/{id}/result`; WebSocket `/v1/matches/{id}/stream`. Chốt payload/schema bằng contract tests khi coding. Backend xác minh Firebase ID token và quyền participant trước mọi read/write/upgrade WebSocket; không lộ answer spec hoặc skill đối thủ trước reveal.

SQL bổ sung `matches` với scope nội dung + `combat_rule_version`; `match_players(match_id,user_id,slot,hp,ready_at,seen_round_at)`; `match_rounds(match_id,round_no,question_id,question_revision,start_at,deadline_at,state)`; `round_skills(match_id,round_no,user_id,skill_id,locked_at)`; `round_submissions(match_id,round_no,user_id,answer_ref,grade_status,received_at,attempt_key)`; `round_results(match_id,round_no,hp_a_before,hp_b_before,damage_to_a,damage_to_b,hp_a_after,hp_b_after,speed_bonus_user_id,settled_at)`; `match_results(match_id,outcome,winner_id_nullable,hp_a,hp_b,settled_at)`; `match_events(match_id,sequence,payload_public,created_at)`. Unique `(match_id,round_no,user_id)` cho skill/submission, `(match_id,round_no)` cho result, `(match_id,sequence)` cho event. `answerSpec` chỉ ở server. Submission cá nhân có thời hạn giữ phục vụ khiếu nại, không ghi log.

## 8. Lộ trình demo

1. Storyboard có nhãn `Mô phỏng trận đấu`: hai avatar, thanh HP, ba thẻ kỹ năng, một vòng mẫu. Không gọi mock là realtime.
2. Giao hữu thật: hai máy Android/hai tài khoản, mã mời, một môn/khối/bộ nội dung, ba câu đã duyệt, server SQL chốt HP. Nếu buổi thi không đủ thời gian, chứng minh **một vòng hai máy** trọn vẹn và ghi rõ ba vòng là kế hoạch.
3. Reconnect, void, quyền, idempotency, đo mạng; sau đó ghép giao hữu.
4. Chỉ sau cổng §10 mở ELO/bảng công khai từng môn. Không cần ELO thật để chứng minh vòng lặp học tập trong demo.

## 9. Câu hỏi playtest

Năm học sinh hiểu ba kỹ năng trong 30 giây không? Nếu không, chỉ giữ Tấn công/Phòng thủ cho bản đầu. Người thua có xem giải thích và muốn làm câu tương tự không? Mạng nào nhận đề chậm hơn, tỷ lệ void/thưởng nhanh theo mạng ra sao? Hàng chờ theo môn/lớp/bộ nội dung có đủ người không? Nếu không, ưu tiên mã mời và luyện, không ghép sai chương trình. Theo dõi câu lặp theo `variant_family_id`; không mở ranked khi ngân hàng quá mỏng.

## 10. Cổng mở ranked và acceptance

Ranked cần bộ câu đủ rộng/được duyệt; scope nội dung rõ; hai máy thật nhận cùng câu/deadline; không lộ đáp án; reconnect/void có test; HP, XP và hai rating ledger idempotent trong test cạnh tranh; consent/độ tuổi/bảng công khai/khiếu nại hoạt động. Thưởng nhanh ranked là cổng **riêng** dựa trên số đo mạng; có thể để tắt dù giao hữu đã bật.

| ID | Tình huống | Kết quả bắt buộc |
| --- | --- | --- |
| S01 | Chung Toán 9, khác môn ưu tiên khác | Ghép nếu cùng `curriculum/content/pool`; không đòi trùng toàn tổ hợp |
| S02 | Cùng tên môn/lớp nhưng khác `content_version` | Không ghép ranked; nêu lý do/luyện thay thế |
| S03 | Một máy nhận đề sau `starts_at` | Hủy câu đã lộ, phát revision mới hoặc void; không thưởng nhanh |
| S04 | A Bút Chớp đúng, B Che Vở đúng | Mỗi người mất 8 HP; hai máy cùng snapshot |
| S05 | A đúng, B sai và chọn Che Vở | A mất 0, B mất 20; sai không bật kỹ năng |
| S06 | Hai người đúng, chênh <2 giây hoặc mạng không đạt | Không ai có thưởng nhanh |
| S07 | Hai người đúng, chênh ≥2 giây, mạng đạt | Người sớm hơn +5, cả hai đòn vẫn chốt |
| S08 | Retry bài nộp/worker settle song song | Một submission/result/XP ledger; tối đa hai rating ledger |
| S09 | Câu lỗi/uncertain, mất kết nối trước nhận đề | Void, không rating, phản hồi rõ |
| S10 | Người ngoài trận gọi API/stream | 403, không lộ đề/đáp án/tài khoản |
| S11 | Cỡ chữ 200%, giảm chuyển động, máy yếu | Đề/nút đọc được; HP/kỹ năng hiểu được khi animation tắt |
| S12 | Storyboard/mock | Có nhãn mô phỏng; không tuyên bố online thật |

Khi code, đưa AC vào `tasks/TNNN-*/spec.md` và `tests.md`. Emulator không thay hai máy thật cho S03/S07.
