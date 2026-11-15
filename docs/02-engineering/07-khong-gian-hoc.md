# Không gian học và trợ lý MindClock

**Mục tiêu:** một phiên tự học ngắn có việc cụ thể, timer local và gợi ý Socratic theo yêu cầu. Không biến app thành công cụ giám sát học sinh; không hứa khóa ứng dụng khác. [PRD](../01-product/01-prd.md), [AI](06-ai-va-cham-bai.md), [privacy](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 1. Luồng và máy trạng thái

`setup(task, subject, targetMinutes, focusLevel) → running ↔ paused → break | finished | abandoned`. Preset 10/25/45 phút hoặc tùy chỉnh; người dùng chọn việc từ TKB/task hôm nay hoặc nhập tay. Timer và nút `Kết thúc` chạy local khi offline/API lỗi. Khi app background/restart, tính elapsed theo đồng hồ phù hợp, đối chiếu monotonic/wall clock, hiển thị nếu dữ liệu không chắc; không cộng phạt vì rời app. Đồng bộ server là bước sau, idempotent theo `clientSessionId`.

## 2. UI

Một màn dọc: việc đang làm, môn, timer lớn, `Tạm dừng/Nghỉ/Kết thúc`, ghi `Đã làm`/`Đang vướng`, nút `Hỏi MindClock`. Camera/mic chỉ bật sau thao tác riêng; trạng thái đang thu, giới hạn, tắt ngay phải nhìn thấy. Không giả một ô video AI như người thật nếu không có session thực. Nếu người dùng rời app, khi quay lại dùng câu trung tính `Bạn muốn tiếp tục phiên học?`, không mắng, không trừ XP/streak. Có giảm chuyển động và chữ 200%.

## 3. Trợ lý

Gửi task/subject/grade + câu hỏi người dùng và vài lượt gần nhất, không gửi video/frame liên tục. AI hỏi lại một bước, nhắc công thức hoặc gợi ý vừa đủ; không đưa đáp án cuối trước nỗ lực. Backend kiểm consent/rate/timeout, có fallback text `Hiện chưa kết nối được. Ghi lại chỗ bạn đang vướng.` Không tự tạo lịch/notification/báo thức; chỉ đề xuất để người dùng xác nhận. Voice realtime chỉ task riêng khi có chi phí/quyền/máy thật; token Live ephemeral, không lộ API key.

## 4. Test và cổng

FOCUS-01 timer offline/pause/resume/finish; FOCUS-02 background/kill/restart/đổi giờ; FOCUS-03 đồng bộ finish lặp; FOCUS-04 API timeout không kẹt màn; FOCUS-05 camera/mic từ chối/và dừng; FOCUS-06 AI không lộ đáp án/chủ động bật camera; FOCUS-07 TalkBack/chữ lớn/màn hẹp; FOCUS-08 không thu app list/mặt/video mặc định. Đo thời gian mở màn, điện/pin, quota token. Không gian học P1 chỉ mở pilot sau báo thức P0 an toàn.
