# Ranked, mùa giải và kinh tế mỹ thuật — cổng sau giao hữu

**Trạng thái:** đề xuất, chưa mở API/trận xếp hạng. [GDD combat](01-pvp-gdd.md) v0.1 chỉ để playtest; tài liệu này không tự phê duyệt balance/coin. Mục tiêu là thi đấu tự nguyện công bằng, không biến báo thức thành điểm rank.

## Điều kiện mở ranked

Giao hữu hai máy đạt độ tin cậy đồng bộ/chấm; bộ câu cùng curriculum/grade/subject đủ cho mùa; cơ chế appeal có người xử; quyền asset/content/tuổi đã duyệt; chống multi-account/AFK cơ bản; server event/ledger bất biến. Nếu pool nhỏ, chỉ mở giao hữu và nhãn `Chưa có xếp hạng môn này`.

## MMR/RP và bậc

`rank_ledger` là nguồn ghi tăng/giảm duy nhất, match settle một lần. MMR dùng ghép trận nội bộ; RP hiển thị theo môn/mùa. Tiers hiển thị đề xuất: Đồng, Bạc, Vàng, Bạch Kim, Kim Cương; mỗi tier có bậc 5→1. Mốc RP, K-factor, placement, chống farm và rớt hạng phải được chạy mô phỏng/season test và chốt `rating_rule_version` trước code; không lấy số tùy ý từ docs archive. Trận void/AI uncertain/đối thủ mất mạng do lỗi hệ thống không đổi RP. Thắng/thua chỉ sau kết quả server, có màn giải thích biến động và đường kháng nghị.

Leaderboard tách theo môn, khối, curriculum, mùa; chỉ user opt-in, alias/avatar đã duyệt; không công khai trường, giờ dậy hoặc bài làm. Mùa kết thúc đóng ledger cũ, badge lịch sử gắn season ID, không đổi retroactive. Hồ sơ ẩn/xóa phải biến mất khỏi projection/cache theo policy.

## Coin, mua nhân vật và nhiệm vụ

Nếu mở coin: kiếm từ nhiệm vụ học hợp lệ/giao hữu/ranked có giới hạn ngày và chống lặp server; ví ledger hai chiều, balance là projection. Dùng coin chỉ cho **nhân vật/skin/khung/FX mỹ thuật** sau duyệt, không mua damage/HP, câu dễ hoặc lượt hồi. Ba tướng core luôn có đường chơi miễn phí; tướng mua sau phải tuân cùng budget balance và không độc quyền sức mạnh. Không tiền thật trong giai đoạn này; thanh toán thật là product/legal/security task riêng. Nhiệm vụ không ép thức dậy sớm trái nhu cầu ngủ, không trừ coin vì bỏ ngày.

## Kiểm thử trước mở

Simulation nhiều trình độ/tướng/môn cho phân bố win rate, queue time và rank inflation; A/B account, retry/duplicate settle/ledger, disconnect, appeal/void, chuyển mùa, mua coin hai lần, số dư âm, leaderboard opt-out/xóa, giả mạo kết quả client. UI phải hiện nguyên nhân không ghép được và thời gian chờ ước tính trung thực. Nếu mô phỏng hoặc nội dung chưa đủ, giữ ranked tắt bằng server feature flag; giao hữu không tự đổi RP.
