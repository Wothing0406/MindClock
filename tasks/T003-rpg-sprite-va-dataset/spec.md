# Đặc tả T003

## Vấn đề và kết quả mong muốn

Đội cần một luật kinh tế/rank có thể lập trình, asset sprite 2D và nguồn câu có quyền sử dụng rõ. Bản docs cũ chưa có tiền tệ, nhân vật mua, bậc rank chi tiết; một số nguồn dataset người dùng đề xuất chưa cho phép nạp thẳng vào app.

## Phạm vi

- **Trong phạm vi:** cập nhật docs hiện hành; cài nhóm skill từ `0x0funky/agent-sprite-forge` vào `.agents/skills/` nếu chưa có; ghi registry/đường nhập dataset và cổng quyền sử dụng.
- **Ngoài phạm vi:** game/app/backend chạy thật, giao dịch tiền thật, nhập toàn bộ corpus không rõ quyền, phát hành ảnh sprite thật.
- **Quyền/dữ liệu:** ví coin trong game, RP/MMR/XP server-authoritative, dữ liệu câu hỏi có provenance/licence, dữ liệu người chưa thành niên theo docs/25.
- **Nguồn chuẩn:** `docs/35`, `docs/34`, `docs/22`, `docs/28`, `docs/25`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Kết quả | Bằng chứng |
| --- | --- | --- | --- |
| AC-01 | Người dùng đọc docs Solo | Có HP, kỹ năng theo nhân vật, RP qua bậc Đồng 1–5 và kinh tế coin có số ví dụ, chống farm | TC-01 |
| AC-02 | Agent làm art | Chỉ có sprite 2D/FX 2D, asset contract và fallback; skill sprite forge có trong dự án và được ghi nguồn | TC-02 |
| AC-03 | Agent tích hợp corpus | Biết nguồn, quyền, schema format 2025, quy trình staging/duyệt/publish; không có bulk content không rõ quyền trong repo | TC-03 |
| AC-04 | Agent coding từ docs | README/AGENTS/skill index trỏ đúng nguồn mới, không còn chỉ dẫn 3D hoặc cơ chế nhân vật đồng nhất làm chuẩn | TC-04 |

## Hợp đồng và trường hợp biên

RP/coin/ownership/skill loadout có ledger/transaction, idempotency, server authority. Không mua sức mạnh bằng tiền thật; nếu thiếu coin hoặc duplicate purchase phải có kết quả rõ. Dữ liệu nhập phải hỗ trợ `single_choice`, `true_false_4`, `short_answer`, ngăn xuất bản nếu thiếu đáp án/giấy phép/duyệt. ViMMRC chỉ metadata cho đến khi quyền được xác nhận.

## Quyết định/mâu thuẫn

Yêu cầu hiện tại thay hướng “mọi avatar cùng kỹ năng” bằng nhân vật có bộ skill riêng nhưng ngân sách sức mạnh ngang nhau và mỗi người chọn được nhân vật miễn phí. 2D sprite là asset duy nhất; 3D trước đó là lịch sử. Quyền của VNHSGE chưa rõ và ViMMRC research-only/gated nên không nạp trực tiếp.
