# Bàn giao T010

- **Trạng thái:** `verifying`; docs/asset và rule local đạt, backend/upload/moderation thật chưa triển khai.
- **Đã làm:** docs/52 hồ sơ/ảnh tải lên/quyền công khai/hai lịch sử/uy tín/API/SQL; docs/53 ngôn từ/tên/ảnh/phát ngôn/báo cáo/kháng nghị; đồng bộ docs/07/21/24/25/28/43/44; sáu huy hiệu hạng SVG riêng khung; web demo có preview tải ảnh local và chọn avatar/khung/badge, thẻ kết thúc hiển thị badge mẫu; README mô tả Clock, lịch, câu hỏi, không gian học, chatbot, PvP, hồ sơ và tình trạng thật.
- **Test đã chạy:** xem [tests.md](tests.md); `test_profile_rules.js`, asset XML/đường dẫn, docs links, task checker, diff đều exit 0 ngày 12/11/2026 Windows.
- **Chưa chạy:** file picker/hiển thị badge trên Chrome Android; backend ảnh/mức quyền/moderation chưa có nên TC-03–05 là đặc tả cần task coding riêng. Không gọi bản preview là upload thật.
- **Rủi ro:** chính sách trẻ em/ngưỡng tuổi và quy trình vận hành cần duyệt trước pilot; ảnh của người dùng có thể cần người duyệt và object storage, không bật công khai nếu chưa có năng lực. Badge RP chỉ được server cấp sau cổng ranked.
- **Điểm tiếp tục:** xem `docs/52–53` trước task backend; tạo task riêng cho `GET/PATCH /v1/me`, avatar upload pending/duyệt/xóa và test A/B/cache; trên Android mở demo T009, chọn ảnh PNG/JPEG/WebP hợp lệ/sai, đổi avatar, xem badge ở profile và thẻ kết thúc, ghi kết quả TC-01–02 tại `tests.md`. Chỉ đổi `done` khi phần được yêu cầu chạy thật đạt.
- **Push GitHub:** chờ commit/remote SHA ở cuối lượt này.
