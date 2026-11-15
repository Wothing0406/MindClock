# Động lực học thay cho cảm giác bị ép

**Vấn đề cần kiểm:** nếu báo thức cứ reo cho tới khi giải đúng và AI quở trách khi rời phòng, người học có thể tắt quyền/gỡ app, thấy xấu hổ hoặc thiếu ngủ. Đây là giả thuyết sản phẩm cần thử với học sinh, không thể giải bằng thêm điểm phạt. [PRD](01-prd.md), [lịch ngủ](09-giac-ngu-va-bao-thuc.md), [phòng học](08-phong-hoc-ai-va-ban-be.md).

## Vòng giá trị ngắn

`Tự chọn mục tiêu nhỏ → bắt đầu dễ → tự trình bày một bước → nhận phản hồi công bằng → thấy tiến bộ của mình → chọn việc tiếp`. Câu sáng nên 1–3 phút ở mức đầu; bài đúng có lời giải thích/tiến độ, bài sai có thử lại/gợi bước, `uncertain` không phạt. Sau câu hiện kế hoạch ngày, một hành động rõ `Bắt đầu 10 phút học` hoặc `Để sau`. Streak ghi ngày thực sự có hoạt động phù hợp, không yêu cầu dậy sớm mọi ngày hoặc hy sinh giờ ngủ. Không dùng thông báo tạo sợ mất hạng hay so sánh với lớp.

## Khi người dùng khó chịu

Nhận dấu hiệu do **user tự báo** (`Quá khó`, `Cần nghỉ`, `Chấm chưa đúng`, `Nhắc quá nhiều`) thay vì suy từ camera. Cho chỉnh độ khó/mức nhắc/âm/giờ, đổi môn, nghỉ 1 ngày không phạt, tắt AI hoặc chỉ dùng đồng hồ. Sai 3 lần mới có gợi ý bước đầu; khi vẫn bí, `Ôn sau` và câu giải thích sau khi hết phiên, không giữ âm chuông. Trong phòng học, `Ít nhắc hơn`/`Im lặng`/`Rời` luôn thấy. Người dùng không bị ép bật camera để được học.

## Động lực xã hội và game

Bạn học là lời mời hai chiều, phòng nhỏ, không công khai việc riêng; gợi `Học cùng 25 phút` thay vì bảng điểm tập trung. PvP chỉ khi người học muốn: cùng câu, trình bày lý do để kích hoạt skill, tướng khác lối chơi nhưng không mua lợi thế. Rank theo môn/mùa có opt-in; profile khác chỉ xem thành tích tổng hợp đã chọn. Humor ở avatar/FX là tình huống nhẹ, không giễu học lực/chấm sai/ngủ muộn.

## Thí nghiệm trước khi mở rộng

| Giả thuyết | Cách kiểm nhỏ | Chỉ số và quyết định |
| --- | --- | --- |
| Câu sáng vừa sức giúp bắt đầu ngày | 8–12 học sinh THPT dùng 1 tuần với consent phù hợp, phỏng vấn việc họ đã làm | Số ngày mở câu, thời gian làm, tự báo khó chịu/giấc ngủ, bỏ quyền/gỡ; nếu phiền cao, giảm/đổi câu. |
| AI nhắc nhẹ hữu ích hơn nhắc nghiêm | Cho user tự chọn, đổi được giữa phiên, hỏi cảm nhận sau | Tỷ lệ tiếp tục phiên, số lần tắt/giảm nhắc, phàn nàn; không tối ưu bằng cách làm user khó rời. |
| Phòng bạn tạo động lực | Thử phòng mời 2 người, đo hoàn thành việc tự báo và lỗi kết nối | Số phòng hoàn thành, report/block, quyền riêng tư; nếu quản lý rủi ro chưa đủ, giữ private beta. |
| Plan AI giúp hơn plan rule | A/B hoặc usability test với nội dung tương đương, có người đánh giá | User có hiểu/sửa/xác nhận plan không, AI có bịa môn/giờ không, chi phí/latency. |

Owner chốt ngưỡng và cách thu dữ liệu trước thử; không dùng ảnh học sinh thật hoặc thông tin học tập nhạy cảm để “demo” khi chưa có điều kiện. Kết luận có thể là bỏ một tính năng gây khó chịu. [Release gate](../03-quality/02-van-hanh-phat-hanh.md).
