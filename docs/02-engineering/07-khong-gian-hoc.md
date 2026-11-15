# Không gian học và trợ lý MindClock

**Mục tiêu:** một phiên tự học có việc cụ thể, timer local, chọn học một mình/cùng AI/cùng bạn. Không biến app thành công cụ giám sát học sinh; không hứa khóa ứng dụng khác. [Hành vi phòng học](../01-product/08-phong-hoc-ai-va-ban-be.md), [realtime kỹ thuật](09-phong-hoc-realtime.md), [AI](06-ai-va-cham-bai.md), [privacy](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 1. Luồng và máy trạng thái

`setup(roomType, task, subject, targetMinutes, cadence, coachTone) → running ↔ paused → break | finished | abandoned`. `roomType=solo|ai|friends`, `cadence=deep|interval`, `coachTone=quiet|gentle|firm`. Preset 10/25/45 phút hoặc tùy chỉnh; người dùng chọn việc từ TKB/task hôm nay hoặc nhập tay. Timer và nút `Kết thúc` chạy local khi offline/API lỗi. Khi app background/restart, tính elapsed theo đồng hồ phù hợp, đối chiếu monotonic/wall clock, hiển thị nếu dữ liệu không chắc; không cộng phạt vì rời app. Đồng bộ server là bước sau, idempotent theo `clientSessionId`.

## 2. UI

Một màn dọc: ô mình/AI hoặc bạn, việc đang làm, môn, timer lớn, `Mic/Cam/Hỏi/Tạm dừng/Nghỉ/Rời phòng`, ghi `Đã làm`/`Đang vướng`. Camera/mic tắt mặc định và chỉ bật sau thao tác riêng; trạng thái đang thu, giới hạn, tắt ngay phải nhìn thấy. Avatar AI là 2D có nhãn, chuyển động theo trạng thái/audio thật; không giả người thật hay giả đang giám sát. Nếu người dùng rời app, khi quay lại dùng câu trung tính `Bạn muốn tiếp tục phiên học?`, không mắng, không trừ XP/streak. Có giảm chuyển động và chữ 200%.

## 3. Trợ lý

Gửi task/subject/grade + câu hỏi người dùng và vài lượt gần nhất, không gửi video/frame liên tục. AI hỏi lại một bước, nhắc công thức hoặc gợi ý vừa đủ; không đưa đáp án cuối trước nỗ lực. Backend kiểm consent/rate/timeout, có fallback text `Hiện chưa kết nối được. Ghi lại chỗ bạn đang vướng.` Không tự tạo lịch/notification/báo thức; chỉ đề xuất để người dùng xác nhận. `firm` chỉ là nhắc ngắn, không chửi, bêu xấu hay giả giận dỗi để thao túng. Voice push-to-talk trước; Live realtime là task riêng khi có chi phí/quyền/máy thật, token ephemeral, không lộ API key.

## 4. Test và cổng

FOCUS-01 timer offline/pause/resume/finish; FOCUS-02 background/kill/restart/đổi giờ; FOCUS-03 đồng bộ finish lặp; FOCUS-04 API timeout không kẹt màn; FOCUS-05 camera/mic từ chối/và dừng; FOCUS-06 AI không lộ đáp án/chủ động bật camera; FOCUS-07 TalkBack/chữ lớn/màn hẹp; FOCUS-08 không thu app list/mặt/video mặc định. ROOM-01–06 bao phủ lựa chọn phòng, Live lỗi/quota, lời nhắc và bạn bè. Đo thời gian mở màn, điện/pin, quota token. Phòng bạn/Live chỉ mở sau cổng kỹ thuật và quyền, không làm điều kiện cho timer local.
