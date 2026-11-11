# Đặc tả T004

## Vấn đề và kết quả mong muốn

Hiện repo mới ghi metadata nguồn đề, câu PvP dựa vào đáp án cuối, luật kỹ năng ít trạng thái. Sau task, đội coding biết rõ dữ liệu nghiên cứu nào đã lấy được, điều kiện xuất bản, cách yêu cầu trình bày và chấm công bằng, công thức PvP mới, đường tăng độ khó và gợi ý giờ dậy.

## Phạm vi

- **Trong phạm vi:** tài liệu sản phẩm/SQL/API/test; tải nguồn công khai vào staging cục bộ cho nghiên cứu nếu khả thi; manifest hash/count; không phát hành câu nguồn.
- **Ngoài phạm vi:** app/backend/game chạy thật, ảnh sprite, cấp phép nội dung, tích hợp câu nguồn vào sản phẩm.
- **Dữ liệu/role/quyền:** raw nguồn chỉ ở local gitignored; không dùng bài làm học sinh thật; chỉ người duyệt nội dung mới có quyền xuất bản.
- **Tài liệu chuẩn:** docs/31, 34, 35, 37, 38 và docs/14, 28, 32.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi/hồ sơ phải có | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Hai nguồn VNHSGE/VMLU công khai | staging nghiên cứu local hoặc ghi rõ lý do không tải được; manifest nguồn/hash/count, không commit raw | TC-01 |
| AC-02 | Câu ở báo thức/giao hữu/ranked | đáp án + giải thích/bước làm theo rubric; đường chữ thay camera; `uncertain` không phạt và không đổi rating | TC-02 |
| AC-03 | PvP có heal/lifesteal/stun/buff | thứ tự tính đồng thời, giới hạn HP/status, không tước quyền trả lời câu hỏi; ví dụ tính được | TC-03 |
| AC-04 | Người mới đặt lịch và chọn môn | tăng khó theo bằng chứng, hai đối thủ cùng đề; gợi ý giờ dậy từ giờ học/di chuyển/chuẩn bị và người dùng xác nhận | TC-04 |
| AC-05 | Bản mô tả sản phẩm/asset | nhân vật người/động vật, map/FX, nội dung vui phù hợp học sinh, giới hạn hiệu năng/truy cập | TC-05 |

## Hợp đồng và trường hợp biên

Không có API thực thi trong task này. Contract đề xuất phải tách `answer_spec`, `reasoning_rubric`, `grading_result`, `combat_rule_version`. AI chỉ trả nhận định có chứng cứ; backend chốt điểm theo rule đã version hóa. AI lỗi/ảnh mờ/đa lời giải hợp lệ → `uncertain`, bảo toàn quyền dừng khẩn cấp và không đổi RP. Không đưa ảnh/token/raw source vào log hoặc git.

## Quyết định/mâu thuẫn

Yêu cầu hiện tại thay hướng “ranked chỉ đáp án cấu trúc, AI ngoài trận” của docs/35: ranked có thể chấm trình bày **sau khi nộp** chỉ khi đã đạt cổng kiểm định với mẫu người chấm; trước đó giao hữu và ranked tắt. Không dùng AI sinh đề trực tiếp trong trận. Stun chỉ khóa thẻ riêng một vòng, người học vẫn được trả lời và dùng thẻ chung.
