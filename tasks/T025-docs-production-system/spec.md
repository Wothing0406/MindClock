# Đặc tả T025

## Kết quả mong muốn

Một người mới hoặc AI coding đọc `docs/README.md` là biết đọc gì theo task, app thật là Flutter Android + FastAPI, trạng thái nào mới có mã, còn test nào chưa đạt, dùng contract nào, chia lát cắt nào và release theo cổng nào. Không phải suy luận giữa 57 tài liệu đánh số cũ.

## Phạm vi

- Tài liệu canonical theo: bắt đầu/quy trình, sản phẩm, kỹ thuật, chất lượng, game mở rộng. Mỗi tài liệu có phạm vi, trạng thái và link đến nguồn liên quan.
- Tài liệu cũ chuyển vào `docs/archive/2026-11/`, có chỉ mục giải thích không dùng làm nguồn coding. Không xóa nội dung lịch sử hoặc WIP `54-web-mobile-local.md`.
- Cập nhật mọi Markdown link bị ảnh hưởng trong docs, root README/AGENTS, task và skill Android nội bộ; checker kiểm đệ quy.
- Không đổi source Flutter/Kotlin/FastAPI, schema, API runtime hoặc dữ liệu. Không gọi docs là sản phẩm đã chạy.

## Acceptance ↔ test

| ID | Điều kiện | Kết quả | Test |
| --- | --- | --- | --- |
| AC-01 | Mở `docs/` | Có cây folder có thứ tự đọc, owner và trạng thái; archive riêng, root không còn 57 file đánh số | TC-01 |
| AC-02 | Agent nhận task Android/API/AI/content/game | Tìm được yêu cầu, contract, test, điểm chưa đạt và quy trình AC→test→handoff mà không lấy web demo làm sản phẩm | TC-02 |
| AC-03 | Follow link trong README/AGENTS/docs/task | Không gãy link địa phương do di chuyển; checker quét đệ quy và báo thiếu | TC-03 |
| AC-04 | So repo trước/sau | Mã app/API và WIP T022/T023 không bị sửa/ghi đè; docs không khẳng định test máy thật đã đạt | TC-04 |

## Quyết định

Tài liệu canonical mới có ưu tiên cao hơn archive. Archive giữ tên file cũ để truy nguồn và tránh làm mất ý tưởng; không tự chuyển nội dung mâu thuẫn (kit cũ, web prototype, model/chi phí) thành chuẩn mới. Các đường dẫn trong task lịch sử được cập nhật cơ học khi target di chuyển, nhưng trạng thái/bằng chứng cũ không đổi.
