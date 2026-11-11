# Solo RPG v2 — luật trận, ghép môn và đồng bộ

**Trạng thái:** đặc tả để coding, chưa có trận online chạy thật. Đây là nguồn chuẩn cho **đồng bộ** Solo, thay luật tính điểm ở [docs/33 v1](33-dau-truong-solo-ranked-gdd.md) và luật một câu ở [docs/21](21-dau-truong-xep-hang.md). Bài làm/chấm theo [docs/39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md), kit PvP/map theo [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md), kinh tế/RP theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md). Ngân hàng câu theo [docs/34](34-ngan-hang-cau-hoi-da-mon.md), hồ sơ môn theo [docs/32](32-ho-so-hoc-tap-va-nhieu-mon.md), SQL nền theo [docs/28](28-backend-sql.md). HP/sát thương là giả thuyết phải playtest; mọi trận lưu `combat_rule_version`.

## 1. Vòng lặp sản phẩm

`Chọn môn → tìm bạn/chia sẻ mã mời → sẵn sàng → chọn kỹ năng → cùng nhận câu → nộp một lần → xem đòn/HP và cách giải → vòng sau → kết quả và chủ đề cần ôn`. Giao hữu bằng mã mời là bản online đầu tiên. Ghép người lạ, ELO và bảng công khai chỉ mở sau cổng chất lượng §10. Không dùng bot giả người thật; không ép đấu khi chuông reo; không lấy giờ dậy làm điểm.

## 2. Ghép cùng nội dung, không cần trùng toàn bộ tổ hợp

Ranked bắt buộc trùng `{subject_code, grade_band, curriculum_id, content_version, question_pool_version, locale}`. `curriculum_id` là mã bộ nội dung do đội biên tập duy trì, không suy ra chỉ từ lớp hoặc năm. Ví dụ `Toán · Lớp 9 · Bộ nội dung 2026` chỉ hiển thị sau khi nội dung đã được xác nhận. Mỗi match khóa ba `question_id + revision` cùng thứ tự cho hai người.

Tổ hợp/môn ưu tiên trong hồ sơ chỉ gợi ý môn nên đấu. Hai người đều chọn Toán 12 và cùng bộ nội dung thì ghép được dù các môn ưu tiên còn lại khác nhau. Bắt trùng cả tổ hợp sẽ làm hàng chờ quá mỏng. Người dùng chọn môn thi đấu; app không tự đổi môn/lớp/bộ câu để tìm đối thủ. Giao hữu bằng mã có thể dùng bộ câu chung khác hồ sơ nếu cả hai xác nhận và có nhãn `Giao hữu · không tính hạng`. Thiếu câu hoặc đối thủ: `Chưa có trận phù hợp. Bạn có thể luyện môn này.`

Rating band thử nghiệm ±100 rồi ±200 sau 15 giây trong cùng scope; sau 30 giây đề nghị tiếp tục chờ/luyện. Chỉ một queue ticket và một match active/người; ticket TTL và hủy idempotent. Region chỉ điều phối độ trễ, không hiện vị trí.

## 3. Luật HP và thẻ kỹ năng

- Hai nhân vật bắt đầu **60 HP**. Ba vòng, một câu đã duyệt **kèm yêu cầu trình bày ngắn**/vòng, hạn server thử nghiệm 90–120 giây/câu. Sau ba vòng ai còn nhiều HP hơn thắng; bằng HP hoặc cùng về 0 trong một vòng là hòa. Có thể kết thúc sớm khi một bên về 0 sau một vòng. Không có tiebreak vô hạn.
- Trước ready chọn 2/4 thẻ chung + một thẻ riêng; mỗi vòng chọn một thẻ trong loadout **trước khi hiện đề**, không chọn mặc định. Kỹ năng khóa trên server và chỉ tiết lộ hai bên sau reveal. `correct` rõ mới kích hoạt; `incorrect`/hết giờ không kích hoạt. Hai hành động tính **đồng thời**, người nộp sớm không hủy lượt người kia. Hồi/hút/choáng theo docs/40.
- Một lần nộp/người/vòng gồm đáp án và lý do/bước làm. Chỉ reveal sau khi cả hai bài được chấm hoặc hết hạn; nếu cần chấm ảnh sau deadline, trạng thái `grading_pending` có timeout. Câu lỗi/`uncertain` → void trận có hạng, không đổi rating. AI có thể đề xuất chấm **sau nộp** qua backend, chỉ khi cổng docs/39 đạt; nếu chưa, ranked tắt và chỉ giao hữu.

Thẻ chung/riêng, hồi/hút/choáng và thứ tự tính ở [docs/40 §2–3](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md). Server tính từ hai submission và kit đã khóa; client không gửi HP/sát thương có thẩm quyền.

**Ví dụ kiểm tra:** A đúng Bút Chớp, B đúng Che Vở, không thưởng tốc độ → A mất 8 HP, B mất `20−12=8` HP; cả hai còn 52. Nếu B sai → Che Vở không bật; A còn 60, B còn 40.

### Tốc độ trong bản yêu cầu viết

**Tắt speed bonus** khi người học phải viết/chụp bài: tốc độ viết, camera và tải ảnh khác nhau. `received_at` chỉ dùng kiểm deadline và đồng bộ, không cộng sát thương/đổi RP/phá hòa. Nếu sau này có mode câu đóng không yêu cầu viết, phải có rule version và thử mạng riêng; không áp mặc định cho v3.

## 4. Đồng bộ hai người và chấm sau nộp

Máy trạng thái: `queued → matched → ready → skill_select → round_prepare → round_active → grading_pending → round_settle → (skill_select | match_settle) → settled`, nhánh `cancelled/voided/needs_review`. Mỗi event có `event_id, match_id, round_no, sequence, server_time, rule_version`. Client bỏ event lặp, tải snapshot nếu thiếu sequence. Server khóa bộ câu/rubric tại `matched` nhưng không gửi stem/đáp án sớm hoặc rubric/đáp án trước reveal.

1. Hai người ready; chọn kỹ năng. Hết 5 giây, server khóa lựa chọn hoặc kỹ năng mặc định.
2. Server gửi `round_prepare` chỉ có số vòng/thời lượng; nhận ready-to-receive của hai client. Server phát cùng payload đề qua WebSocket, kèm `starts_at` tương lai gần và `deadline_at`. Client gửi `question_received`; chỉ hiển thị câu từ `starts_at`.
3. Nếu một máy không xác nhận trong cửa sổ hoặc nhận sau `starts_at`, **hủy câu đã lộ**, chọn revision khác và chuẩn bị lại; không dùng lại câu cũ. Không phục hồi được thì void trận không rating. Không thể bảo đảm hai màn hình sáng cùng một mili giây; chỉ dùng mốc server và đo sai lệch thực tế.
4. Nộp đáp án + bài giải với `Idempotency-Key`; server xác thực participant, revision, thời hạn. Cùng key/payload trả kết quả cũ; payload khác sau khi khóa trả 409. Backend kiểm đáp án; bộ chấm bài giải theo docs/39, không nhận cờ `correct` từ client.
5. Hai bài nộp hoặc hết giờ → trạng thái `grading_pending` nếu cần AI; cùng rubric/model/prompt version đã khóa cho hai bên. `correct/incorrect` rõ → một transaction/worker có lock match chốt grade, buff, damage, heal, status, HP, event reveal. `uncertain`/timeout bộ chấm → void theo docs/39. Animation chạy **sau** state đã chốt. Reconnect lấy snapshot + events từ cursor, không phát lại damage.
6. Match settle khóa result, XP/coin ledger và (nếu ranked hợp lệ) hai RP/MMR ledger trong cùng transaction. Retry/worker song song không tạo kết quả thứ hai. Không log token, đáp án cá nhân hoặc ảnh.

WebSocket dùng để đẩy trận; `GET snapshot/events` là đường phục hồi và có thể dùng polling cho demo nếu hai máy chứng minh cùng deadline. Không gọi Gemini hoặc tạo đề lúc `round_prepare`; bộ câu đã duyệt được chọn/khóa trước trận. Gemini chỉ có thể tham gia **sau nộp** để đọc/lập nhận định bài giải. Mất kết nối trước khi đề hiện đủ → void vòng/trận; mất sau đó cho reconnect/nộp trước deadline. Mất mạng không tự động là gian lận. Giao hữu v1 rời trận thì hủy không phạt; quy tắc forfeit ranked cần khiếu nại và playtest riêng.

## 5. XP, RP/MMR và quyền riêng tư

HP chỉ sống trong trận, reset 60; không mua và không đổi thành XP/RP. XP học tập thử nghiệm: +5 khi hoàn tất ít nhất 2 vòng hợp lệ, +2 mỗi câu đúng, tối đa 11/trận và 3 trận cấp XP/ngày; người thua vẫn nhận. **RP là bậc mùa hiển thị**, MMR/ELO nội bộ dùng ghép trận, Đồng Mực là điểm mua nhân vật; cách cộng/trừ và bậc theo [docs/37 §1–4](37-kinh-te-rank-va-nhan-vat-2d.md). Trận `voided/needs_review` không đổi RP/MMR. HP/tốc độ không cộng thẳng RP; MMR không chọn độ khó báo thức. Bảng mùa chỉ hiện khi đủ người opt-in/đủ trận theo [docs/37](37-kinh-te-rank-va-nhan-vat-2d.md) và quy tắc quyền riêng tư ở [docs/33](33-dau-truong-solo-ranked-gdd.md) §7. Biệt danh/avatar whitelist, không tên thật, ảnh thật, trường/lớp cụ thể hay thời khóa biểu. Consent/độ tuổi theo [docs/24](24-dang-ky-va-quan-ly-tai-khoan.md) và [docs/25](25-bao-mat-va-du-lieu.md).

Không thể chống giải hộ bằng camera hay đo tốc độ tuyệt đối. Giới hạn đấu lại tính hạng cùng cặp, rate limit và rà soát hành vi bất thường; không gán nhãn gian lận tự động. Có nút báo câu lỗi/khiếu nại; câu lỗi được thu hồi revision và void trận liên quan có audit.

## 6. Avatar, UI và hiệu ứng vui

Roster gồm Cú Mực, Cáo Nắng, Rồng Giấy và Hiệp Sĩ Bìa Vở theo [docs/40](40-dau-truong-pvp-nhan-vat-ban-do-va-hieu-ung.md); một nhân vật chọn miễn phí, nhân vật khác mở bằng Đồng Mực sau playtest. Humor đến từ đồ dùng/tình huống, không chế giễu người thua. Không dùng emoji hệ thống, meme có bản quyền, GIF mạng, 3D hoặc tiếng kêu chen vào đề. Asset là sprite 2D gốc WebP/PNG, bản tĩnh luôn có. Không có nhân vật bị thương/ốm. Có tắt âm và giảm chuyển động.

Màn vòng: `Cú Mực 52/60 HP | Vòng 2/3 | Cáo Nắng 40/60 HP`; ba thẻ trong loadout trước câu; sau đó đề + vùng `Viết cách làm` chiếm phần lớn màn hình, nút `Nộp bài` rõ. Khi đang chấm hiện trạng thái; sau reveal chỉ một hiệu ứng 300–500 ms, số HP và tên kỹ năng vẫn hiện bằng chữ khi animation tắt. Không chờ animation để mở vòng tiếp theo. Khung rank chỉ cosmetic, không đổi hitbox/sức mạnh.

## 7. Hợp đồng API/SQL để lập task

Endpoint dự kiến: `GET /v1/competition/subjects`, `POST/DELETE /v1/matches/queue`, `POST /v1/matches/{id}/loadout`, `POST /v1/matches/{id}/ready`, `POST /v1/matches/{id}/rounds/{n}/skill`, `POST /v1/matches/{id}/rounds/{n}/received`, `POST /v1/matches/{id}/rounds/{n}/submission`, `GET /v1/matches/{id}`, `GET /v1/matches/{id}/events?cursor=`, `GET /v1/matches/{id}/result`; WebSocket `/v1/matches/{id}/stream`. Chốt payload/schema bằng contract tests khi coding. Backend xác minh Firebase ID token và quyền participant trước mọi read/write/upgrade WebSocket; không lộ answer spec/rubric hoặc skill đối thủ trước reveal.

SQL bổ sung `matches` với scope nội dung + `combat_rule_version`/`grading_policy_version`; `match_players(match_id,user_id,slot,hp,character_id,loadout_ids,ready_at,seen_round_at)`; `match_rounds(match_id,round_no,question_id,question_revision,rubric_revision,start_at,deadline_at,state)`; `round_skills(match_id,round_no,user_id,skill_id,locked_at)`; `round_submissions(match_id,round_no,user_id,answer_ref,grading_decision_id,grade_status,received_at,attempt_key)`; `round_results(match_id,round_no,hp_a_before,hp_b_before,damage_to_a,damage_to_b,heal_a,heal_b,statuses_applied,hp_a_after,hp_b_after,settled_at)`; `match_results(match_id,outcome,winner_id_nullable,hp_a,hp_b,settled_at)`; `match_events(match_id,sequence,payload_public,created_at)`. Unique `(match_id,round_no,user_id)` cho skill/submission, `(match_id,round_no)` cho result, `(match_id,sequence)` cho event. `answerSpec`/rubric chỉ ở server. Bài giải cá nhân có thời hạn giữ phục vụ khiếu nại, không ghi log hoặc gửi đối thủ.

## 8. Lộ trình demo

1. Storyboard có nhãn `Mô phỏng trận đấu`: hai avatar, thanh HP, ba thẻ kỹ năng, một vòng mẫu. Không gọi mock là realtime.
2. Giao hữu thật: hai máy Android/hai tài khoản, mã mời, một môn/khối/bộ nội dung, ba câu đã duyệt, server SQL chốt HP. Nếu buổi thi không đủ thời gian, chứng minh **một vòng hai máy** trọn vẹn và ghi rõ ba vòng là kế hoạch.
3. Reconnect, void, quyền, idempotency, đo mạng; sau đó ghép giao hữu.
4. Chỉ sau cổng §10 mở RP/MMR và bảng công khai từng môn. Không cần rank thật để chứng minh vòng lặp học tập trong demo.

## 9. Câu hỏi playtest

Năm học sinh hiểu ba thẻ trong loadout trong 30 giây không? Nếu không, chỉ giữ Tấn công/Phòng thủ cho bản đầu. Người thua có xem giải thích và muốn làm câu tương tự không? Mạng nào nhận đề chậm hơn, tỷ lệ void theo mạng và tỷ lệ `uncertain` theo dạng bài ra sao? Hàng chờ theo môn/lớp/bộ nội dung có đủ người không? Nếu không, ưu tiên mã mời và luyện, không ghép sai chương trình. Theo dõi câu lặp theo `variant_family_id`; không mở ranked khi ngân hàng quá mỏng.

## 10. Cổng mở ranked và acceptance

Ranked cần bộ câu đủ rộng/được duyệt và **rubric trình bày đã đánh giá với người chấm độc lập** theo docs/39; scope nội dung rõ; hai máy thật nhận cùng câu/deadline; không lộ đáp án; reconnect/void có test; HP, XP, coin và hai RP/MMR ledger idempotent trong test cạnh tranh; cân bằng kit nhân vật theo docs/40; consent/độ tuổi/bảng công khai/khiếu nại hoạt động. Speed bonus **tắt** ở mode viết/chụp.

| ID | Tình huống | Kết quả bắt buộc |
| --- | --- | --- |
| S01 | Chung Toán 9, khác môn ưu tiên khác | Ghép nếu cùng `curriculum/content/pool`; không đòi trùng toàn tổ hợp |
| S02 | Cùng tên môn/lớp nhưng khác `content_version` | Không ghép ranked; nêu lý do/luyện thay thế |
| S03 | Một máy nhận đề sau `starts_at` | Hủy câu đã lộ, phát revision mới hoặc void; không chấm thua vì mạng |
| S04 | A Bút Chớp đúng, B Che Vở đúng | Mỗi người mất 8 HP; hai máy cùng snapshot |
| S05 | A đúng, B sai và chọn Che Vở | A mất 0, B mất 20; sai không bật kỹ năng |
| S06 | Hai người đúng, tốc độ nộp khác nhau | Không ai có thưởng nhanh trong mode viết/chụp |
| S07 | Một bài có đáp án đúng nhưng thiếu lý do hoặc AI chưa chắc | Không kích hoạt kỹ năng/đổi RP cho đến khi chấm rõ; ranked void nếu `uncertain` |
| S08 | Retry bài nộp/worker settle song song | Một submission/result/XP và coin ledger; tối đa hai RP/MMR ledger |
| S09 | Câu lỗi/uncertain, mất kết nối trước nhận đề | Void, không rating, phản hồi rõ |
| S10 | Người ngoài trận gọi API/stream | 403, không lộ đề/đáp án/tài khoản |
| S11 | Cỡ chữ 200%, giảm chuyển động, máy yếu | Đề/nút đọc được; HP/kỹ năng hiểu được khi animation tắt |
| S12 | Storyboard/mock | Có nhãn mô phỏng; không tuyên bố online thật |

Khi code, đưa AC vào `tasks/TNNN-*/spec.md` và `tests.md`. Emulator không thay hai máy thật cho S03/S07.
