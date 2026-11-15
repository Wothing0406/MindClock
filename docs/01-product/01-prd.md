# PRD — MindClock Android

**Phiên bản:** 1.0 tài liệu, ngày 15/11/2026. **Owner:** nhóm sản phẩm; thay đổi hành vi cần cập nhật tài liệu này, [journey](02-hanh-trinh-ux.md), contract và test trong cùng task. **Trạng thái:** mục tiêu triển khai, không xác nhận đã phát hành. [Hiện trạng mã](../00-start/01-hien-trang.md).

## 1. Vấn đề và giá trị cần kiểm chứng

Học sinh THCS/THPT và sinh viên năm đầu có thể tắt báo thức rồi ngủ tiếp, ôn tập buổi sáng không sát lịch, và thấy “đã hiểu” khi đọc lời giải AI mà chưa tự làm. MindClock đặt một câu truy hồi ngắn **sau khi chuông reo**, gắn với môn đã chọn/lịch học, yêu cầu đáp án cùng bước trình bày. Ứng dụng phải giúp bắt đầu học mà vẫn an toàn: người dùng luôn dừng được chuông, sai bài không bị phạt, không khóa điện thoại.

**Giả thuyết:** 7 ngày dùng thử có thể cải thiện tỷ lệ dậy đúng giờ tự báo và mức nhớ bài/cảm nhận hữu ích. Chưa có bằng chứng hiệu quả giáo dục; [pilot](../03-quality/02-van-hanh-phat-hanh.md) phải đo và cho phép bác bỏ ý tưởng.

## 2. Đối tượng và việc cần làm

| Persona | Việc cần làm | Ràng buộc |
| --- | --- | --- |
| Học sinh 9/12 | Dậy đúng giờ, biết môn hôm nay, ôn 1 câu vừa sức, xem chỗ sai | Thời gian ít, mạng/thiết bị không ổn định, có thể chưa đủ tuổi tạo tài khoản online. |
| Học sinh THCS/THPT khác | Hình thành thói quen và chọn môn/tổ hợp riêng | Không ép thi hay học mọi môn; camera không bắt buộc. |
| Sinh viên năm đầu | Nhập lịch học riêng, phiên tự học ngắn | Lịch khác trường phổ thông, môn tùy biến nhưng ngân hàng câu cần duyệt. |
| Giáo viên/phụ huynh | Xem tiến độ khi được cấp quyền | Giai đoạn sau; không mặc định xem giờ dậy/ảnh/bài cá nhân. |

## 3. Phạm vi theo release

| Mức | Có | Chưa có/điều kiện |
| --- | --- | --- |
| **MVP Android P0** | Khách local, onboarding có thể bỏ qua, lịch/môn, báo thức thường/thử thách, Dừng khẩn cấp offline, câu đã duyệt, nhập chữ, hoàn thành không chấm offline, timer học local | Camera/AI online tùy chọn sau khi đánh giá; không cần PvP, rank, pet, giáo viên, phụ huynh hoặc iOS để phát hành nội bộ. |
| **Online cá nhân** | Email Auth, đồng bộ TKB/phiên, chấm 3 trạng thái, XP server, tiến độ, xóa tài khoản | PostgreSQL/Firebase/test quyền/idempotency và consent đạt. |
| **Mở rộng** | AI gợi mở, camera, đa môn sâu hơn, không gian học, giao hữu 1v1 | Qua cổng content, quyền, chất lượng chấm và hai máy. Ranked/cửa hàng tiếp sau giao hữu. |

## 4. Yêu cầu nghiệp vụ có thể test

| ID | Người dùng làm gì | Hành vi bắt buộc | Test nguồn |
| --- | --- | --- | --- |
| P-01 | Mở app lần đầu | Chọn dùng khách hoặc đăng nhập; có thể bỏ qua khối/môn để chỉ báo thức | UX-01, AUTH-01 |
| P-02 | Thêm/sửa/xóa giờ báo | Lưu local, xác minh OS schedule, hiện lần reo tiếp theo/quyền thật; đề xuất AI chỉ có hiệu lực sau xác nhận | AL-01–04 |
| P-03 | Chuông thử thách reo | Âm/rung và Dừng khẩn cấp chạy cục bộ; không Hoãn; câu cache đã duyệt nếu có | AL-05–09 |
| P-04 | Chuông thường reo | Có thể Hoãn theo cấu hình cục bộ và Dừng; không phụ thuộc login/API | AL-10 |
| P-05 | Người học chưa có câu/mất mạng | Vẫn dừng chuông, chọn `Ôn sau`/hoàn thành không chấm; không tự tạo điểm | LEARN-01 |
| P-06 | Nộp đáp án và bước giải | Có đường nhập chữ; ảnh chỉ sau quyền/chụp/xem lại/xác nhận; backend chấm `correct/incorrect/uncertain` | LEARN-02–05, AI-01 |
| P-07 | Sai bài | Cho thử lại; gợi ý chỉ từ lần sai rõ thứ 3 ở thử thách, Socratic không đưa đáp án cuối trước nỗ lực | LEARN-06, AI-02 |
| P-08 | Xem tiến độ | Chỉ dữ liệu cá nhân; XP/chuỗi chỉ server chốt từ attempt đủ điều kiện; giờ dậy không vào rating | DATA-01 |
| P-09 | Vào Không gian học | Timer local có dừng/nghỉ/kết thúc; rời app không bị phạt/khóa | FOCUS-01–05 |
| P-10 | Xóa tài khoản/rút đồng ý | API/UX có trạng thái xử lý rõ, ẩn khỏi bảng ngay, dọn dữ liệu theo chính sách; chuông local tách biệt | AUTH-04, PRIV-01 |
| P-11 | Lập lịch học và việc hôm nay | Nhập/sửa TKB nhiều môn, nhắc opt-in, gợi giờ/câu/việc có lý do và chỉ áp dụng sau xác nhận | PLAN-01–05 |
| P-12 | Xem hồ sơ và chia sẻ | Lịch sử/tiến độ có nguồn rõ; avatar/tên được duyệt; profile công khai mặc định ẩn, không lộ giờ dậy/TKB/bài | PROFILE-01–04 |

## 5. Quy tắc bất biến

- **An toàn báo thức:** Dừng khẩn cấp một chạm dừng âm/rung ngay trong mọi trạng thái, kể cả offline, chấm đang chờ hoặc token hết hạn. Không hứa tự mở khóa màn hình, khóa app khác, chặn gỡ app hoặc chống gian lận tuyệt đối.
- **Công bằng học tập:** sai và `uncertain` không bị trừ uy tín/rank. AI không tự quyết XP, streak, rating, gian lận; câu MVP từ ngân hàng đã duyệt, có rubric/revision. Có thể phản hồi chấm sai.
- **Tự nguyện:** thi đấu, camera, mic, AI Live, chia sẻ hồ sơ và nhắc lịch đều tách consent. Không dùng giờ dậy làm bảng hạng. Không bán lợi thế chiến đấu.
- **Dữ liệu:** ảnh bài làm không lưu mặc định; không log ảnh/token/nội dung cá nhân; tài khoản server theo chính sách tuổi và quyền. [Chính sách](04-tai-khoan-quyen-rieng-tu.md).
- **Ngôn ngữ:** `vi-VN`, ngắn gọn, đúng chức năng, không emoji hệ thống/phóng đại hay mắng người dùng. [Design](03-he-thiet-ke.md).

## 6. Chỉ số và ngưỡng quyết định

Trong pilot ghi: chuông dự kiến/chuông thực, tỷ lệ dừng an toàn, số buổi làm câu, thời gian tới câu đầu, `uncertain`, phản hồi chấm sai, crash/ANR, thời gian chấm, chi phí AI/người, tỷ lệ xóa hoặc bỏ dùng, tự báo chất lượng ngủ/cảm nhận hữu ích. **Ngưỡng mở pilot phải được chủ dự án chốt trước thu thập**; không tự đặt “thành công” sau khi xem số liệu. Báo thức bỏ lỡ hoặc không thể dừng là lỗi chặn release. [Test/release](../03-quality/01-ke-hoach-kiem-thu.md).

## 7. Ngoài phạm vi hiện tại và câu hỏi mở

Giáo viên/phụ huynh, pet, ranked/cửa hàng, AI giám sát camera liên tục, iOS không thuộc P0. Cần quyết định trước pilot: tuổi/đồng ý, chương trình học và số câu tối thiểu, quyền nội dung/art, ngưỡng chấm AI, ngân sách, thiết bị Android mục tiêu và hình thức phân phối. Không giải quyết các quyết định này bằng một màn mock.

[Lịch học và nhắc việc](05-lich-hoc-nhac-viec.md), [hồ sơ và xã hội](06-ho-so-tien-do-xa-hoi.md) là đặc tả chi tiết cho P-11/P-12; phần online/xã hội chỉ mở theo release và consent tương ứng. [Quyết định còn mở](../00-start/06-quyet-dinh-va-gia-dinh.md).
