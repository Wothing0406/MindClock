# Backend nhân vật, rank, bảng xếp hạng và kiểm thử

> **Cập nhật 12/11/2026:** roster/kit cũ đã hủy. Phần catalog, starter, mua nhân vật và các ví dụ avatar bên dưới là **khung kỹ thuật chưa được phép triển khai** cho tới khi chốt roster/giá/luật mới. `neutral_a`/`neutral_b` trong fixture chỉ là placeholder prototype, không phải nhân vật đã duyệt. `rank_ledger` và nguyên tắc server chốt điểm vẫn giữ.
>
> **Tham chiếu triển khai PvP mới:** [docs/46 §6–7](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md) cho bảng `armor/ward/qi`, action/settle/event và cổng cân bằng; nếu mở coding phải cập nhật schema/API/test ở file này cùng task. Catalog/giá cũ không còn hiệu lực.

**Trạng thái:** hợp đồng **đề xuất cho giai đoạn M3**, chưa có API/SQL đang chạy. [07](07-hop-dong-api-va-ai.md) là quy ước `/v1`, auth, lỗi, idempotency; [28](28-backend-sql.md) là SQL nền; [35](35-solo-rpg-dong-bo-va-ky-nang.md) là trận; [37](37-kinh-te-rank-va-nhan-vat-2d.md) là RP/coin; [21](21-dau-truong-xep-hang.md) là quyền bảng; [43](43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md) là UI. Khi coding, khóa schema/payload trong task và contract tests trước khi mobile/backend tích hợp. **Tên ledger canonical:** `rank_ledger`; không tạo thêm `rating_ledger` cho cùng RP/MMR.

## 1. Quyền và ranh giới dữ liệu

- Khách local được xem ba concept mới có nhãn mô phỏng, không có ví, sở hữu, RP hay bảng server. Online yêu cầu Firebase ID token đã xác minh; backend lấy `uid` từ token. Client không được gửi số dư, giá, điểm, HP, `isCorrect`, `rank`, owner hoặc eligibility làm sự thật.
- Bảng xếp hạng và ghép người lạ **tắt mặc định**. Tuổi/đồng ý được rà soát trước pilot với người chưa thành niên. `competition_profiles` giữ alias/`avatar_id` allowlist và `visible`; không trả email, trường, lịch, giờ dậy, ảnh bài, tài khoản ID thô.
- Server là writer duy nhất của ownership, wallet/coin ledger, `rank_profiles`, `rank_ledger`, match result và bảng. PostgreSQL có FK, unique, transaction; app không truy cập DB trực tiếp. Ảnh bài không nằm trong event, bảng hoặc log.
- Bản client cache bảng có TTL ngắn và `updatedAt`, không được dùng làm nguồn quyết định điểm. Rời bảng phải ẩn khỏi API ngay cả khi worker projection chưa cập nhật; màn client tự bỏ cache cũ khi rời.

## 2. Bảng SQL và bất biến

| Bảng | Khóa/field tối thiểu | Bất biến/ghi chú |
| --- | --- | --- |
| `character_catalog` | `character_id PK`, `price_coin`, `kit_version`, `asset_version`, `status` | Chỉ tạo khi ba concept mới được duyệt; giá/version do server quản; không sửa giá cũ của receipt |
| `character_ownership` | PK `(user_id,character_id)`, `source=starter|purchase`, `acquired_at` | mỗi người chọn starter đúng một lần; không xóa sở hữu vì nghỉ/thua |
| `character_loadout` | PK `user_id`, `equipped_character_id`, `version` | FK ownership; khi match ready, khóa snapshot `character_id+kit_version` |
| `wallets`, `coin_ledger` | PK user; ledger unique `(user_id,source_type,source_id,rule_version)` | số dư không âm; claim/mua concurrent có một kết quả; ledger bù trừ khi sửa |
| `purchase_receipts` | unique `(user_id,idempotency_key)`, `payload_hash`, `result` | cùng key/cùng payload trả cùng receipt; khác payload 409 |
| `competition_profiles` | PK user, `alias`, `avatar_id`, `visible`, `consent_version`, `visibility_version` | `visible=false` mặc định; chỉ avatar allowlist; đổi alias/ẩn bảng tăng version |
| `rank_profiles` | PK `(user_id,scope_id,season_id)`, `rp`, `mmr`, `placement_count`, `version` | scope gồm môn, khối, curriculum/content version; RP 0–1199, khởi 100 theo rule thử |
| `rank_ledger` | `entry_id PK`, `match_id`, `user_id`, scope/mùa, `entry_kind=settle|correction`, `review_id?`, RP/MMR before/delta/after, `rule_version` | unique **settle** `(match_id,user_id,scope_id,season_id)`; correction unique `(review_id,user_id)` để bù trừ có audit; trận void không có settle |
| `boards` | `board_id PK`, scope/mùa, `rule_version`, `status`, `min_visible_members`, `snapshot_version` | bảng chỉ mở khi đủ người opt-in/đủ trận; ngưỡng đề xuất 10 cần pilot |
| `leaderboard_entries` | PK `(board_id,user_id)`, `rp_snapshot`, `alias_snapshot`, `avatar_id`, `visibility_version`, `settled_at` | projection từ `rank_profiles`; đọc phải join `competition_profiles.visible=true` và kiểm mùa/consent hiện hành |

`match_players`, `match_rounds`, `round_submissions`, `round_results`, `match_results` theo [35 §7](35-solo-rpg-dong-bo-va-ky-nang.md); không dùng bảng một submission/người/**trận** của GDD cũ. Index bảng: `(board_id,rp_snapshot DESC,user_id ASC)`; phân trang keyset bằng `(rp_snapshot,user_id)` ký/opaque, **gắn `snapshot_version` trong cursor**. Nếu bảng đổi giữa hai trang, API trả `409 BOARD_CHANGED` để client tải lại trang đầu, tránh nhân/mất hàng; không dùng offset cho bảng đông. Alias/ẩn cập nhật projection qua outbox idempotent; API vẫn áp dụng `visible` hiện hành khi đọc. Một mùa đóng thì board snapshot chỉ đọc, không thay điểm cũ khi mùa mới bắt đầu; yêu cầu xóa/ẩn vẫn được thực hiện.

## 3. Trình tự hoạt động

### Chọn nhân vật và mua

1. Khách xem catalog local; sau đăng nhập `GET catalog` để nhận giá/kit/version hiện tại. `POST starter-character` với `characterId` có idempotency: transaction kiểm chưa có starter, thêm ownership `source=starter`, equip mặc định; retry trả cùng kết quả. Một người không thể lấy bốn starter bằng bốn thiết bị.
2. Sau khi có coin từ nhiệm vụ/trận **được server xác minh**, `GET wallet` hiện số dư. Mua: người dùng xem giá/số dư, xác nhận → `POST purchase` cùng idempotency key. Transaction khóa ví, kiểm catalog active/giá phiên bản/ownership/số dư, ghi ledger âm + ownership + receipt; thiếu coin/đã sở hữu không trừ. Equip sau đó là thao tác riêng, miễn phí.
3. Ở phòng chờ, `ready` kiểm ownership + kit còn bật, lưu snapshot. Đổi avatar/equip trong hồ sơ **không** thay kit của trận đang diễn ra. Kit mới/mất cân bằng chỉ tắt cho trận sau bằng feature flag; không đổi luật giữa trận.

### Chơi, tính RP và dựng bảng

1. Người dùng chọn `Giao hữu`; ranked chỉ hiển thị khi feature flag, consent, scope nội dung, số trận placement, câu/rubric/QA và điều kiện vận hành đều đạt cổng [35 §10](35-solo-rpg-dong-bo-va-ky-nang.md). Ghép cùng `{subject,gradeBand,curriculumId,contentVersion,questionPoolVersion,locale}`; không tự trộn chương trình.
2. Hai người chọn thẻ, cùng nhận đề theo giờ server, nộp đáp án + trình bày. Server chấm `correct|incorrect|uncertain`, chốt HP/kỹ năng đồng thời theo [46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md). `uncertain`, câu lỗi hoặc mất kết nối không đủ bằng chứng → `needs_review|voided`; không đổi RP/MMR. Giao hữu không ghi RP.
3. Ranked hợp lệ: transaction khóa match + hai `rank_profiles` theo thứ tự ổn định, xác nhận `match_results` chưa chốt, tính RP thử `+20/0/−20` với clamp 0–1199 và MMR theo `rank_rule_version`, ghi hai dòng `rank_ledger`, coin/XP đủ điều kiện và result **một lần**. Outbox cập nhật leaderboard sau commit. Retry/worker song song trả cùng result, không có điểm lẻ một bên.

   **Công thức MMR thử để code/test:** từ hai MMR **trước trận** `R_A,R_B`, tính `E_A=1/(1+10^((R_B−R_A)/400))`; `S_A=1|0.5|0` cho thắng/hòa/thua; `delta_A=round_half_away_from_zero(24×(S_A−E_A))`, `delta_B=−delta_A`. Không tính tiếp từ MMR vừa cập nhật của A; lưu cả before/delta/after cùng rule version. Hai người cùng 1000: thắng → `+12/−12`, hòa → `0/0`. K=24 và RP ±20 là **tham số playtest**, không mở ranked trước khi mô phỏng/cân bằng. RP hiển thị dùng `tier=floor(RP/200)` và `division=floor((RP%200)/40)+1` theo [37 §4](37-kinh-te-rank-va-nhan-vat-2d.md).
4. Người học tự bật hiện bảng; chỉ sau 5 trận placement và phân vùng đủ người mới có hàng công khai. Top 20 xếp `RP DESC`, cùng RP có **cùng hạng** (`rank = 1 + số người có RP lớn hơn`); `user_id` nội bộ chỉ ổn định thứ tự hàng đồng điểm, không quyết hạng và không trả ra ngoài. Không lấy MMR/giờ dậy làm tie-break hạng. `myPosition` chỉ trả cho chủ tài khoản đã opt-in/đủ điều kiện. Khi opt-out, API đặt `visible=false` trước khi trả thành công; mọi GET bảng lọc trạng thái mới, dù projection/cache chậm.
5. Nếu phát hiện chấm sai sau khi settle, ghi review/audit và **bù trừ ledger trong transaction**, cập nhật projection; không sửa/xóa âm thầm ledger cũ. Quy tắc hủy/đổi mùa và thời hạn khiếu nại cần chủ vận hành chốt trước ranked pilot; trong khi chưa có, ranked tắt.

## 4. Endpoint `/v1` dự kiến và response tối thiểu

Mọi endpoint dưới đây ngoài catalog công khai nội bộ đều cần bearer token; các write có `Idempotency-Key` khi tạo/claim/mua/settle. Đây là **contract để coding**, chưa có server. Thêm/sửa payload phải cập nhật docs07 và contract tests cùng task.

| Method/path | Request chính | Response/trạng thái | Quyền/lỗi |
| --- | --- | --- | --- |
| `GET /game/characters` | không | `catalogVersion`, nhân vật đã duyệt, `priceCoin`, `kitVersion`, `owned`, `equipped` | chỉ trả metadata công khai, không PII; endpoint chưa mở |
| `POST /game/starter-character` | `characterId` | `ownership`, `equippedCharacterId`, `starterClaimed=true` | `STARTER_ALREADY_CLAIMED`, ID không hợp lệ; idempotent |
| `GET /game/wallet` | không | `balance`, `version`, `updatedAt` | chỉ chủ tài khoản |
| `POST /game/characters/{id}/purchase` | `catalogVersion` | `receiptId`, `balanceAfter`, `ownership` | `INSUFFICIENT_COIN`, `ALREADY_OWNED`, `CATALOG_CHANGED`; idempotent |
| `PUT /game/characters/equipped` | `characterId`, `version` | `equippedCharacterId`, `version` | chỉ sở hữu; `409` version cũ |
| `GET /competition/rank?scopeId=&seasonId=` | scope đã mở | `status=locked|placement|ranked`, `rp`, `tier`, `division`, `nextThreshold`, `matchCount` | RP chỉ của chính mình; không trả MMR |
| `GET/PATCH /me` và `PUT /competition/visibility` | `/me`: alias, avatar/frame, profile version; `/visibility`: `visible`, `consentVersion` | hồ sơ + `visibilityVersion` | một nguồn hồ sơ ở `users`; projection thi đấu chỉ theo opt-in, consent/tuổi; opt-out trả sau khi ẩn; xem docs/52 |
| `GET /competition/boards/{boardId}?limit=20&cursor=` | scope/mùa | `status`, `updatedAt`, `snapshotVersion`, `entries[]`, `myPosition?`, `nextCursor?` | caller phải opt-in/đủ tuổi; chưa đủ 5 trận trả `status=placement`, bảng thiếu người trả `status=not_ready`, cả hai không có entries; mỗi entry chỉ alias/avatar/RP/tier/rank |
| `GET /game/ledger?limit=&cursor=` | không | coin/XP/RP events của chính mình theo scope | owner; không lộ bài/ảnh đối thủ |

Ví dụ **response bảng** (dữ liệu minh họa, không là người thật):

```json
{
  "boardId": "math9-curriculumA-season1",
  "status": "open",
  "snapshotVersion": 12,
  "updatedAt": "2026-11-12T08:00:00Z",
  "entries": [
    {"rank": 1, "alias": "Bạn A", "avatarId": "neutral_a", "rp": 420, "tier": "vang", "division": 1},
    {"rank": 1, "alias": "Bạn B", "avatarId": "neutral_b", "rp": 420, "tier": "vang", "division": 1}
  ],
  "myPosition": null,
  "nextCursor": null
}
```

`rank` trong response là số hạng, không phải index hàng. `myPosition=null` khi tài khoản đã opt-in nhưng chưa đủ placement; người chưa opt-in nhận `403 COMPETITION_NOT_ENABLED` và vẫn xem tiến độ riêng qua `/competition/rank`. Chưa đủ 10 người/board chưa mở trả `status=not_ready` + lời UI `Chưa đủ người để mở bảng`, không trả danh sách nhỏ có nguy cơ nhận diện. Không cache response công khai ở CDN khi chưa kiểm soát opt-out; nếu cache, thời hạn và invalidation phải chứng minh bằng test.

## 5. Test từ hợp đồng đến hai máy thật

| ID | Test | Kỳ vọng |
| --- | --- | --- |
| BR01 | Khách local mở sảnh/nhân vật | xem mẫu, không gọi ví/bảng như có tài khoản |
| BR02 | Hai request starter đồng thời trên hai máy, khác `characterId` | đúng một nhân vật miễn phí; request thua có lỗi ổn định, không thêm ownership |
| BR03 | Retry starter/mua cùng key và payload; khác payload | cùng receipt/result; khác payload `409`, không nhân coin/sở hữu |
| BR04 | Mua thiếu coin, catalog đổi giá, đã sở hữu, hai mua đồng thời | không âm ví/không trừ hai lần; version và ledger khớp |
| BR05 | Equip nhân vật chưa sở hữu hoặc client gửi HP/giá/kit giả | từ chối hoặc bỏ qua field không có quyền; match dùng kit snapshot server |
| BR06 | User A đọc/sửa ví, rank, profile, match của B | `403/404`, không lộ email/UID/ảnh/bài |
| BR07 | 5 placement, RP 0/139/159/199/1199, MMR hai người 1000, thắng/hòa/thua/void | tier/division đúng docs37, clamp đúng; MMR `+12/−12` khi thắng và `0/0` khi hòa; void không đổi RP/MMR |
| BR08 | Hai worker settle cùng match / mạng retry | một result, đúng hai dòng `rank_ledger`, coin/XP idempotent, không có một bên đổi điểm trước |
| BR09 | AI `uncertain`, câu retired/rubric lỗi, hai máy lệch giờ/mạng | void/needs_review, không kích hoạt skill/rank sai; hồi phục qua snapshot/event |
| BR10 | Cùng RP, phân trang qua ranh giới top 20, đổi RP khi đang đọc | cùng số hạng, thứ tự ổn định; cursor cũ trả `409 BOARD_CHANGED`, client tải lại từ đầu |
| BR11 | Board 9→10 người, rồi opt-out còn 9 | không lộ bảng khi dưới ngưỡng; người rời ẩn ngay ở mọi GET/cache |
| BR12 | Đổi alias/avatar, opt-out, mùa đóng, xóa tài khoản | API không hiện tên cũ/ảnh cũ, snapshot mùa vẫn ẩn người rút; dữ liệu riêng theo TTL |
| BR13 | Chữ 200%, Reduce Motion, sprite lỗi, Android yếu | đề/nút/HP/rank vẫn đọc được; frame tĩnh, không lag chặn Nộp/Dừng |
| BR14 | Demo với fixture và không có hai máy/API | màn gắn `Mô phỏng`, không ghi nhận online/AI/rank thật |

Test BR02–BR12 chạy trên PostgreSQL với transaction và hai tài khoản; SQLite local không chứng minh concurrency/rank. BR09 cần hai máy Android hoặc hai client độc lập có mạng giả chậm, nhưng cổng mở online yêu cầu máy thật. Test bảng có dữ liệu **giả tổng hợp**, không ảnh/tên học sinh. Cổng UX ở [43 §5](43-thiet-ke-nhan-vat-avatar-khung-rank-va-bang.md); cổng chấm/ranked ở [39](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). Không gắn `done` cho ranked chỉ vì unit test công thức RP pass.

**Bộ fixture tái lập khi có code:** tạo 11 tài khoản thử không có email thật trong môi trường local/staging, 4 catalog item/kit version cố định, 1 board Toán 9, 3 câu/rubric đội duyệt, hai client Android cùng LAN và Gemini mock có ba kết quả. Cho 9 người đủ placement + opt-in → bảng `not_ready`; người thứ 10 → bảng `open`; hai người RP 420 phải cùng hạng; người thứ 10 rời → bảng trở lại `not_ready` và alias không xuất hiện ở bất cứ API/cache nào. Chạy BR02/03/08 bằng request đồng thời thật trên PostgreSQL; ghi ID phiên bản luật/DB, latency, response và ledger count trong báo cáo task. Sau đó thử hai máy thật cho BR09/13; không dùng fixture để tuyên bố AI chấm công bằng.

## 6. Thứ tự coding và demo đúng khả năng

M3A: ba concept/avatar tĩnh theo docs/46, chưa có cửa hàng → M3B: giao hữu hai máy, Đánh thường, 1 round thật → M3C: 6 round, giáp/khí, ba kit, asset/FX tĩnh và giảm chuyển động → M3D: playtest cân bằng, bộ bài chấm độc lập, consent/khiếu nại/anti-abuse → M3E: chỉ khi cần mới chốt coin ledger/nhiệm vụ/cửa hàng → M3F: RP/rank/bảng mùa. Mỗi bước có task folder theo [tasks/README](../tasks/README.md), AC ↔ BR test và bàn giao thiết bị/phiên bản. Demo trước M3F dùng bảng có nhãn `Mô phỏng`; không tô khung RP thật lên tài khoản chưa có trận ranked.
