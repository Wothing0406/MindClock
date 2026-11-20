# Bàn giao

Trạng thái done. AC01–04 của lát tiến độ đạt bằng test Flutter/HTTP/PostgreSQL; không tuyên bố đã phát hành Android.

Đã nối tab Tôi với ProgressSummary từ server, thanh EXP theo mốc API, chuỗi ôn và lịch sử EXP phân trang. Các trạng thái khách/fixture/rỗng/lỗi/hết token có UI rõ. Response cũ sau logout/đổi A→B hoặc refresh mới bị bỏ. Không persist EXP vào ví local, không tạo danh hiệu/rank giả. Giữ WIP T064/T065 và Firebase config ngoài commit.

Kiểm chứng 20/11/2026 Windows: 9 test T067 PASS, 6 test personal flow PASS, analyze sạch; PostgreSQL test PASS sau Alembic head trong DB UUID riêng tự xóa, kiểm A/B/hai client/idempotent ledger. Docs links PASS 616 Markdown, task records PASS. Xem tests.md.

Giới hạn: chưa chụp/rà profile trên Android hoặc hai điện thoại; metadata profile/avatar upload và danh hiệu chưa đồng bộ đầy đủ. Chuỗi ôn chưa dùng thưởng pet. Bước tiếp: chạy APK tab Tôi với tài khoản test, hai thiết bị đọc cùng progress; mở task snapshot ngày thưởng/system grace rồi nhóm/pet. Không mở ranked trước cổng PvP.

Git: code commit `bf28373467c8783377020b2ae8372b982371c352` trên `main`, push thành công 20/11/2026, git ls-remote xác minh đúng SHA. Bản ghi này theo sau bằng commit bàn giao. WIP game/asset/Firebase giữ ngoài commit.
