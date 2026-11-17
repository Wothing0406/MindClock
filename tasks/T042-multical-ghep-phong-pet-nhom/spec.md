# Đặc tả T042

## Vấn đề và kết quả mong muốn

Docs chỉ có phòng mời hai người; chưa chỉ cách tìm giờ rảnh chung, ghép nhóm, AI 1–1/nhóm và pet. Sau task, đội có yêu cầu kiểm chứng được để tách lát triển khai.

## Phạm vi

- **Trong phạm vi:** thiết kế product, contract dự kiến, quyền dữ liệu, lộ trình và test design.
- **Ngoài phạm vi:** code Flutter/FastAPI, migration, dịch vụ media, asset pet, tính năng đã phát hành.
- **Dữ liệu/quyền:** availability riêng, projection free/busy, room membership, pet ledger server; consent trẻ em và moderation trước discovery.
- **Tài liệu chuẩn:** `docs/01-product/12-lich-chung-ghep-phong-va-pet-nhom.md`, `docs/02-engineering/12-lich-chung-va-ghep-phong.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Kết quả tài liệu phải mô tả | Bằng chứng |
| --- | --- | --- | --- |
| AC-01 | Lập hẹn 2–4 người | Chỉ chia sẻ rảnh/bận, cần từng người xác nhận, không đổi alarm | TC-01 |
| AC-02 | Chọn 1–1 AI/bạn hoặc nhóm | Nhãn người tham gia rõ, deep im lặng, camera/mic off | TC-02 |
| AC-03 | Tìm phòng | Cùng môn/cùng tập trung, lọc consent/block/capacity, empty state thật | TC-03 |
| AC-04 | Nuôi pet nhóm | Ledger có cap/idempotency, không phạt người vắng hoặc đổi RP | TC-04 |
| AC-05 | Bàn giao cho coding | PRD ↔ engineering ↔ quality ↔ roadmap có link/ID | TC-05 |

## Hợp đồng và trường hợp biên

API/schema ở docs engineering là **đề xuất**, chưa hiện hữu. Test cần bao phủ timezone/DST, vote cũ, join đồng thời, A/B, mất mạng, đổi account, rút consent, retry thưởng.

## Quyết định/mâu thuẫn

Bản đồ án đề xuất web client, guest vào phòng công khai, khóa app, dùng camera suy xao nhãng và trừ pet/streak tập thể; các điểm đó không đưa vào canonical vì trái nền tảng Android hiện hành và quy tắc an toàn/riêng tư của repo. KPI nêu trong bản đồ án là giả thuyết, chưa phải kết quả thử nghiệm.
