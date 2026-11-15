# Lịch học, kế hoạch ngày và thông báo

**Phạm vi:** cá nhân hóa câu ôn và việc hôm nay. [PRD](01-prd.md) là nguồn hành vi chung; [alarm Android](../02-engineering/02-bao-thuc-android.md) sở hữu chuông OS. Tính năng này không đổi giờ báo nếu người dùng chưa xác nhận.

## Dữ liệu đầu vào và ưu tiên

Người dùng chọn lớp THPT/chương trình học, môn/tổ hợp thi từ [catalog đã duyệt](../02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md), mức tự đánh giá, ngày học trong tuần, giờ bắt đầu, thời lượng di chuyển và giờ ngủ mong muốn **tùy chọn**. Có thể nhập tay hoặc chụp TKB để AI gợi parse; bản parse phải được xem, sửa, xác nhận trước lưu. Lịch cá nhân được ưu tiên hơn suy đoán AI; lịch ngày nghỉ/ngoại lệ ưu tiên hơn lịch lặp. Mỗi buổi có `subjectId`, tên hiển thị, start/end local time, timezone, curriculum version và `source=manual|import_confirmed`.

Không thu vị trí, trường, lớp cụ thể hoặc tình trạng sức khỏe để lập lịch mặc định. Không coi giờ ngủ mục tiêu là tư vấn y tế. Người dùng có thể bỏ qua TKB và dùng báo thức thường.

## Hành trình ngày

1. Tối hôm trước: nếu đã bật nhắc, app hiển thị tối đa một bản tóm tắt ngày mai và nút `Xem kế hoạch`. Không tự tạo âm chuông mới.
2. Khi mở app: `Hôm nay` có buổi học theo giờ, tối đa ba việc do người dùng chọn hoặc xác nhận từ plan nháp, câu ôn đề xuất, trạng thái đã hoàn thành/chưa làm. Việc quá hạn không biến thành phạt/uy tín.
3. Chuông reo: câu cache từ môn học ngày hôm đó nếu có content duyệt phù hợp. Nếu nhiều môn, ưu tiên môn sắp học và các điểm sai gần đây, nhưng phải có giới hạn lặp/độ khó; cho đổi môn thủ công.
4. Sau câu: cho `Xem lịch hôm nay`, `Bắt đầu 15 phút học`, `Để sau`. Không tự kéo dài âm báo.
5. Kết ngày: người dùng có thể sửa việc hoàn thành; AI có thể đề xuất ngày mai một việc nhỏ dựa trên lịch và câu sai, nhưng chỉ lưu sau xác nhận.

## Quy tắc đề xuất

Engine xác định trước `candidate = published questions ∩ subjects today ∩ grade/curriculum ∩ rights valid`. Chọn có giải thích: `Môn Toán học lúc 7:15`, `Ôn lại chuyên đề đã sai`. Ngày đầu dùng nhận biết/dễ; tăng độ khó theo số bài **đã được chấm chắc** và lựa chọn người dùng, không theo rank game hay chỉ số AI suy đoán. Nếu tập ứng viên rỗng, hiện `Chưa có câu phù hợp hôm nay` và cho tự chọn môn; không gọi Gemini để tạo câu chấm điểm tức thì.

AI có thể: parse TKB từ ảnh sau consent, tóm tắt việc hôm nay, gợi khung tự học ngắn, đề xuất giờ dậy dựa trên giờ học/di chuyển do người dùng nhập. AI **không** tự bật alarm, tự sửa TKB, ép giờ dậy hay chẩn đoán giấc ngủ. Đề xuất kèm lý do và nút `Dùng giờ này`/`Giữ giờ cũ`.

## Thông báo và lỗi

Nhắc TKB/việc dùng local notification theo quyền OS, cho phép tắt từng loại và quiet hours; không dựa vào push cloud để báo thức. Mặc định trên màn khóa chỉ hiện `Bạn có lịch học hôm nay` hoặc thông báo trung tính; user tự bật hiển thị môn chi tiết. Khi quyền thông báo bị từ chối, nội dung vẫn xem trong app và hiển thị hướng dẫn mở quyền khi cần. Khi đổi múi giờ/giờ mùa hè/sửa buổi học, tính lại lịch thông báo idempotent theo event ID; không gửi dồn nhắc cũ. TKB offline giữ bản đã xác nhận và gắn `Chưa đồng bộ` khi login/sync lỗi. Nhắc buổi chiều là notification nhẹ; chỉ reo kiểu alarm nếu user tự tạo chuông riêng. [Lịch ngủ/chuông](09-giac-ngu-va-bao-thuc.md).

## Acceptance trước khi code

- TKB nhập tay, sửa một buổi, nghỉ ngày đặc biệt và đổi timezone cho kết quả ngày đúng; chụp TKB không lưu khi user hủy.
- Không có môn/câu phù hợp vẫn xem lịch, dừng chuông và học timer được.
- Đề xuất giờ dậy/việc không có hiệu lực nếu user không xác nhận.
- Nhắc bị từ chối, tắt loại nhắc, quiet hours và sửa lịch không tạo thông báo trùng.
- Không lộ TKB trong notification lock screen nếu cài ẩn nội dung; dữ liệu bạn khác không xem được.

[SQL](../02-engineering/03-du-lieu-sql.md) và [API](../02-engineering/04-hop-dong-api.md) phải có migration/contract cụ thể trong task mở tính năng; tài liệu này là đặc tả hành vi, không khẳng định đã chạy.
