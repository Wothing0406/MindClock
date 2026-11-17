# Prompt triển khai đấu trường theo lát cắt

**Dùng cho AI coding trong repo, không phải prompt runtime gửi Gemini.** Mỗi prompt chỉ chạy khi lát trước có bằng chứng. Đọc [AGENTS.md](../../AGENTS.md), [docs index](../README.md), [hiện trạng](../00-start/01-hien-trang.md), [roadmap](../00-start/02-lo-trinh.md), [quy trình](../00-start/03-quy-trinh-vibe-code.md), [GDD](01-pvp-gdd.md), [modes/asset](04-che-do-don-doi-va-asset-gap.md) và docs theo task. Không dùng archive/web prototype làm nguồn.

## Quy tắc chung dán vào mọi prompt

```text
Làm một lát cắt MindClock Android Flutter + FastAPI/PostgreSQL; không tạo web client hay màn mock giả online.
Trước code tạo/tiếp tục tasks/TNNN-ten-ngan với README/spec/plan/tests, AC ↔ TC, source refs và điểm tiếp tục.
Dựa vào PRD/API/SQL/quality canonical, kiểm code thật trước khi nói tính năng đã có. Nếu mâu thuẫn, ghi quyết định và sửa docs/code/test cùng lần.
Câu scored chỉ từ ngân hàng published có revision/rubric/quyền. Gemini đề xuất chấm; backend quyết correct|incorrect|uncertain và mọi HP/EXP/RP/result. Không phát đáp án/rubric trước reveal.
Không dùng giờ dậy/pet làm rating, không bán HP/damage/câu dễ. Không kết tội gian lận từ camera/tốc độ; lỗi AI/network không tự xử thua.
UI vi-VN, không emoji hệ thống, có chữ lớn/TalkBack/Reduce Motion/tắt âm. Asset cần provenance/quyền và manifest; art nghiên cứu chưa tự thành release.
Sau từng lát: test đúng tầng và ghi kết quả thực/môi trường vào tests.md, diff/secret/asset review, handoff; stage đúng file task, commit ID task, push và xác minh remote. Chưa đạt thì giữ verifying.
```

## Prompt G1 — luyện đơn đầu tiên

```text
Mục tiêu: mở Đấu trường → Luyện đơn → chọn môn/tướng → giải câu approved có bước trình bày → chấm ba trạng thái → dùng đòn/chiêu → tổng kết. Offline nếu đã cache. Không RP/MMR/leaderboard.
Đọc: docs/04-game/01-pvp-gdd.md, 02-nhan-vat-asset.md, 04-che-do-don-doi-va-asset-gap.md §2/5/6, docs/02-engineering/05-ngan-hang-cau-hoi.md, 06-ai-va-cham-bai.md, docs/03-quality/05-ca-nghiem-thu.md GAME-06.
Kiểm Flutter thật và assets/game/manifest.json; lập bảng tái dùng/sửa/thiếu. Tạo task G1; không dựng đối thủ online giả. Bot deterministic có seed/replay, không gọi Gemini tự quyết HP. Offline chỉ luyện local. Uncertain có đường sửa/đổi câu.
Triển khai một đường dọc Flutter với câu lớn hơn sân, ba tướng core, qi/chiêu/nội tại, text lý do, result. Unit test bot/rule, widget luồng và Android manual; chỉ import art đã duyệt, nếu quyền chưa rõ dùng placeholder dev/feature flag ngoài release.
```

## Prompt G2 — giao hữu 1v1 có mạng

```text
Mục tiêu: hai người thật cùng môn/khối/curriculum giao hữu 1v1 trên hai Android, cùng câu/rubric/deadline, server chốt HP/event/result, reconnect không nhân action. Ranked tắt.
Đọc: GDD §1–6, docs/04-game/04-che-do-don-doi-va-asset-gap.md §3/5/6, API/SQL canonical, privacy, GAME-01–05/07.
Trước code chốt schema/API với OpenAPI và migration PostgreSQL; tách backend và Flutter thành hai task nếu lát quá lớn. Viết transaction + unique submit/action/settle, owner token A/B, snapshot/event sequence, timeout/void/uncertain/appeal. Client chỉ render server event, không gửi damage/HP/RP.
Test PostgreSQL hai account và hai Android thật; ghi latency, facing/hit/sound và Reduce Motion. Thiếu câu hoặc quyền art thì giữ feature flag tắt cho người dùng.
```

## Prompt G3 — giao hữu đội 2v2

```text
Mục tiêu: hai bạn lập đội, chọn một môn/chương trình, ghép đội khác, bốn người cùng câu mỗi round và nộp lời giải riêng; chỉ correct rõ chọn action/target. Giao hữu, không RP đội.
Đọc: docs/04-game/04-che-do-don-doi-va-asset-gap.md §4–7, GDD 1v1, API/SQL/privacy, GAME-08–10. Chỉ bắt đầu khi G2 có test hai máy/reconnect/void đạt.
Tạo task backend team rule/version/transaction trước, Flutter bốn-slot/target sau nếu cần. Server khóa bốn submission/action, resolve đồng thời; uncertain làm void/review, lỗi teammate không tự phạt RP. Không lộ bài đồng đội trước deadline. Không trộn room học/pet với PvP.
Test bốn account/PostgreSQL/bốn Android, focus fire/heal/ward/KO/hòa, duplicate/reconnect/mất host và UI 320–390dp. Playtest balance, sửa bằng rule version mới trước mở rộng.
```

## Prompt G4 — asset/QA riêng

```text
Mục tiêu: biến asset nghiên cứu đã có thành gói Flutter được duyệt cho G1/G2 rồi thiết kế thêm UI/sân/FX 2v2 cho G3.
Đọc: docs/04-game/02-nhan-vat-asset.md, 04-che-do-don-doi-va-asset-gap.md §6, assets/game/manifest.json, scripts/check_game_assets.py, docs/01-product/03-he-thiet-ke.md.
Trước tạo asset, kiểm nguồn/quyền từng ảnh/âm, master/facing/anchor/animation; nếu quyền thương mại chưa xác nhận thì không đóng gói release. Tạo inventory theo file: reuse/sửa/thiếu. Mỗi tướng một folder source/runtime/fx/audio, không dùng FX của tướng khác.
Sân 2v2 bốn slot có target anchor và Reduce Motion still. Xuất manifest version/hash, preview 320/360/390dp; chạy checker, kiểm bằng mắt hướng/độ rộng/hit đúng target, rồi profile Flutter Android. Pass file count không đồng nghĩa animation/quyền/performance đạt.
```

**Nếu AI trả web demo hoặc nói “đã xong PvP” từ mock:** dừng task, đối chiếu AC/GAME test, ghi sai khác vào `worklog.md`, tiếp tục backend/Android còn thiếu. Không xóa WIP khác hoặc push secret/ảnh người học.
