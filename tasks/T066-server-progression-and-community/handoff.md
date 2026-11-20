# Bàn giao

Trạng thái done cho lát backend tiến độ và kế hoạch cộng đồng của T066; không là trạng thái hoàn thành toàn bộ cộng đồng. T065 và T064 có WIP riêng cần giữ nguyên.

Đã có service progression.py, summary tính chuỗi ôn từ ledger và level progress-v1, xp-history owner-only phân trang. Flutter nhận level/xpToNextLevel và hiển thị ở tiến độ luyện tập. Contract và kế hoạch cộng đồng tại docs/01-product/13-tien-do-va-cong-dong-trien-khai.md. Kết quả kiểm trong tests.md.

Điểm tiếp tục: kiểm PostgreSQL/A-B và đồng bộ hai thiết bị; bổ sung test Flutter cho trường level rồi profile thống nhất và lịch sử EXP UI. Chốt snapshot ngày thưởng/system grace trước dùng streak cho pet. Các lát bạn bè/nhóm/phòng, asset pet, danh hiệu, ví/leaderboard server và PvP phải mở task riêng theo kế hoạch; chưa triển khai trong T066.

T067 đã kiểm PostgreSQL migration/ledger trong DB test riêng và nối UI tiến độ vào tab Tôi. AC backend T066 đạt ở mức unit/API/PostgreSQL; hai điện thoại còn là cổng release như spec, không là bằng chứng đã phát hành. Bước tiếp: profile metadata/avatar/danh hiệu, snapshot ngày thưởng/system grace trước pet; kiểm thiết bị thật.

Git: code commit `bf28373467c8783377020b2ae8372b982371c352` trên `main`, push thành công 20/11/2026 và xác minh bằng git ls-remote origin refs/heads/main. Không đưa WIP T064/T065, asset hay Firebase config vào commit. Bản ghi này theo sau bằng commit bàn giao.
