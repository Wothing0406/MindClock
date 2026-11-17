# Đặc tả T045

## Vấn đề

GDD chỉ đặc tả 1v1, prompt chưa tách lát code, asset inventory chưa chỉ rõ thiếu cho luyện đơn/2v2. T045 tạo nguồn để AI coding không biến một web demo thành arena thật.

## Phạm vi

- Trong phạm vi: docs và prompt; ngoài phạm vi: code/asset runtime/migration.
- Quyền: art nghiên cứu chưa được duyệt thương mại, câu scored published/revision/rubric.

## Yêu cầu kiểm chứng được

| ID | Khi | Tài liệu mô tả | TC |
| --- | --- | --- | --- |
| AC-01 | Chọn mode | Luyện đơn bot, 1v1 người, 2v2 đội có điều kiện riêng | TC-01 |
| AC-02 | 2v2 round | Bốn lời giải riêng, action/target/settle server, uncertain void | TC-02 |
| AC-03 | Chuẩn bị art | Inventory reuse/sửa/thiếu, QA hướng/anchor/quyền/hiệu năng | TC-03 |
| AC-04 | AI coding | Prompt G1–G4 có nguồn, test, cổng, không mock production | TC-04 |

## Quyết định/biên

“Chơi dd” được hiểu là chơi đội 2v2; nếu user định nghĩa khác, sửa mode trước coding. Team HP/armor là nháp playtest, không mở ranked. Luyện đơn offline không cấp RP; không cần tướng thứ tư.
