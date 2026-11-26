# Bàn giao T023

## Cập nhật mobile 14/11/2026
- Chạy phiên mới bằng `services/api/.venv/Scripts/python.exe services/api/run_product.py --port 8011` vì 8010 đang có server cũ (bind error 10048); không tắt phiên cũ. Launcher mặc định vẫn 8010 sau khi người dùng dừng server cũ.
- `/product` nay dùng mobile.html + product.css + product.js, có route asset no-store. File product.html cũ giữ tham chiếu bản đầu, không còn là trang mặc định.
- Màn Hôm nay/Báo thức/Học/Tôi, bottom nav safe-area, khung điện thoại 480px trên desktop, chọn ngày vùng chạm 48px cuộn ngang, chữ nhập 16px, không cấm zoom; Học tách Đồng hồ/Hỏi AI.
- Bổ sung queue metadata phiên kết thúc chưa đồng bộ với gửi lại chủ động; giữ deadline/context khi restore, timer hết giờ không bị nhận nhầm pause; khóa chỉnh task trong phiên.
- Báo thức POST có key retry ổn định, nhận server ID rồi PATCH khi chỉnh; ngày chưa lưu là draft. Bài nộp timeout giữ key cho cùng payload. Mã phiên hỗ trợ origin HTTP không có randomUUID.
- Test mới backend `test_product_mobile.py`: asset/ID/viewport/safe-area; toàn backend 14 passed. Node logic pass navigation, timer restore/pause/resume/finish, queue sync, chat/error/retry, DOM contract. Browser và âm thật chưa có công cụ kiểm trong phiên này.
- Khi chạy server cũ: Ctrl+C rồi chạy START-MINDCLOCK.cmd; mở http://127.0.0.1:8010/product. Mã router cần reload để nhận CSS/JS route mới. Nguồn hướng dẫn docs/54-web-mobile-local.md.
- **Trạng thái:** verifying, chưa production-ready.
- **Chat API cuối:** /v1/study/help trả 200, safe, message_vi tiếng Việt theo câu hỏi qua gemini-3.5-flash-lite. Đường app server → Gemini → schema phản hồi đã chạy thật; browser rendering chưa kiểm.
- **Cập nhật AI cuối:** sau cài socksio, gọi upstream trực tiếp thành công bằng gemini-3.5-flash-lite, có candidates. Browser end-to-end vẫn chưa kiểm vì CUA guard.
- **Sửa upstream:** đã tìm ImportError do HTTPX dùng SOCKS proxy nhưng thiếu socksio; cài socksio 1.0.0 thành công trong .venv và đổi requirements sang httpx[socks]==0.28.1. Cần kiểm lại mạng/model/quota sau khi hết lỗi dependency.
- **SQL smoke:** create study 200, retry cùng session ID, finish 200 trên DB local hiện có.
- **Đã làm:** UI web nền giấy/teal/night, SVG, hai luồng; báo thức local và đồng bộ cấu hình; WebAudio/MP3, Dừng khẩn cấp; lấy câu/nộp bài qua API; timer mốc thời gian pause/resume/finish/restore; chat chữ với timeout/retry/error, fallback có nhãn, không lưu chat mặc định.
- **File:** services/api/app/product.html, product_ui.py, main.py, services/api/run_product.py, START-MINDCLOCK.cmd.
- **Test:** xem tests.md; backend 13 passed, Node VM pass, HTTP qua TestClient 200.
- **Chạy:** nhấp START-MINDCLOCK.cmd, mở http://127.0.0.1:8010/product. Launcher chạy migration và bind loopback.
- **Giới hạn:** chuông browser cần tab/máy hoạt động. SQL hiện theo cấu hình local SQLite, không giả PostgreSQL. AI đang trả fallback, chưa chứng minh live. CUA bị guard chặn, shell loopback timeout; chưa thao tác âm/thị giác thật.
- **Điểm tiếp tục:** chạy launcher ngoài phiên công cụ, mở Chrome, kiểm Thử chuông/Dừng/timer/chat; chẩn đoán upstream Gemini nếu fallback. Không ghi đè demo_ui.py đang do T022 sửa.
