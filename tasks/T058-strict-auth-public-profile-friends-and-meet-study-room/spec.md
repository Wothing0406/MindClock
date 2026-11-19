# Đặc tả kỹ thuật T058

## Mục tiêu & Ràng buộc

1. **AC-01 (Bỏ Guest Mode trên WelcomeScreen):**
   - `WelcomeScreen` không còn nút `Dùng thử không cần tài khoản` (`guest-start-setup`) hay `Để sau` (`guest-skip-later`).
   - Người dùng mới đi thẳng qua nút `Bắt đầu ngay (Đăng ký / Đăng nhập)` (`welcome-auth-start`), chỉ giữ đường cứu sinh `Chỉ báo thức khi mất mạng` (`guest-alarm-only`) để báo thức local không bị chặn khi offline/Auth lỗi.
2. **AC-02 (Mật khẩu mạnh & Chính sách rõ ràng phải chấp nhận):**
   - Form đăng ký trên `AuthScreen` bắt buộc mật khẩu $\ge 8$ ký tự, có ít nhất 1 chữ hoa, 1 chữ thường, 1 số và 1 ký tự đặc biệt; hiển thị checklist độ mạnh realtime tiếng Việt.
   - Hiển thị nút mở sheet/dialog **Toàn văn Điều khoản sử dụng & Chính sách quyền riêng tư (`v2026-11`)** giải thích rõ: mục đích tài khoản, ảnh bài làm không lưu mặc định, không lộ giờ dậy/TKB cho người lạ, quyền xóa dữ liệu; người dùng phải tích đồng ý điều khoản và nhóm tuổi mới tạo tài khoản được, kèm gọi ghi nhận `consent` theo `policyVersion`.
3. **AC-03 (Backend Gói B trên FastAPI + PostgreSQL 16):**
   - Migration `0004_add_community_friends_and_study_rooms.py` tạo bảng `friend_requests`, `friendships`, `user_blocks`, `study_rooms`, `study_room_members`.
   - Routes `/v1/profiles/{userId}`, `/v1/users/search`, `/v1/friends/request`, `/v1/friends/requests`, `/v1/friends/requests/{id}/respond`, `/v1/friends`, `/v1/study-rooms/public`, `/v1/study-rooms`, `/v1/study-rooms/{id}/join`, `/v1/study-rooms/{id}/leave`, `/v1/study-rooms/ai-match`.
   - Bảo mật: chỉ tài khoản đã xác thực, kiểm tra chéo `user_blocks`, **tuyệt đối không lộ** `email`, `alarms`, `timetable` chi tiết hay giờ dậy qua API công khai/phòng học; hỗ trợ `DELETE /v1/me` xóa sạch dữ liệu cộng đồng của user.
4. **AC-04 (Flutter UI Profile công khai, Kết bạn, Quét phòng Meet & AI Avatar 2D cử động):**
   - UI xem Profile học sinh công khai (Avatar + Biệt danh + Lớp + Môn học + Mục tiêu + nút Kết bạn/Hủy/Chặn).
   - UI Tìm bạn / Lời mời kết bạn / Danh sách bạn bè.
   - UI Quét phòng công khai (`visibility: public | invite_only`) + nút `AI ghép nhóm phù hợp trình độ`.
   - Giao diện phòng học nhiều người **lưới thẻ kiểu Google Meet** (mỗi ô là avatar/khung cam + trạng thái mic/cam tắt mặc định, người dùng tự bật/tắt; ô `MindClock AI` có avatar 2D cử động nhịp chớp mắt/gật đầu/gợi mở rõ nhãn AI và tôn trọng Reduce Motion).
5. **AC-05 (Responsive, không Raw Color, đầy đủ test):**
   - Không tràn layout ở `320dp`, `textScale: 2.0`, `RAW_COLOR_HITS = 0`, `flutter analyze --no-pub` không lỗi, `pytest` chạy sạch trên PostgreSQL 16 thật.
