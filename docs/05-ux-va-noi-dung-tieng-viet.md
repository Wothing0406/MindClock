# UX, luồng màn hình và nội dung tiếng Việt

> **Nguồn hiện hành:** [nhu cầu học sinh](41-nhu-cau-hoc-sinh-va-kiem-chung-san-pham.md), [báo thức thử thách](31-bao-thuc-thu-thach.md), [lịch nhiều môn](32-ho-so-hoc-tap-va-nhieu-mon.md), [bài làm có trình bày](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md). Chế độ thử thách không có Hoãn; chế độ thường có thể Hoãn.

**Nguồn quy tắc:** [PRD](04-prd-va-dac-ta-san-pham.md). Thiết kế cho học sinh lớp 9, Android trước, `vi-VN`.

**Không gian học:** màn thiết lập/đang học/trợ lý/kết thúc và nhãn khi rời app ở [docs/45](45-khong-gian-hoc-va-che-do-tap-trung.md). Màn báo thức không tự mở camera hoặc tự chuyển sang phiên học; người dùng chọn `Bắt đầu học` sau khi tắt chuông.

## 1. Nguyên tắc giao diện

1. **Vừa thức dậy vẫn dùng được:** một hành động chính mỗi màn, câu hỏi lớn, không ép đọc nhiều chữ.
2. **Không mắng người học:** không dùng “lười”, “thất bại”, “gian lận”, “ngu”, “linh thú suy dinh dưỡng”.
3. **Đúng trạng thái:** có trạng thái “AI chưa chắc”, không biến ảnh mờ thành bài sai.
4. **Cho người dùng kiểm soát:** Dừng khẩn cấp luôn khả dụng; Hoãn chỉ hiện ở chế độ thường. Lịch, môn và mức khó có thể sửa, không để AI tự đổi chuông.
5. **Minh bạch AI:** trước lần gửi ảnh đầu, nói ảnh được gửi đến dịch vụ AI để phân tích và không lưu mặc định.
6. **Tiến bộ cá nhân:** XP/streak động viên, không xếp hạng công khai ở MVP.

## 2. Bản đồ màn hình MVP

| Mã | Màn | Nội dung/chức năng | Điều hướng |
| --- | --- | --- | --- |
| S01 | Chào mừng | Giá trị một câu, bắt đầu/khám phá | S02 |
| S02 | Bắt đầu | `Dùng thử không cần tài khoản`; email/mật khẩu chỉ khi cần đồng bộ/thi đấu | S03 |
| S03 | Thiết lập ban đầu | Lớp, giờ dậy, môn theo ngày; giải thích quyền | S04 |
| S04 | Trang chủ | Lần báo thức tới, môn hôm sau, tiến bộ, sửa lịch | S05/S06/S11 |
| S05 | Thời khóa biểu | Tuần 7 ngày, môn/chủ đề, ngày nghỉ | S04 |
| S06 | Báo thức | Giờ, lặp, âm thanh/rung, quyền hệ thống | S04 |
| S07 | Chuông đang reo | Giờ, môn, `Mở câu hỏi`, `Dừng khẩn cấp`; Hoãn chỉ ở mode thường | S08/S04 |
| S08 | Làm bài | Đề, chọn/nhập đáp án, `Viết cách làm` hoặc `Chụp nháp`, Dừng khẩn cấp | S09/S10 |
| S09 | Xem ảnh (tùy chọn) | Xem/chụp lại, chọn gửi ảnh AI, nhắc che thông tin riêng | S10/S08 |
| S10 | Phản hồi | Đúng/Sai/Chưa đủ rõ; gợi ý **theo số lần sai rõ**, Thử lại/Xem lời giải/Kết thúc | S08/S11 |
| S11 | Tiến bộ | XP, streak, số buổi, chủ đề cần ôn | S04 |
| S12 | Cài đặt | Quyền, xóa dữ liệu, báo chấm sai, trợ giúp | S04 |

**Không yêu cầu đăng nhập để đặt và dùng chuông local.** Tài khoản chỉ cần cho đồng bộ, chấm AI và thi online. Token hết hạn không làm mất báo thức. Khách local thấy rõ tiến độ chưa đồng bộ và không có XP/RP có thẩm quyền từ server.

## 3. Hành trình chính

### Thiết lập lần đầu

`S01 → S02 dùng thử → S03 chọn giờ/môn hoặc Để sau → quyền báo thức khi lưu → thử chuông → S04`. Nếu nhập giờ học, hiển thị phép tính gợi ý giờ dậy và yêu cầu xác nhận. Quyền camera chỉ hỏi khi người dùng chụp lần đầu; không yêu cầu toàn bộ quyền ngay lúc mở app. Khi quyền báo thức bị từ chối, vẫn cho học thủ công và hiện `Thiết bị chưa cho phép báo thức đúng giờ`.

### Một buổi sáng bình thường

Thiết bị phát chuông → `S07` → `Mở câu hỏi` giảm âm đủ để đọc → `S08` nhập đáp án **và một lý do/bước** bằng chữ, hoặc `S09` chụp nháp sau khi đồng ý → `S10 correct` thì chuông dừng → `Hôm nay` cho biết môn/việc kế tiếp. Ở chế độ thử thách, âm không tự tắt khi chỉ mở câu; người dùng vẫn có Dừng khẩn cấp. Không tự mở đấu trường hoặc màn thưởng lúc mới dậy.

### Sai bài

`S10 incorrect` lần 1–2 trong chế độ thử thách chỉ báo `Bài này chưa đúng. Bạn có thể thử lại`, **chưa nêu bước sai/gợi ý/đáp án**. Lần sai rõ thứ ba mới nêu một bước cần xem và một gợi ý phương pháp; lần 4–5 có thể đổi câu tương đương dễ hơn theo rubric. Dừng khẩn cấp luôn có; sau khi kết thúc mới xem lời giải đầy đủ và lỗi đã ghi.

### Ảnh khó đọc/API chậm

`S10 uncertain` → `Chụp lại`, `Nhập chữ`, `Hoàn thành không chấm` hoặc Dừng khẩn cấp. AI timeout sau giới hạn cấu hình → `Chưa thể chấm lúc này`; không tăng bộ đếm sai, không tự tăng XP như bài đúng. Ảnh không rõ không bị gọi là gian lận.

### Hoãn/tắt khẩn cấp

`Dừng khẩn cấp` hiện ở `S07–S10` hoặc có đường mở trong tối đa một thao tác; **một lần chạm dừng âm/rung ngay** trên thiết bị. Nếu cần xác nhận để tránh chạm nhầm, chỉ hỏi **sau khi âm đã dừng** và không phát lại chuông nếu người dùng bỏ qua. Lý do là tùy chọn. Hoãn 5 phút chỉ ở chế độ thường; chế độ thử thách không có Hoãn. Người dùng có thể giảm âm khi đang đọc nhưng không bị ép để âm quá lớn.

## 4. Bộ nhãn tiếng Việt chuẩn

| Vị trí | Nội dung |
| --- | --- |
| S01 tiêu đề | “Dậy đúng giờ. Nghĩ bằng chính mình.” |
| S01 mô tả | “Một câu ôn ngắn theo lịch học, mỗi buổi sáng.” |
| S04 báo thức kế tiếp | “Chuông tiếp theo: 06:30, Thứ Hai” |
| S07 nút chính | `Mở câu hỏi` |
| S07 nút phụ | `Dừng khẩn cấp`; mode thường thêm `Hoãn 5 phút` |
| S08 nút | `Chọn/nhập đáp án` · `Viết cách làm` · `Chụp nháp` |
| S09 riêng tư | “Ảnh này sẽ được gửi để AI đọc và phản hồi. MindClock không lưu ảnh mặc định.” |
| S09 nút | “Chụp lại” · “Gửi bài” |
| S10 đúng | “Bạn làm đúng rồi!” · “Bạn đã biến đổi đúng ở bước …” |
| S10 sai | Lần 1–2 mode thử thách: “Bài này chưa đúng. Bạn có thể thử lại.”; từ lần 3: “Hãy xem lại bước này…” |
| S10 chưa rõ | “Mình chưa đọc rõ bài làm” · “Bạn có thể chụp lại dưới ánh sáng tốt hơn.” |
| S10 chậm | “Chưa thể chấm lúc này. Bạn vẫn có thể kết thúc báo thức.” |
| S10 sau sai | `Thử lại`; từ lần sai rõ thứ ba có `Xem gợi ý`; `Xem lời giải` sau khi kết thúc |
| S11 XP | “+10 điểm kinh nghiệm” · “Bạn đã hoàn thành 4 buổi sáng tuần này.” |
| S12 báo lỗi | “Báo kết quả chấm chưa đúng” |

## 5. Empty, loading và lỗi

| Trạng thái | Hiển thị | Hành động |
| --- | --- | --- |
| Chưa có môn hôm nay | “Hôm nay chưa có môn trong lịch.” | “Chọn câu ôn” / “Chỉ dùng báo thức” |
| Chưa có câu tải sẵn | “Chuông vẫn hoạt động. Câu ôn sẽ có khi kết nối lại.” | “Tắt chuông” |
| Đang chấm | “Đang đọc từng bước bài làm…”; không hiển thị phần trăm giả | “Hủy chấm và kết thúc” |
| Ảnh quá lớn/không hỗ trợ | “Ảnh chưa gửi được. Hãy chụp lại hoặc chọn ảnh nhỏ hơn.” | “Chụp lại” |
| Mất mạng | `Không có mạng. Chuông vẫn hoạt động; bài này chưa được chấm.` | `Hoàn thành không chấm` / `Dừng khẩn cấp` |
| Không có quyền camera | `Bạn có thể viết cách làm bằng chữ.` | `Nhập chữ` / `Mở cài đặt` |
| Không có quyền báo thức chính xác | “Thiết bị chưa cho phép báo thức đúng giờ.” | “Mở cài đặt quyền” |
| Token hết hạn | “Cần đăng nhập lại để đồng bộ tiến độ.” | “Đăng nhập” / “Dùng báo thức” |

## 6. Khả năng tiếp cận

Vùng chạm mục tiêu ít nhất 48×48 dp theo [hệ UI](27-quy-chuan-giao-dien-va-figma.md); có nhãn TalkBack, không diễn đạt đúng/sai chỉ bằng màu; chữ 200% không che Dừng khẩn cấp; rung/âm có tùy chọn. Với người không thể viết tay hoặc dùng camera, có đường nhập **đáp án và lý do bằng chữ**; cách nhập không làm giảm XP/RP. Người dùng có thể tắt animation và lời thoại vui.

## 7. Nội dung phục vụ việc học sau chuông

Trang `Hôm nay` có ba khối theo thứ tự: `Chuông tiếp theo`, `Môn/việc hôm nay`, `Một điều cần ôn lại`. Chỉ hiển thị việc AI đề xuất sau khi người học xác nhận; nhắc học tối đa hai lần/ngày mặc định và theo giờ yên tĩnh. Câu sai/chưa rõ có thể tạo **một** gợi ý ôn cùng kỹ năng, không tạo hàng loạt task. Ngày nghỉ hoặc lịch trống không ép câu sáng. Thành tích XP là thông tin phụ, không chiếm màn đầu.

## 8. Màn hình tương lai cần thiết kế riêng

Linh thú chỉ phản ánh hoạt động tích cực, không bị “ốm” vì ngủ thêm. Đấu trường cần quy tắc công bằng, chống quấy rối và bảo vệ người chưa thành niên. Dashboard giáo viên chỉ ưu tiên **xu hướng tổng hợp**, quyền xem cá nhân phải được cấp riêng. Phụ huynh không mặc định xem ảnh bài làm, lịch ngủ hay mọi lần tắt báo thức.

