# Bàn giao

Trạng thái verifying cho Git. AC01–04 đạt bằng test SQLite/PostgreSQL/Flutter của lát room-capacity, không gọi toàn bộ cộng đồng hoàn tất.

Đã sửa giới hạn phòng 2–8 mặc định4 và row lock chống vượt chỗ, incoming/outgoing lời mời và trạng thái đóng, bộ lọc môn/lớp/còn chỗ, code join, room detail từ tab Tôi sang phòng. Giữ nguyên luật game và asset WIP. Thiết kế pet/share tại docs/01-product/14-pet-nhom-va-the-chia-se.md, chưa có asset/runtime/share thật.

Tests 20/11/2026: Flutter 7 PASS, backend SQLite 4 PASS, PostgreSQL concurrency 1 PASS trong DB UUID riêng; xem tests.md. Chưa có ảnh Android/media nhiều máy. Chưa push.

Điểm tiếp tục: API host settings/capacity sau tạo và get-room refresh/presence, mã mời TTL/rotate/QR, room permission/moderation/rate-limit và Live media trước người lạ; nhóm cam kết + ledger pet và asset gốc duyệt trước share. T065 game vẫn verifying; không mở ranked.
