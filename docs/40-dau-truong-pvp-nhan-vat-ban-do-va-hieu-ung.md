# Đấu trường PvP: kỹ năng, nhân vật, bản đồ và hiệu ứng

**Trạng thái:** thiết kế v3 để playtest, chưa có PvP hoặc asset chạy thật. Đọc cùng [đồng bộ trận](35-solo-rpg-dong-bo-va-ky-nang.md), [kinh tế/rank](37-kinh-te-rank-va-nhan-vat-2d.md), [bài làm có trình bày](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). V3 mở rộng thẻ/kỹ năng của docs/37 §3; thông số cần mô phỏng và thử với người học trước ranked. `combat_rule_version=pvp-writing-v3`.

> **Đóng băng thiết kế cũ:** chủ dự án đã hủy roster và kit nhân vật cũ. Các công thức 60 HP/3 vòng bên dưới chỉ là lịch sử playtest, **không được dùng để code luật PvP mới**. Bản v0.1 mới ở docs/46; vẫn phải playtest trước ranked. Chỉ giữ nguyên tắc chấm công bằng, server quyết định, không phạt sai và hiệu ứng không che bài.
>
> **Nguồn mới:** [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) là đặc tả v0.1 cho ba nhân vật, 100 HP/50 giáp, kit, UI, sprite và networking. Nó thay phần combat trong file này; phần dưới chỉ lưu lịch sử v3 để so sánh, không dùng lập task code.

## 1. Cảm giác trận và giới hạn học tập

Một trận giao hữu có **3 vòng, 60 HP/người**, hai người nhận cùng một câu/vòng và phải giải thích ngắn. Chọn thẻ **trước** khi lộ câu; đúng rõ mới kích hoạt. Hai bên cùng nộp hoặc hết giờ rồi server chấm, chốt hai hành động **đồng thời**, reveal đáp án và hiệu ứng. Màn đề vẫn là phần chính; game diễn ra ở đầu/cuối vòng. Thời lượng thử 90–120 giây/vòng khi phải viết, cần đo thực tế; không lấy tốc độ viết làm thưởng sát thương. Ranked tắt cho đến khi đủ cổng chấm công bằng và cân bằng kit.

`Choáng` có nghĩa **mất lượt dùng thẻ riêng ở vòng kế**, nhưng người học **vẫn trả lời câu hỏi** và có thể chọn thẻ chung. Không khóa màn câu, không tự xử thua một lượt học. Nếu choáng ở vòng 3, không có hiệu lực; UI vô hiệu hóa thẻ gây choáng ở vòng cuối. Một người không thể bị choáng liên tiếp: có `stun_immunity` một vòng sau khi hết choáng. Không có RNG, không có “chí mạng” ngẫu nhiên, không mua HP hoặc lượt.

## 2. Bộ thẻ và nhân vật

Mỗi người chọn **2 trong 4 thẻ chung** làm loadout trước khi sẵn sàng, cộng một thẻ riêng của nhân vật. Đổi loadout sau khi bắt đầu trận bị từ chối. Tất cả thẻ chung mở miễn phí; nhân vật mua bằng Đồng Mực chỉ thêm phong cách/chọn chiến thuật có ngân sách cân bằng, không tăng HP gốc. Bản demo nhỏ có thể chỉ dùng `Bút Chớp/Che Vở`, sau đó mở từng thẻ khi có test.

| Mã | Tên trên UI | Hiệu ứng nếu trả lời đúng | Giới hạn/đánh đổi |
| --- | --- | --- | --- |
| `quick_pen` | Bút Chớp | 20 sát thương | không phòng thủ/hồi |
| `notebook_guard` | Che Vở | 8 sát thương, chặn 12 sát thương nhận vòng này | ít sát thương |
| `bandage_note` | Dán Bìa | hồi 12 HP, 0 sát thương | không quá 60 HP; không hồi nếu bài sai |
| `ink_siphon` | Mượn Mực | 12 sát thương; hồi `min(6, floor(sát thương thực gây ra/2))` | bị chặn hết thì không hút được |
**Thẻ riêng và nhân vật:** chưa chốt. Không tạo ID/asset/catalog từ bộ cũ. Luật 100 HP/50 giáp, nội tại và chiêu mới phải được mô phỏng và duyệt cùng người học trước ranked. Tránh diện mạo trường/lớp cụ thể, giới tính ép buộc, ảnh trẻ em thật hoặc meme bản quyền.

## 3. Thứ tự tính và ví dụ để code

Server khóa `skill_id`, `question_revision`, `rubric_revision`, `combat_rule_version` lúc bắt đầu vòng. Với mỗi bên: nếu `correct`, lấy `attack`, `block`, `heal`, `status` từ thẻ; nếu `incorrect/timeout`, tất cả bằng 0. `uncertain` ở ranked → void trận; giao hữu → void vòng. Buff Nạp Mực tiêu ở vòng kế ngay cả khi bài sai, chỉ cộng vào **attack đúng**, không cộng vào hồi. Không có speed bonus khi buộc viết.

Cho A/B: `raw_to_B=max(0,attack_A+buff_A-block_B)`; `actual_to_B=min(hp_B_before,raw_to_B)` (tương tự A). Hút máu của A tính từ `actual_to_B`; `heal_A=min(12 hoặc hút_máu, max_hp-hp_A_before)` theo thẻ đã chọn. **Cùng một snapshot đầu vòng**, tính `hp_A_after=clamp(hp_A_before-actual_to_A+heal_A,0,60)` và B tương tự; không lấy HP mới của A để tính đòn của B. Nếu cả hai về 0, hòa. Status cho vòng sau chỉ áp nếu trận còn tiếp diễn. Damage/heal/choáng là số do server chốt, animation không gây tác dụng thứ hai.

Ví dụ ở 60 HP: A đúng `ink_siphon`, B đúng `notebook_guard`: A gây `max(0,12−12)=0`, không hút máu; B gây 8, nên A 52, B 60. A còn 30 HP đúng `bandage_note`, B sai → A 42, B 60. A đúng `binder_stun` vòng 1, B đúng `quick_pen`: A 40, B 50; vòng 2 B vẫn nhận đề và được chọn một trong hai thẻ chung, chỉ thẻ riêng bị khóa. A còn 5 HP chọn hồi 12, B đánh 20: HP A về 0 nếu không có chặn; hồi cùng vòng không cứu được trong ví dụ này (`clamp(5−20+12)=0`).

**Cần test cân bằng:** Dán Bìa có thể tạo chiến thuật kéo dài/hòa; giới hạn 3 vòng và quyết định thắng theo HP còn lại, không có thời gian bù vô hạn. Hút máu dùng damage thực sau block. Choáng chỉ khóa thẻ riêng, có thể yếu với người dùng loadout chung; giữ mục tiêu chiến thuật nhẹ. Nếu tỉ lệ thắng lệch, tắt các thẻ mới bằng feature flag trong ranked, vẫn có thể thử giao hữu có nhãn `Luật thử nghiệm`.

## 4. Bản đồ, hiệu ứng và ngân sách hiệu năng

Ba map 2D: **Sân Trường Giấy** (đường kẻ vở), **Thư Viện Cuối Tiết** (giá sách giấy), **Bàn Học Bình Minh** (ánh sáng nhẹ qua cửa). Map chỉ thay phông, âm thanh và câu thoại; **không cộng chỉ số, không che đề, không tạo RNG** trong ranked. Màu tương phản và bảng đề không phụ thuộc map. Màn trận chia `status/HP + hai avatar` ở trên, `đề và vùng viết` ở giữa, `nút nộp` ở dưới. Khi chấm/reveal, đề vẫn xem lại được.

| Hiệu ứng | Hình ảnh/âm thanh đề xuất | Fallback chữ/tĩnh |
| --- | --- | --- |
| Tấn công | nét bút lướt qua mép khung, giấy rung nhẹ | `Bút Chớp · 20 sát thương` |
| Chặn | trang vở gập trước avatar, bụi giấy nhỏ | `Chặn 12` |
| Hồi | miếng băng giấy dán thanh HP, mực xanh quay lại | `Hồi 12 HP` |
| Hút máu | giọt mực đi từ thanh HP đối thủ sang bút, **không màu máu** | `Hút 4 HP` |
| Choáng | kẹp giấy xoay nhẹ trên thẻ riêng, không hiệu ứng nhấp nháy mạnh | `Thẻ riêng bị khóa 1 vòng` |
| Nạp sức | lọ mực sáng lên một nhịp | `Đòn sau +10` |
| Kết quả | trang vở lật và dấu kiểm, không bắn pháo hoa dài | `Thắng/Hòa/Thua` rõ bằng chữ |

Asset gốc: sprite PNG/WebP 2D, atlas theo nhân vật/map; `idle`, `think`, `attack`, `guard`, `heal`, `stunned`, `win`, `rest`, mỗi clip 4–8 frame ở 8–12 fps; neo chân cố định. Tải sẵn ở phòng chờ, giới hạn một FX ngắn 300–500 ms sau chốt vòng; âm thanh tắt được. `Reduce Motion`, máy nóng, asset lỗi hoặc FPS thấp → frame tĩnh + text/HP; không dùng GIF mạng, emoji hệ thống, 3D hoặc giật màn liên tục. Đòn chỉ là phép ẩn dụ giấy/bút, tránh mô tả thương tích cơ thể. Nút trả lời/giờ còn lại không bị FX che và TalkBack đọc kết quả số.

## 5. Giọng vui “bựa vừa đủ”

Humor nằm ở **tình huống**, không nhận xét trí thông minh/người thua. Lời thoại mới cần đội nội dung duyệt; không dùng câu thoại từ roster đã hủy. Không chen lời lúc đọc đề; mỗi vòng tối đa một câu, có tắt hài hước. Cấm câu trêu ngủ nướng, “ngu”, “gà”, hạ nhục trường/lớp, đùa về sức khỏe hoặc nội dung người lớn. Không sao chép meme/nhân vật nổi tiếng. UI thao tác dùng lời ngắn: `Chọn thẻ`, `Viết cách làm`, `Nộp bài`, `Đang chấm`, `Xem lời giải`.

## 6. API/SQL và cổng phát hành

`match_players` thêm `max_hp=60`, `character_id`, `kit_version`, `loadout_ids`; `round_results` thêm `heal_a/b`, `block_a/b`, `status_applied`, `combat_rule_version`; `round_statuses(match_id,user_id,status_id,starts_round,expires_after_round,source_event_id)` unique theo nguồn; `combat_events` lưu damage/heal/status đã chốt, không cho client ghi. `round_submissions` tham chiếu `grading_decision_id` theo docs/39. `POST /v1/matches/{id}/loadout` trước ready; `GET /v1/game/skills` trả kit/giá trị từ catalog version; `POST /skill` chỉ nhận skill thuộc loadout và đúng vòng, **từ chối thẻ riêng nếu đang choáng nhưng vẫn nhận thẻ chung**. Event reveal gồm `hp_before/after`, `damage`, `heal`, `block`, `status`, `effect_id`, `sequence`; không chứa bài viết/ảnh riêng của đối thủ.

Trình tự: giao hữu 2 thẻ chung → thêm hồi/hút → nhân vật thứ tư/choáng → playtest 30+ trận/kit và đánh giá chấm trình bày → mới xem xét ranked. Kiểm tra hai đòn đồng thời, hồi khi HP gần 0/60, block khiến hút 0, choáng vòng 3 bị cấm, stun immunity, retry/đổi kit, Reduce Motion, map không đổi kết quả và quyền xem bài đối thủ. Tham số HP/skill là **giả thuyết**, không phải đã cân bằng.
