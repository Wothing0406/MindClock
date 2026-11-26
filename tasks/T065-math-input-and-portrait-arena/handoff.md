# Bàn giao

Trạng thái `verifying`; chưa commit/push vì AC-03 chưa được kiểm chứng trên Android và hai tài khoản thật. Các file arena còn chứa WIP T064 có từ trước, không stage gộp.

Đã sửa formatter phần trăm/đơn vị/chỉ số và grouping phân số; thêm hàng ký hiệu cuộn ngang và xem trước cho đáp án/trình bày. Đã giữ sprite trong sân thu gọn, thêm bộ ba thẻ chiêu với frame đúng tướng, tên/nội tại/chi phí/lý do khóa; bỏ dãy nút chiêu trùng. PvP mở thẻ theo snapshot `correct` + `action_window`. Màn ghép trận có tướng đã chọn và nút hủy; không giả đối thủ.

Giới hạn: chưa chuyển sang Flame; chưa layout sân cố định khi cuộn đề; chưa bổ sung event playback PvP/âm thanh; không thay luật hay mở ranked. Formatter chưa phải LaTeX đầy đủ.

Điểm tiếp tục: analyze đã PASS. E2E không còn chạy: hai lần lỗi cache build Android và lần ba dừng do không có log tiến triển, chi tiết trong tests.md. Chẩn đoán môi trường build Windows rồi chạy lại `flutter test --no-pub integration_test/arena_game_e2e_test.dart -d emulator-5554` trong app/; chụp màn Android để rà bố cục; dùng hai tài khoản backend kiểm queue/cancel/submit/action/reconnect. Không coi fixture E2E là đăng nhập thật. Sau khi đạt AC mới rà diff từng hunk của T064/T065, commit đúng phạm vi và push; không đưa Firebase config hoặc WIP khác vào commit.
