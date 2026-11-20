# Đặc tả

AC01: ngày ôn là ngày có thưởng challenge_correct từ server, lấy ngày tạo ledger theo timezone tài khoản; trùng ngày chỉ tính một, hôm nay chưa làm giữ chuỗi đến hết hôm nay, ngày bị bỏ lỡ làm chuỗi về 0. Không gọi đây là chuỗi dậy đúng giờ.
AC02: level v1 = 1 + floor(sqrt(EXP/100)); tổng EXP mốc level L = 100*(L-1)^2. EXP từ ledger, không tự ghi level. Không cấp thêm EXP khi đọc summary.
AC03: lịch sử EXP phân trang owner-only không trả dữ liệu user khác. Giữ contract trường cũ.
AC04: test ngày liên tiếp, thiếu ngày, tương lai, timezone, level boundary, API A/B. PostgreSQL và hai thiết bị vẫn cần kiểm riêng.
