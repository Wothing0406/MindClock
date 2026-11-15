# Lịch ngủ, đồng hồ và buổi sáng

**Vai trò:** giúp người dùng thấy mối quan hệ giữa giờ ngủ và giờ dậy, đặt **nhiều báo thức** và vào một câu ôn ngắn sau khi thức. Ảnh iOS user gửi là tham chiếu cách biểu diễn vòng ngủ/thức, **không sao chép giao diện**. Android đầu tiên; khả năng màn khóa phụ thuộc OS/quyền/máy. [Alarm kỹ thuật](../02-engineering/02-bao-thuc-android.md).

## Màn đồng hồ

Tab `Báo thức`: danh sách nhiều chuông, giờ/lần reo tiếp theo/ngày lặp/âm/chế độ/quyền; tạo, sửa, tắt, xóa, thử âm. Tab `Lịch ngủ`: vòng 24 giờ có hai tay nắm giờ lên giường và giờ dậy, hiển thị thời lượng dự kiến bằng chữ lớn, không chỉ màu; thay giờ bằng trường nhập số/bộ chọn cho TalkBack. Nhấn `Lưu` mới đổi lịch; nếu thay giờ dậy của chuông đang dùng, hiển thị các chuông bị ảnh hưởng để user xác nhận. Cho chọn MP3 cục bộ/tệp người dùng có quyền hoặc âm tích hợp; kiểm tệp không đọc được và fallback âm OS. Không phát nhạc game làm alarm.

Với học sinh 13–17 tuổi, [CDC nêu khuyến nghị 8–10 giờ](https://www.cdc.gov/sleep/about/); người 18–60 tuổi từ 7 giờ. Đây là **tham chiếu chung**, không phải kết luận cá nhân. UI nói `Lịch này dự kiến 7 giờ. Bạn có thể cần thời gian ngủ dài hơn.` và cho điều chỉnh; không tự ép giờ dậy hay dùng thiếu ngủ làm điểm phạt. Không yêu cầu ngày sinh đầy đủ; nhóm tuổi tự khai/consent chỉ để chọn lời nhắc phù hợp. Khi giờ học sớm khiến không đủ thời gian ngủ, ưu tiên gợi ngủ sớm hoặc giảm task, không gợi dậy sớm hơn.

## Giờ đi ngủ và Không làm phiền

Đến giờ ngủ: local reminder `Sắp đến giờ nghỉ. Bạn muốn tắt nhắc học tối nay?`; có nút mở cài đặt DND/chế độ ngủ hoặc bật quy tắc app **chỉ khi người dùng đã cấp quyền và OS hỗ trợ**. Không hứa tự bật DND trên mọi Android. Nếu không cấp quyền, app im lặng các nhắc học của chính nó theo quiet hours, nhưng **không thể im lặng ứng dụng khác**. Android 15 thay đổi cách app target API 35 điều khiển DND toàn hệ thống; implementation phải kiểm version và trạng thái thật, có đường người dùng tự bật. [Notification Policy access](https://developer.android.com/reference/kotlin/android/provider/Settings#ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS), [Android 15 behavior](https://developer.android.com/about/versions/15/behavior-changes-15).

## Reo và câu buổi sáng/chiều

Trước giờ reo, app có thể cache câu published phù hợp TKB + trình độ; AI không cần chạy đúng giây reo. Khi chuông đến, native phát âm/rung, hiển thị trên màn khóa theo full-screen intent/quyền hoặc notification fallback. Nội dung màn khóa mặc định chỉ `Báo thức 06:00` và `Mở để xem kế hoạch hôm nay`; **không lộ môn/TKB chi tiết khi màn khóa chưa mở**, user có tùy chọn hiển thị thêm sau khi hiểu rủi ro. Người dùng bấm `Mở câu` để vào app, hoặc `Dừng khẩn cấp` để tắt âm/rung ngay. Full-screen không có nghĩa app tự mở khóa hay cấm OS dismiss. [Android full-screen/lock-screen visibility](https://developer.android.com/develop/ui/compose/notifications/create-notification#full-screen_intent).

Trong app, một câu tự luận ngắn từ ngân hàng duyệt: đáp án + một bước trình bày bằng chữ, hoặc chụp **ảnh mới** từ camera sau quyền/xem lại/xác nhận; không chọn ảnh thư viện ở mode thử thách (không phải chống gian lận tuyệt đối). Gemini đề xuất đọc bước, backend chốt `correct/incorrect/uncertain`. Sai rõ: thử lại, từ lần 3 cho gợi ý bước đầu; sau nhiều lần hoặc mệt, `Ôn sau`/Dừng vẫn có. Câu đúng kết thúc phiên và hiện kế hoạch hôm nay. Không giữ chuông reo cho đến khi đúng; mục tiêu là tạo nhịp học, không tạo bế tắc/thiếu ngủ. Không trừ uy tín vì sai/uncertain/dừng. Câu chiều từ lịch là **nhắc ôn**, không tự động là alarm âm lớn trừ khi user đặt riêng.

## Acceptance

| ID | Khi | Phải xảy ra |
| --- | --- | --- |
| SLEEP-01 | Có 2+ alarm và lịch ngủ | Sửa một alarm không đổi chuông khác; vòng/nhập số cùng thời lượng, cảnh báo theo nhóm tuổi không ép. |
| SLEEP-02 | Đến giờ ngủ, DND bị từ chối/OS không hỗ trợ | App chỉ im lặng nhắc của chính nó và hướng dẫn; không nói đã bật DND toàn máy. |
| SLEEP-03 | Màn khóa, nội dung riêng tư mặc định | Không lộ TKB/môn; full-screen hoặc notification fallback; Dừng âm/rung một chạm. |
| SLEEP-04 | Ảnh sai/mờ, Gemini timeout, offline | Người dùng nhập chữ/ôn sau/dừng; không phạt, không kẹt âm. |
| SLEEP-05 | User chọn MP3 lỗi/đổi quyền tệp | Có âm fallback, UI báo tệp không dùng được, không làm mất alarm. |

Đường chụp camera chỉ giúp yêu cầu nỗ lực trực tiếp; điện thoại thứ hai và hỗ trợ ngoài vẫn có thể làm hộ. Không tuyên bố chống gian lận tuyệt đối.
