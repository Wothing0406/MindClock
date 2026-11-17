# Không gian học và trợ lý MindClock

**Mục tiêu:** một phiên tự học có việc cụ thể, timer local, chọn học một mình/cùng AI/cùng bạn. Không biến app thành công cụ giám sát học sinh; không hứa khóa ứng dụng khác. [Hành vi phòng học](../01-product/08-phong-hoc-ai-va-ban-be.md), [realtime kỹ thuật](09-phong-hoc-realtime.md), [AI](06-ai-va-cham-bai.md), [privacy](../01-product/04-tai-khoan-quyen-rieng-tu.md).

## 1. Luồng và máy trạng thái

`setup(roomType, suggestedTask?, task, subjectContext?, targetMinutes, cadence, audioOptions) → recap → running ↔ paused → break | finished | abandoned`. Hai `roomType` chính là `solo|ai`; `friends` chỉ qua feature flag/task riêng. `subjectContext` được suy ra từ kế hoạch/TKB đã xác nhận nếu có, **không là trường bắt buộc để bắt đầu**. Preset 15/25/45 phút hoặc tùy chỉnh. Timer và nút `Kết thúc` chạy local khi offline/API lỗi. `cadence=deep` đặt mọi `audioOptions` trong phiên về off và không tự gọi AI; `solo` không khởi tạo phiên AI. Khi app background/restart, tính elapsed theo đồng hồ phù hợp, đối chiếu monotonic/wall clock, hiển thị nếu dữ liệu không chắc; không cộng phạt vì rời app. Đồng bộ server idempotent theo `clientSessionId`.

EXP `study-time-v0.1` được tính **ở server** từ phút `running` hợp lệ đã hoàn thành: `min(floor(activeSeconds/300), 12)` mỗi phiên, tổng tối đa 30/ngày người dùng theo timezone đã lưu. Pause/break không tính; phiên chưa `finished`, dưới 300 giây hoặc thời gian không chắc không cấp. Client chỉ giữ dự kiến khi offline. Backend phải kiểm replay, timestamp bất thường và trần ngày; `study_session_id`/`clientSessionId` unique theo owner, một ledger entry cho một phiên, finish cùng key trả cùng kết quả. Không chuyển EXP thời gian thành RP hoặc điểm năng lực. Chi tiết hành vi ở [phòng học](../01-product/08-phong-hoc-ai-va-ban-be.md).

## 2. UI

Màn chọn có hai thẻ `Học một mình`/`Học cùng MindClock`, tiếp theo là gợi ý cá nhân, sửa mục tiêu/thời lượng, nhịp và thẻ recap. `solo` dùng timer, mục tiêu, ghi chú và nút dừng; không dựng avatar/chat AI. `ai` thêm nút hỏi và tùy chọn media. Camera/mic/âm tắt mặc định; `deep` luôn silent trong phiên, AI trả chữ khi hỏi. Avatar AI là 2D có nhãn và chỉ chuyển động theo audio thật ở nhịp đã bật âm; không giả người thật hay giám sát. Khi người dùng quay lại app, hiện câu tiếp tục trung tính; không mắng hoặc trừ EXP/streak. Có giảm chuyển động và chữ 200%.

## 3. Trợ lý

Gửi task/subject/grade + câu hỏi người dùng và vài lượt gần nhất, không gửi video/frame liên tục. AI hỏi lại một bước, nhắc công thức hoặc gợi ý vừa đủ; không đưa đáp án cuối trước nỗ lực. Backend kiểm consent/rate/timeout, có fallback text `Hiện chưa kết nối được. Ghi lại chỗ bạn đang vướng.` Không tự tạo lịch/notification/báo thức; chỉ đề xuất để người dùng xác nhận. `firm` chỉ là nhắc ngắn, không chửi, bêu xấu hay giả giận dỗi để thao túng. Voice push-to-talk trước; Live realtime là task riêng khi có chi phí/quyền/máy thật, token ephemeral, không lộ API key.

## 4. Test và cổng

FOCUS-01 timer offline/pause/resume/finish; FOCUS-02 background/kill/restart/đổi giờ; FOCUS-03 đồng bộ finish lặp; FOCUS-04 API timeout không kẹt màn; FOCUS-05 camera/mic từ chối/và dừng; FOCUS-06 AI không lộ đáp án/chủ động bật camera; FOCUS-07 TalkBack/chữ lớn/màn hẹp; FOCUS-08 không thu app list/mặt/video mặc định; FOCUS-09 silent ở `deep`/không AI ở `solo`; FOCUS-10 tính EXP đúng phút active, cap, owner, offline và retry. ROOM-01–08 bao phủ lựa chọn phòng, Live lỗi/quota, lời nhắc và bạn bè. Đo thời gian mở màn, điện/pin, quota token. Phòng bạn/Live chỉ mở sau cổng kỹ thuật và quyền, không làm điều kiện cho timer local.
