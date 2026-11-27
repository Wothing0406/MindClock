# Đặc tả nhiệm vụ T093

## Vấn đề và kết quả mong muốn

Người dùng phản ánh các lỗi UX nghiêm trọng trong Không gian học:
1. Khi tạo/vào phòng học với bạn (`_activeMeetRoom != null`), bên dưới vẫn tiếp tục hiện toàn bộ khối thiết lập `"Học một mình"` / `"Chọn việc học cụ thể"` / `"Thời lượng"`.
2. Luồng vào chưa tách thành 3 lựa chọn ngang hàng (`Học một mình`, `Học cùng MindClock AI`, `Học cùng bạn`) và chưa có lựa chọn tường minh `Bắt đầu ngay` hoặc `Hẹn giờ`.
3. Khối `"Câu hỏi cá nhân hóa theo môn & lớp"` bị lặp ở cả màn chuẩn bị lẫn trong phiên học đang chạy, kèm chữ kỹ thuật `(0 XP, không thay ngân hàng báo thức đã duyệt)`; đồng thời khi tạo phòng nhóm chưa ưu tiên lọc theo các môn học sinh đã chọn trong `StudyProfile`.
4. Phiên `Học một mình` đang chạy thiếu ô ghi chú nhanh chỗ vướng và bị thừa các thẻ phụ; phiên `Học cùng AI` thiếu lựa chọn gửi ảnh bài tập kèm hộp thoại xác nhận consent rõ ràng; màn `Hôm nay` đang có 2 điểm vào `Không gian học` (`today-dir-study` và `_buildStudySpaceEntryCard` khi chưa có phiên chạy).

## Phạm vi

- **Trong phạm vi:** `StudySpaceScreen`, `StudyCommunitySheet`, `StudyRoomSessionPanel`, `TodayScreen` và bộ widget tests Không gian học.
- **Ngoài phạm vi:** Vòng đời dọn phòng / TTL / heartbeat / chủ phòng rời trên backend PostgreSQL sẽ thực hiện ở task riêng `T094`.
- **Tài liệu chuẩn:** `AGENTS.md §3`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/07-khong-gian-hoc.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Mở Không gian học | Có đúng 3 lựa chọn rõ ràng `Học một mình`, `Học cùng MindClock AI`, `Học cùng bạn`, kèm lựa chọn tường minh `Bắt đầu ngay` hoặc `Hẹn giờ` (không tự tạo lịch ngầm khi chưa xác nhận). | TC-01 |
| AC-02 | Chọn `Học một mình` và bắt đầu phiên | Chỉ hiển thị đồng hồ, mục tiêu, ô ghi chú vướng mắc (`study-solo-stuck-note-input`), tạm dừng và kết thúc; tuyệt đối không có chat hay avatar AI. | TC-02 |
| AC-03 | Chọn `Học cùng MindClock AI` | Có phiên chat lịch sử trong phiên, hỏi bằng chữ / giọng nói / ảnh có consent (`study-ai-photo-consent-btn`), nghe giọng trả lời, không giả quan sát người học; `Tạo câu luyện` là hành động tùy chọn ở duy nhất 1 nơi, lọc đúng môn theo `StudyProfile`, không tự sinh khi mở phòng. | TC-03 |
| AC-04 | Chọn `Học cùng bạn` hoặc đang ở trong phòng bạn bè | Chỉ hiển thị sảnh/phòng bạn bè (`StudyRoomSessionPanel`), không hiển thị khối thiết lập hay điều khiển `Học một mình` / AI cá nhân bên dưới (trừ khi phòng chủ động bật mời AI); mic/cam tắt mặc định và ghi rõ trạng thái chưa truyền cuộc gọi trực tiếp; màn `Hôm nay` chỉ có 1 điểm vào Không gian học. | TC-04 |

## Quyết định/mâu thuẫn

- Trên `TodayScreen`, ô `today-dir-study` trong Danh mục tính năng là điểm vào duy nhất cho Không gian học (thể hiện luôn trạng thái đang học nếu có phiên đang mở), bỏ thẻ `_buildStudySpaceEntryCard` bị lặp ở cuối màn `TodayScreen`; cập nhật `study_focus_local_test.dart` bấm qua `today-dir-study`.
