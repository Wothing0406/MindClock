# UX, luồng màn hình và nội dung tiếng Việt

**Nguồn quy tắc:** [PRD](04-prd-va-dac-ta-san-pham.md). Thiết kế cho học sinh lớp 9, Android trước, `vi-VN`.

## 1. Nguyên tắc giao diện

1. **Vừa thức dậy vẫn dùng được:** một hành động chính mỗi màn, câu hỏi lớn, không ép đọc nhiều chữ.
2. **Không mắng người học:** không dùng “lười”, “thất bại”, “gian lận”, “ngu”, “linh thú suy dinh dưỡng”.
3. **Đúng trạng thái:** có trạng thái “AI chưa chắc”, không biến ảnh mờ thành bài sai.
4. **Cho người dùng kiểm soát:** hoãn và tắt khẩn cấp luôn khả dụng trong luồng chuông.
5. **Minh bạch AI:** trước lần gửi ảnh đầu, nói ảnh được gửi đến dịch vụ AI để phân tích và không lưu mặc định.
6. **Tiến bộ cá nhân:** XP/streak động viên, không xếp hạng công khai ở MVP.

## 2. Bản đồ màn hình MVP

| Mã | Màn | Nội dung/chức năng | Điều hướng |
| --- | --- | --- | --- |
| S01 | Chào mừng | Giá trị một câu, bắt đầu/khám phá | S02 |
| S02 | Đăng nhập | Google/email theo cấu hình, điều khoản và riêng tư | S03 |
| S03 | Thiết lập ban đầu | Lớp, giờ dậy, môn theo ngày; giải thích quyền | S04 |
| S04 | Trang chủ | Lần báo thức tới, môn hôm sau, tiến bộ, sửa lịch | S05/S06/S11 |
| S05 | Thời khóa biểu | Tuần 7 ngày, môn/chủ đề, ngày nghỉ | S04 |
| S06 | Báo thức | Giờ, lặp, âm thanh/rung, quyền hệ thống | S04 |
| S07 | Chuông đang reo | Giờ, câu ngắn, Bắt đầu, Hoãn 5 phút, Tắt khẩn cấp | S08/S04 |
| S08 | Làm bài | Đề, thời gian gợi ý không đếm ngược gây áp lực, Gợi ý, Chụp bài | S09 |
| S09 | Xem ảnh | Cắt/đổi ảnh, Gửi bài, thông tin riêng tư lần đầu | S10 |
| S10 | Phản hồi | Đúng/Sai/Chưa đọc rõ; gợi ý; Thử lại/Xem lời giải/Kết thúc | S08/S11 |
| S11 | Tiến bộ | XP, streak, số buổi, chủ đề cần ôn | S04 |
| S12 | Cài đặt | Quyền, xóa dữ liệu, báo chấm sai, trợ giúp | S04 |

**Không yêu cầu đăng nhập để chuông đã cài tiếp tục reo khi token hết hạn.** Đăng nhập chỉ cần cho đồng bộ/chấm AI. Nếu chưa có tài khoản, có thể cho chế độ khách local ở giai đoạn M2.

## 3. Hành trình chính

### Thiết lập lần đầu

`S01 → S02 → S03 → quyền báo thức/thông báo → S04`. Cài giờ trước; quyền camera chỉ hỏi khi người dùng chụp lần đầu. Không yêu cầu toàn bộ quyền ngay lúc mở app. Khi quyền báo thức bị từ chối, vẫn cho dùng chức năng học và hiện trạng thái “Báo thức có thể không reo đúng giờ”.

### Một buổi sáng bình thường

Thiết bị phát chuông → `S07` → “Bắt đầu thử thách” giảm âm → `S08` → “Chụp bài” → `S09` → “Gửi bài” → `S10 correct` → chuông dừng → `S11` hoặc trang chủ. Nếu muốn tránh tiếng chuông kéo dài, mặc định chuông dừng sau khi bắt đầu và chuyển sang rung nhẹ/nhắc lại; điều này phải được kiểm chứng trong thử nghiệm.

### Sai bài

`S10 incorrect` chỉ đúng bước sai, cho một gợi ý, “Thử lại”. Sau lần thứ hai có “Xem lời giải” và “Kết thúc buổi sáng”. Không đặt vòng lặp vô hạn.

### Ảnh khó đọc/API chậm

`S10 uncertain` → “Chụp lại” hoặc “Nhập đáp án” hoặc “Hoàn thành không chấm”. Nếu hết 15 giây, thông báo “Chưa thể chấm lúc này”; chuông vẫn tắt được. Không tự tăng XP như bài đúng.

### Hoãn/tắt khẩn cấp

Tại mọi màn trong luồng báo thức có đường về `S07` hoặc nút điều khiển nhanh. Hoãn đặt lại 5 phút cục bộ; tắt khẩn cấp dừng ngay và hỏi lý do **tùy chọn** sau đó, không buộc trả lời.

## 4. Bộ nhãn tiếng Việt chuẩn

| Vị trí | Nội dung |
| --- | --- |
| S01 tiêu đề | “Dậy đúng giờ. Nghĩ bằng chính mình.” |
| S01 mô tả | “Một câu ôn ngắn theo lịch học, mỗi buổi sáng.” |
| S04 báo thức kế tiếp | “Chuông tiếp theo: 06:30, Thứ Hai” |
| S07 nút chính | “Bắt đầu thử thách” |
| S07 nút phụ | “Hoãn 5 phút” · “Tắt khẩn cấp” |
| S08 nút | “Gợi ý một bước” · “Chụp bài làm” |
| S09 riêng tư | “Ảnh này sẽ được gửi để AI đọc và phản hồi. MindClock không lưu ảnh mặc định.” |
| S09 nút | “Chụp lại” · “Gửi bài” |
| S10 đúng | “Bạn làm đúng rồi!” · “Bạn đã biến đổi đúng ở bước …” |
| S10 sai | “Hãy xem lại bước này” · “Bạn đã viết …; thử kiểm tra …” |
| S10 chưa rõ | “Mình chưa đọc rõ bài làm” · “Bạn có thể chụp lại dưới ánh sáng tốt hơn.” |
| S10 chậm | “Chưa thể chấm lúc này. Bạn vẫn có thể kết thúc báo thức.” |
| S10 sau sai | “Thử lại” · “Xem lời giải” · “Kết thúc buổi sáng” |
| S11 XP | “+10 điểm kinh nghiệm” · “Bạn đã hoàn thành 4 buổi sáng tuần này.” |
| S12 báo lỗi | “Báo kết quả chấm chưa đúng” |

## 5. Empty, loading và lỗi

| Trạng thái | Hiển thị | Hành động |
| --- | --- | --- |
| Chưa có môn hôm nay | “Hôm nay chưa có môn trong lịch.” | “Chọn câu ôn” / “Chỉ dùng báo thức” |
| Chưa có câu tải sẵn | “Chuông vẫn hoạt động. Câu ôn sẽ có khi kết nối lại.” | “Tắt chuông” |
| Đang chấm | “Đang đọc từng bước bài làm…”; không hiển thị phần trăm giả | “Hủy chấm và kết thúc” |
| Ảnh quá lớn/không hỗ trợ | “Ảnh chưa gửi được. Hãy chụp lại hoặc chọn ảnh nhỏ hơn.” | “Chụp lại” |
| Mất mạng | “Không có mạng. Báo thức vẫn dùng được; chấm bài sau khi kết nối.” | “Hoàn thành không chấm” |
| Không có quyền camera | “Cần quyền camera để chụp bài. Bạn cũng có thể nhập đáp án.” | “Mở cài đặt” / “Nhập đáp án” |
| Không có quyền báo thức chính xác | “Thiết bị chưa cho phép báo thức đúng giờ.” | “Mở cài đặt quyền” |
| Token hết hạn | “Cần đăng nhập lại để đồng bộ tiến độ.” | “Đăng nhập” / “Dùng báo thức” |

## 6. Khả năng tiếp cận

Nút tối thiểu 44×44 dp, có nhãn cho TalkBack, không diễn đạt đúng/sai chỉ bằng màu; có thể tăng cỡ chữ mà không che nút tắt khẩn cấp; rung có thể tắt riêng; âm thanh tăng dần tùy chọn. Với người không thể viết tay hoặc dùng camera, có đường nhập đáp án ngắn, được ghi rõ hình thức khác trong dữ liệu để tránh so sánh thiếu công bằng.

## 7. Màn hình tương lai cần thiết kế riêng

Linh thú chỉ phản ánh hoạt động tích cực, không bị “ốm” vì ngủ thêm. Đấu trường cần quy tắc công bằng, chống quấy rối và bảo vệ người chưa thành niên. Dashboard giáo viên chỉ ưu tiên **xu hướng tổng hợp**, quyền xem cá nhân phải được cấp riêng. Phụ huynh không mặc định xem ảnh bài làm, lịch ngủ hay mọi lần tắt báo thức.

