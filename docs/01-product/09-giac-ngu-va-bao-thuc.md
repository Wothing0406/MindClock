# Lịch ngủ, đồng hồ và buổi sáng

**Vai trò:** giúp người dùng thấy mối quan hệ giữa giờ ngủ và giờ dậy, đặt **nhiều báo thức** và vào một câu ôn ngắn sau khi thức. Ảnh iOS user gửi là tham chiếu cách biểu diễn vòng ngủ/thức, **không sao chép giao diện**. Android đầu tiên; khả năng màn khóa phụ thuộc OS/quyền/máy. [Alarm kỹ thuật](../02-engineering/02-bao-thuc-android.md), [động lực](10-dong-luc-va-kiem-chung.md).

## Màn đồng hồ

Tab `Báo thức`: danh sách nhiều chuông, giờ/lần reo tiếp theo/ngày lặp/âm/quyền; tạo, sửa, tắt, xóa, thử âm. Khi đặt chuông mới (`S06`), mặc định auto bật **Báo thức thử thách** và để hệ thống/AI **tạo sẵn 1 câu hỏi cá nhân hóa** dựa trên `StudyProfile` (lớp, môn, mức độ) + thời khóa biểu ngày báo thức kích hoạt (xóa bỏ hoàn toàn bước chọn môn thủ công và chọn chế độ thường/thử thách rườm rà), hiển thị thẻ xem trước chủ đề/môn/nguồn câu ngay trên màn cài chuông và vẫn luôn có nút **Dừng khẩn cấp** 1 chạm khi reo. Tab `Lịch ngủ`: vòng 24 giờ có hai tay nắm giờ lên giường và giờ dậy, hiển thị thời lượng dự kiến bằng chữ lớn, không chỉ màu; thay giờ bằng trường nhập số/bộ chọn cho TalkBack. Nhấn `Lưu` mới đổi lịch; nếu thay giờ dậy của chuông đang dùng, hiển thị các chuông bị ảnh hưởng để user xác nhận. Cho chọn MP3 cục bộ/tệp người dùng có quyền hoặc âm tích hợp; kiểm tệp không đọc được và fallback âm OS. Không phát nhạc game làm alarm.

Với học sinh 13–17 tuổi, [CDC nêu khuyến nghị 8–10 giờ](https://www.cdc.gov/sleep/about/); người 18–60 tuổi từ 7 giờ. Đây là **tham chiếu chung**, không phải kết luận cá nhân. UI nói `Lịch này dự kiến 7 giờ. Bạn có thể cần thời gian ngủ dài hơn.` và cho điều chỉnh; không tự ép giờ dậy hay dùng thiếu ngủ làm điểm phạt. Không yêu cầu ngày sinh đầy đủ; nhóm tuổi tự khai/consent chỉ để chọn lời nhắc phù hợp. Khi giờ học sớm khiến không đủ thời gian ngủ, ưu tiên gợi ngủ sớm hoặc giảm task, không gợi dậy sớm hơn.

## Giờ đi ngủ và Không làm phiền

Đến giờ ngủ: local reminder `Sắp đến giờ nghỉ. Bạn muốn tắt nhắc học tối nay?`; có nút mở cài đặt DND/chế độ ngủ hoặc bật quy tắc app **chỉ khi người dùng đã cấp quyền và OS hỗ trợ**. Không hứa tự bật DND trên mọi Android. Nếu không cấp quyền, app im lặng các nhắc học của chính nó theo quiet hours, nhưng **không thể im lặng ứng dụng khác**. Android 15 thay đổi cách app target API 35 điều khiển DND toàn hệ thống; implementation phải kiểm version và trạng thái thật, có đường người dùng tự bật. [Notification Policy access](https://developer.android.com/reference/kotlin/android/provider/Settings#ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS), [Android 15 behavior](https://developer.android.com/about/versions/15/behavior-changes-15).

## Reo và câu buổi sáng/chiều

Trước giờ reo, app có thể cache câu published phù hợp TKB + trình độ; AI không cần chạy đúng giây reo. Khi chuông đến, native phát âm/rung, hiển thị trên màn khóa theo full-screen intent/quyền hoặc notification fallback. Nội dung màn khóa mặc định chỉ `Báo thức 06:00` và `Mở để xem kế hoạch hôm nay`; **không lộ môn/TKB chi tiết khi màn khóa chưa mở**, user có tùy chọn hiển thị thêm sau khi hiểu rủi ro. Người dùng bấm `Mở câu` để vào app **và dừng âm/rung cục bộ trước cảnh mở màn**, nhưng lượt học chưa được tính hoàn thành; hoặc bấm `Dừng khẩn cấp` để tắt âm/rung ngay và kết thúc lượt không thưởng. Full-screen không có nghĩa app tự mở khóa hay cấm OS dismiss. [Android full-screen/lock-screen visibility](https://developer.android.com/develop/ui/compose/notifications/create-notification#full-screen_intent).

Trong app **không có màn hỏi muốn bắt đầu, chạm điểm sáng, uống nước hay chụp ly nước**. Mở đầu bằng một cảnh 6–12 giây đã tải sẵn: nhân vật/hình huống đặt một câu hỏi, dừng ở khoảnh khắc cần suy nghĩ, rồi chuyển vào câu tự luận ngắn **liên quan trực tiếp** đến cảnh. Ví dụ Vật lí: một vật tiếp tục trượt khi xe dừng; người học nêu hiện tượng và một lý do. Cảnh không được lộ đáp án; phần kết của cảnh có thể xem sau khi kết thúc lượt, kể cả khi bỏ lượt. `Bỏ qua mở màn` chỉ bỏ đoạn xem, vẫn vào cùng câu. Asset lỗi, máy yếu, Reduce Motion hoặc không có mạng thì hiện 1–2 câu chữ tĩnh tương đương; câu và Dừng không bị chặn. Danh sách cảnh và quy trình nguồn ở [thư viện mở màn](11-canh-mo-man-va-nguon-video.md).

Câu từ ngân hàng duyệt yêu cầu đáp án + một bước trình bày bằng chữ, hoặc chụp **ảnh mới** từ camera sau quyền/xem lại/xác nhận; không chọn ảnh thư viện ở mode thử thách (không phải chống gian lận tuyệt đối). Gemini dùng quy tắc bộ môn rút từ EduSkills để **đề xuất** đọc và đánh giá bước; backend chốt `correct/incorrect/uncertain`. Câu đúng, đủ bước và được xác minh mới hoàn thành lượt, xét EXP/chuỗi. Sai rõ: cho thử lại; từ lần `incorrect` rõ thứ 3 có gợi ý một bước; từ lần thứ 5 hiện `Bỏ lượt` và `Thử tiếp` (ngưỡng v0.1 cần thử người dùng). `Bỏ lượt` kết thúc phiên, **không cộng EXP hoặc ngày chuỗi**, không trừ EXP/RP/vật phẩm đã có. Nếu đây là ngày người dùng đã chọn có thử thách, chuỗi ngày liên tiếp kết thúc theo quy tắc công khai; ngày nghỉ lên lịch trước không phải ngày thử thách. Đóng app trước khi hoàn thành giữ phiên có thể tiếp tục trong ngày; qua ngày mà không hoàn thành thì không thưởng và kết thúc chuỗi, không gán nhãn gian lận. `uncertain`, lỗi AI/câu/mạng không tính là sai; nếu lỗi hệ thống chưa khôi phục trong ngày thì ghi ngày miễn trừ không thưởng và không làm đứt chuỗi cũ.

Chuỗi ôn sáng ở đoạn trên **khác** chuỗi `Đúng giờ` dự kiến cho [nhóm bạn và pet](12-lich-chung-ghep-phong-va-pet-nhom.md): hoàn thành câu muộn trong ngày vẫn có thể giữ kết quả ôn theo chính sách hiện hành, nhưng không cấp dấu đúng giờ để chăm pet. Mốc đúng giờ cần test Android thật, clock drift và lỗi OS trước khi triển khai; không được lấy giờ chuông trên server làm bằng chứng người học đã tỉnh.

Làm bài là **bắt buộc để hoàn thành lượt sáng**, không là điều kiện dừng âm báo thức hay điều kiện dùng điện thoại. `Dừng khẩn cấp` luôn tắt âm/rung một chạm và kết thúc lượt không thưởng khi người dùng chọn; app không thể ngăn force stop/gỡ app. Không giữ chuông reo cho đến khi đúng. Câu chiều từ lịch là **nhắc ôn**, không tự động là alarm âm lớn trừ khi user đặt riêng.

## Acceptance

| ID | Khi | Phải xảy ra |
| --- | --- | --- |
| SLEEP-01 | Có 2+ alarm và lịch ngủ | Sửa một alarm không đổi chuông khác; vòng/nhập số cùng thời lượng, cảnh báo theo nhóm tuổi không ép. |
| SLEEP-02 | Đến giờ ngủ, DND bị từ chối/OS không hỗ trợ | App chỉ im lặng nhắc của chính nó và hướng dẫn; không nói đã bật DND toàn máy. |
| SLEEP-03 | Màn khóa, nội dung riêng tư mặc định | Không lộ TKB/môn; full-screen hoặc notification fallback; Dừng âm/rung một chạm. |
| SLEEP-04 | Ảnh sai/mờ, Gemini timeout, offline | Người dùng nhập chữ/ôn sau/dừng; không phạt, không kẹt âm. |
| SLEEP-05 | User chọn MP3 lỗi/đổi quyền tệp | Có âm fallback, UI báo tệp không dùng được, không làm mất alarm. |
| MORNING-01 | Mở app từ alarm thử thách | Vào mở màn rồi câu, không hỏi bắt đầu; bỏ qua mở màn vẫn phải làm cùng câu; lỗi asset/Reduce Motion dùng chữ tĩnh. |
| MORNING-02 | Sai rõ 3 rồi 5 lần | Gợi ý chỉ từ lần 3; `Bỏ lượt` từ lần 5; `uncertain`/lỗi mạng không tăng sai; Dừng âm luôn có. |
| MORNING-03 | Đúng, bỏ lượt, lỗi hệ thống hoặc dừng khẩn cấp | Chỉ đúng hợp lệ xét EXP/chuỗi một lần; bỏ lượt/dừng không được thưởng hoặc phạt thêm; lỗi hệ thống không làm mất chuỗi oan. |

Đường chụp camera chỉ giúp yêu cầu nỗ lực trực tiếp; điện thoại thứ hai và hỗ trợ ngoài vẫn có thể làm hộ. Không tuyên bố chống gian lận tuyệt đối.
