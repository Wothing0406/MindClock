# Đặc tả

## Lát cắt giao diện điện thoại 14/11
- AC-M1: khung mobile tối đa 480px trên desktop, full width trên điện thoại, safe area và bottom navigation Hôm nay/Báo thức/Học/Tôi; không PvP.
- AC-M2: mỗi hành trình màn riêng; timer và chat có tab con; vùng chạm 48px, không zoom cưỡng chế, bàn phím không che Dừng.
- AC-M3: bảo toàn API/chuông/timer; retry bài nộp dùng lại ID khi chưa có kết quả; hoàn thành offline giữ metadata để gửi lại bằng thao tác chủ động.
- AC-M4: chia HTML/CSS/JS thành asset có route rõ, test syntax/logic/HTTP; không coi test Node là browser QA.
Nguồn: docs/05,13,30,31,45, API schemas.py/routes/v1.py.
- AC01: /product UI responsive tiếng Việt, không JSON/emoji -> TC01 HTTP/syntax/browser.
- AC02: lưu giờ local, thử chuông/dừng không chờ API, nêu giới hạn browser -> TC02.
- AC03: timer mốc thời gian pause/resume/finish/restore -> TC03.
- AC04: AI qua API, message_vi, lỗi/timeout/retry và fallback rõ -> TC04.
- AC05: câu/phiên/bài qua API, uncertain không gọi sai, không XP giả -> TC05.
Không đổi schema/API/auth/backend; dev bearer hiện có chỉ dùng local. Chat không lưu mặc định. Báo thức web không thay thế alarm OS.
