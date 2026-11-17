# Đặc tả T044

## Vấn đề và kết quả

Docs trước có link mời chung và avatar 2D mức trạng thái, nhưng thiếu QR, chat có đích rõ, gửi ảnh hỏi AI sau học và mặt/miệng chuyển động theo audio. Sau task, hành vi và test được mô tả đủ để tách task code.

## Phạm vi

- Trong phạm vi: docs; ngoài phạm vi: Flutter/API/DB/asset thực thi.
- Quyền: QR không mang dữ liệu cá nhân; room membership và AI consent riêng; ảnh không lưu mặc định.

## Yêu cầu kiểm chứng được

| ID | Khi | Tài liệu phải mô tả | TC |
| --- | --- | --- | --- |
| AC-01 | Chia sẻ/quét QR | Link token hạn dùng, xem trước, xác thực/duyệt, thu hồi | TC-01 |
| AC-02 | Chat/gửi ảnh | Chọn đích nhóm/AI, preview/consent, hỏi sau phiên, temp delete | TC-02 |
| AC-03 | AI trả voice | Text fallback, deep không tự phát âm, avatar miệng theo audio thật | TC-03 |
| AC-04 | Học một mình | Không cần phòng/AI/network để học timer | TC-04 |

## Quyết định và trường hợp biên

Chọn avatar rig 2D có mặt biểu cảm thay cho mặt người giả; Reduce Motion ảnh tĩnh. AI không tự nhận toàn bộ chat nhóm. Deep chỉ phát tiếng sau nút `Nghe`. API/schema mới là đề xuất, không mô tả đã chạy.
