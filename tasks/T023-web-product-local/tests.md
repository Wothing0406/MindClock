# Kiểm thử

## Lát cắt mobile
- Backend pytest: 14 passed, 1 deprecation warning; /product và CSS/JS 200 đúng MIME qua TestClient.
- Node test_product.js dùng product.js mới (không dùng script legacy): navigation 4 màn/tab Học, restore deadline, pause/resume/finish, sync queue metadata, stop local, chat mapping/error/retry, ID DOM pass.
- Node --check product.js pass; task records pass.
- Browser ở 320/360/390/600px và text scale 200% chưa kiểm trực quan/âm thật; không gắn done.
- TC-M1: route HTML/CSS/JS, không ID trùng, đủ control JS cần.
- TC-M2: Node kiểm điều hướng 4 màn/timer-chat, retry, lưu/khôi phục local, dừng chuông.
- TC-M3: browser 320/360/390/600 và chữ 200% cần kiểm thật, chưa được coi pass từ Node.
## Kết quả thực 14/11/2026
- Kiểm cuối qua /v1/study/help thật: HTTP 200, safety_status=safe, model=gemini-3.5-flash-lite, message_vi tiếng Việt có nội dung theo câu hỏi; không fallback.
- Sau sửa SOCKS: upstream thật trả UPSTREAM_OK gemini-3.5-flash-lite HAS_CANDIDATES True. Đây là kiểm upstream trực tiếp, không thay browser chat QA.
- SQL thực qua TestClient: study create 200; retry giữ nguyên sessionId; finish 200.
- Chẩn đoán AI: ImportError SOCKS thiếu socksio; cài socksio 1.0.0 thành công, requirements ghi httpx[socks].
- git diff --check toàn repo còn trailing whitespace ở demo_ui.py đang sửa bởi phiên khác; không chạm file đó. Các file của T023 không có lỗi whitespace được báo.
- TC01/AC01: TestClient /product 200, nội dung tiếng Việt; node --check exit 0. Browser chưa kiểm.
- TC02/AC02: Node VM local stop pass; âm thật chưa kiểm.
- TC03/AC03: Node VM start/pause/resume/finish pass. Restore theo localStorage được code; chưa thử browser.
- TC04/AC04: Node VM message_vi/error/retry pass. API live kiểm mock_mode false, HTTP 200 nhưng message fallback; không coi Gemini live đạt.
- TC05/AC05: TestClient health và câu Toán 200, không XP giả trong UI.
- pytest backend: 13 passed, 1 warning, 25.74s.
- compileall product_ui.py/main.py pass.
- Server Uvicorn startup 8010 nhưng shell loopback timeout. CUA dừng do không xác định URL; không tuyên bố kiểm browser pass.
