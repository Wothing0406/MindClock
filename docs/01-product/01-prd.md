# PRD — MindClock Android

**Phiên bản:** 1.2 tài liệu, ngày 15/11/2026. **Owner:** nhóm sản phẩm; thay đổi hành vi cần cập nhật tài liệu này, [journey](02-hanh-trinh-ux.md), contract và test trong cùng task. **Trạng thái:** mục tiêu triển khai sản phẩm lâu dài, không xác nhận đã phát hành. [Hiện trạng mã](../00-start/01-hien-trang.md).

## 1. Vấn đề và giá trị cần kiểm chứng

Học sinh THPT có thể tắt báo thức rồi ngủ tiếp, ôn không sát môn học và thấy “đã hiểu” khi đọc lời giải AI mà chưa tự làm. MindClock nối **lịch học cá nhân → lịch ngủ/báo thức → một câu truy hồi có trình bày → kế hoạch ngày → phòng tự học**. Người học có thể học một mình, cùng AI hoặc mời bạn; PvP là hoạt động tự nguyện sau khi luồng học đủ tin cậy. Chuông phải luôn dừng được; sai bài không bị phạt hay khóa điện thoại.

**Giả thuyết cần kiểm chứng:** người dùng có thể đặt chuông/lịch mà hiểu cách hoạt động, tự làm một câu ngắn sau khi thức, và quay lại phòng học vì cảm thấy được đồng hành. Chưa có bằng chứng cải thiện giấc ngủ hoặc kết quả học; thử người dùng nhiều vòng phải đo cả mức khó chịu và cho phép bỏ tính năng gây hại. Đây là sản phẩm độc lập, không còn scope cuộc thi/hackathon.

## 2. Đối tượng và việc cần làm

| Persona | Việc cần làm | Ràng buộc |
| --- | --- | --- |
| Học sinh THPT 10–12 | Chọn môn theo chương trình, lên lịch, dậy và ôn đúng môn, có bạn học | Có môn lựa chọn khác nhau, tuổi/consent khác nhau, mạng/thiết bị không ổn định. |
| Học sinh THCS, sinh viên | Nhu cầu tương tự nhưng catalog/chương trình khác | Giai đoạn sau; không hiển thị như đã có câu mọi lớp/môn. |
| Giáo viên/phụ huynh | Xem tiến độ khi được cấp quyền | Giai đoạn sau; không mặc định xem giờ dậy/ảnh/bài cá nhân. |

## 3. Phạm vi theo release

| Mức | Có | Chưa có/điều kiện |
| --- | --- | --- |
| **P0 — lõi Android** | Happy path đăng ký email, hồ sơ lớp/môn/avatar, dashboard có kế hoạch cơ bản; nhiều alarm local, lịch ngủ, Dừng khẩn cấp, câu duyệt và nhập chữ, timer học một mình. Nếu Auth/mạng lỗi vẫn có `Chỉ dùng báo thức trên máy`. | Không cần Gemini Live, phòng bạn, PvP hoặc iOS để người dùng kiểm báo thức; đăng ký online chỉ mở khi Auth/privacy/backend đạt. |
| **P1 — cá nhân hóa online** | Đồng bộ TKB, gợi kế hoạch có xác nhận, camera bài làm tùy chọn, chấm ba trạng thái được đánh giá, hồ sơ tiến độ, AI gợi ý theo lượt, voice push-to-talk. | PostgreSQL/Firebase/consent, quyền nội dung và bộ chấm đạt. |
| **P2 — đồng hành và xã hội** | Phòng học với AI Live/avatar nói, phòng mời bạn, hồ sơ công khai opt-in, giao hữu PvP. | Chi phí Live, privacy trẻ em, moderation, realtime/reconnect, câu chấm công bằng và hai máy. Ranked/coin sau playtest riêng. |

## 4. Yêu cầu nghiệp vụ có thể test

| ID | Người dùng làm gì | Hành vi bắt buộc | Test nguồn |
| --- | --- | --- | --- |
| P-01 | Mở app lần đầu | Giải thích quyền; đường chính đăng ký/đăng nhập email; chọn lớp 10–12/môn/trình độ/avatar, xác nhận kế hoạch rồi vào dashboard; nếu Auth không dùng được vẫn đặt alarm local | UX-01, AUTH-01, ON-01–06 |
| P-02 | Thêm/sửa/xóa giờ báo | Lưu local, xác minh OS schedule, hiện lần reo tiếp theo/quyền thật; đề xuất AI chỉ có hiệu lực sau xác nhận | AL-01–04 |
| P-03 | Chuông thử thách reo | Âm/rung và Dừng khẩn cấp chạy cục bộ; không Hoãn; `Mở câu` dừng âm rồi vào cảnh mở màn/câu đã duyệt, không hỏi có muốn bắt đầu; asset có nguồn và fallback chữ | AL-05–09, MORNING-01, MEDIA-01–03 |
| P-04 | Chuông thường reo | Có thể Hoãn theo cấu hình cục bộ và Dừng; không phụ thuộc login/API | AL-10 |
| P-05 | Người học chưa có câu/mất mạng | Vẫn dừng chuông, chọn `Ôn sau`/hoàn thành không chấm; không tự tạo điểm | LEARN-01 |
| P-06 | Nộp đáp án và bước giải | Có đường nhập chữ; ảnh chỉ sau quyền/chụp/xem lại/xác nhận; backend chấm `correct/incorrect/uncertain` | LEARN-02–05, AI-01 |
| P-07 | Sai bài | Cho thử lại; gợi ý chỉ từ lần sai rõ thứ 3; từ lần sai rõ thứ 5 có `Bỏ lượt`; Socratic không đưa đáp án cuối trước nỗ lực | LEARN-06, AI-02, MORNING-02 |
| P-08 | Xem tiến độ | Chỉ dữ liệu cá nhân; hoàn thành câu đúng đã xác minh mới xét XP/chuỗi học buổi sáng; bỏ lượt không cộng, không trừ EXP/RP đã có; giờ dậy không vào rating | DATA-01, MORNING-03 |
| P-09 | Vào Không gian học | Chọn `Học một mình` hoặc `Học cùng MindClock`; app gợi mục tiêu từ lịch đã xác nhận, không bắt chọn môn lại; recap trước bắt đầu; timer local có dừng/nghỉ/kết thúc; `Học sâu` im lặng; rời app không bị phạt/khóa | FOCUS-01–05, FOCUS-09 |
| P-10 | Xóa tài khoản/rút đồng ý | API/UX có trạng thái xử lý rõ, ẩn khỏi bảng ngay, dọn dữ liệu theo chính sách; chuông local tách biệt | AUTH-04, PRIV-01 |
| P-11 | Lập lịch học và việc hôm nay | Nhập/sửa TKB nhiều môn, nhắc opt-in, gợi giờ/câu/việc có lý do và chỉ áp dụng sau xác nhận | PLAN-01–05 |
| P-12 | Xem hồ sơ và chia sẻ | Lịch sử/tiến độ có nguồn rõ; avatar/tên được duyệt; profile công khai mặc định ẩn, không lộ giờ dậy/TKB/bài | PROFILE-01–04 |
| P-13 | Đặt lịch ngủ và nhiều chuông | Vòng 24 giờ/nhập số tương đương, âm tùy chọn, lời nhắc thời lượng ngủ; DND chỉ khi OS/quyền cho phép, fallback rõ | SLEEP-01–05 |
| P-14 | Học cùng AI hoặc bạn | Hai lựa chọn chính một mình/cùng AI; AI chỉ tham gia trong chế độ đã chọn, không có trong phiên một mình; bạn bè là feature flag sau; mic/cam/âm tắt mặc định, nhịp sâu không phát âm; rời được | ROOM-01–08 |
| P-16 | Thưởng phiên tập trung | Sau khi hoàn thành phiên, server cấp EXP theo phút running trọn vẹn có trần phiên/ngày và idempotency; offline chỉ hiện dự kiến; pause/nghỉ/hủy không tính, không đổi RP | FOCUS-10, DATA-01 |
| P-15 | Thi đấu | Giao hữu dùng cùng câu/rubric, người chơi nộp đáp án và lý do; server chốt kết quả, sai/uncertain không xử thua do AI lỗi; ranked là cổng sau | GAME-01–05 |

## 5. Quy tắc bất biến

- **An toàn báo thức:** Dừng khẩn cấp một chạm dừng âm/rung ngay trong mọi trạng thái, kể cả offline, chấm đang chờ hoặc token hết hạn. Không hứa tự mở khóa màn hình, khóa app khác, chặn gỡ app hoặc chống gian lận tuyệt đối.
- **Công bằng học tập:** sai và `uncertain` không bị trừ uy tín/rank. AI không tự quyết XP, streak, rating, gian lận; câu MVP từ ngân hàng đã duyệt, có rubric/revision. Có thể phản hồi chấm sai.
- **Lượt sáng:** câu ôn là điều kiện hoàn thành thử thách và nhận EXP/chuỗi, không phải điều kiện dừng âm hay quyền rời app. Mở màn ngắn tùy bỏ qua, câu không được bỏ qua để lấy điểm. Sau 5 lần `incorrect` rõ có `Bỏ lượt`; `uncertain`, mất mạng, lỗi câu hoặc AI không bị tính là sai và không làm mất lượt vì lỗi hệ thống. [Luồng sáng](09-giac-ngu-va-bao-thuc.md).
- **Tự nguyện:** thi đấu, camera, mic, AI Live, chia sẻ hồ sơ và nhắc lịch đều tách consent. Không dùng giờ dậy làm bảng hạng. Không bán lợi thế chiến đấu.
- **Dữ liệu:** ảnh bài làm không lưu mặc định; không log ảnh/token/nội dung cá nhân; tài khoản server theo chính sách tuổi và quyền. [Chính sách](04-tai-khoan-quyen-rieng-tu.md).
- **Ngôn ngữ:** `vi-VN`, ngắn gọn, đúng chức năng, không emoji hệ thống/phóng đại hay mắng người dùng. [Design](03-he-thiet-ke.md).
- **Quyền và OS:** giải thích quyền lúc mở app nhưng xin đúng lúc cần; không hứa tự bật DND, tự mở khóa hoặc giám sát app khác trên mọi thiết bị.
- **AI đồng hành:** avatar luôn gắn nhãn AI; không suy cảm xúc/lười học từ hình ảnh, không chửi hoặc phạt vì rời phòng, Live có giới hạn chi phí và phương án text/timer.

## 6. Chỉ số và ngưỡng quyết định

Trong thử người dùng ghi: hoàn tất onboarding, quyền bị từ chối, số alarm đặt/thực reo và dừng an toàn, số buổi làm câu, `uncertain`/kháng nghị, thời gian tới việc đầu, sử dụng phòng một mình/AI/bạn, mức khó chịu bởi lời nhắc, crash/ANR, độ trễ/chi phí AI, tỷ lệ rút consent/xóa/bỏ dùng. **Ngưỡng mở từng tính năng phải chốt trước thu thập**; không tự đặt “thành công” sau khi xem số liệu. Báo thức bỏ lỡ hoặc không thể dừng là lỗi chặn release. [Test/release](../03-quality/01-ke-hoach-kiem-thu.md).

## 7. Ngoài phạm vi hiện tại và câu hỏi mở

Giáo viên/phụ huynh, pet, ranked/cửa hàng, AI giám sát camera liên tục, iOS không thuộc P0. Cần quyết định trước mở người dùng thật: tuổi/đồng ý, catalog chương trình và số câu tối thiểu theo môn, quyền nội dung/art, ngưỡng chấm AI, ngân sách Live, thiết bị Android mục tiêu và hình thức phân phối. Không giải quyết bằng một màn mock.

[Onboarding](07-dang-ky-va-khoi-tao-lo-trinh.md), [lịch và kế hoạch](05-lich-hoc-nhac-viec.md), [hồ sơ](06-ho-so-tien-do-xa-hoi.md), [giấc ngủ/báo thức](09-giac-ngu-va-bao-thuc.md), [phòng học](08-phong-hoc-ai-va-ban-be.md) là đặc tả chi tiết. [Quyết định còn mở](../00-start/06-quyet-dinh-va-gia-dinh.md).
