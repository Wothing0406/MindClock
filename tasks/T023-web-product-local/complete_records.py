from pathlib import Path

root = Path(__file__).resolve().parent
records = {
    'README.md': '''# T023 — Web product local
- **Trạng thái:** `verifying`
- **Mục tiêu:** web báo thức và Không gian học AI theo yêu cầu 20 phút, 14/11/2026.
- **Source refs đã đọc:** docs/05,13,30,31,45; schemas.py/routes/v1.py/config.py; handoff T022; frontend-design/SKILL.md.
- **Phạm vi:** product_ui.py, product.html, main.py, run_product.py, START-MINDCLOCK.cmd.
- **Điểm tiếp tục:** chạy launcher, mở http://127.0.0.1:8010/product, kiểm Chrome thật và Gemini fallback. Không chồng file demo_ui.py đang sửa đồng thời.
''',
    'spec.md': '''# Đặc tả
Nguồn: docs/05,13,30,31,45, API schemas.py/routes/v1.py.
- AC01: /product UI responsive tiếng Việt, không JSON/emoji -> TC01 HTTP/syntax/browser.
- AC02: lưu giờ local, thử chuông/dừng không chờ API, nêu giới hạn browser -> TC02.
- AC03: timer mốc thời gian pause/resume/finish/restore -> TC03.
- AC04: AI qua API, message_vi, lỗi/timeout/retry và fallback rõ -> TC04.
- AC05: câu/phiên/bài qua API, uncertain không gọi sai, không XP giả -> TC05.
Không đổi schema/API/auth/backend; dev bearer hiện có chỉ dùng local. Chat không lưu mặc định. Báo thức web không thay thế alarm OS.
''',
    'plan.md': '''# Kế hoạch
- [x] UI riêng /product, không sửa file demo đang có thay đổi đồng thời.
- [x] Nối API, chuông local, timer và khôi phục context học.
- [x] Node syntax/logic, TestClient HTTP/API, backend pytest.
- [x] Server startup và launcher local với migration.
- [ ] Browser/âm thanh/responsive thực tế: CUA dừng do URL guard.
- [ ] Gemini live: hiện endpoint trả fallback, UI nhận diện rõ.
- [x] Bàn giao giới hạn và điểm tiếp tục.
''',
    'tests.md': '''# Kiểm thử
## Kết quả thực 14/11/2026
- TC01/AC01: TestClient /product 200, nội dung tiếng Việt; node --check exit 0. Browser chưa kiểm.
- TC02/AC02: Node VM local stop pass; âm thật chưa kiểm.
- TC03/AC03: Node VM start/pause/resume/finish pass. Restore theo localStorage được code; chưa thử browser.
- TC04/AC04: Node VM message_vi/error/retry pass. API live kiểm mock_mode false, HTTP 200 nhưng message fallback; không coi Gemini live đạt.
- TC05/AC05: TestClient health và câu Toán 200, không XP giả trong UI.
- pytest backend: 13 passed, 1 warning, 25.74s.
- compileall product_ui.py/main.py pass.
- Server Uvicorn startup 8010 nhưng shell loopback timeout. CUA dừng do không xác định URL; không tuyên bố kiểm browser pass.
''',
    'handoff.md': '''# Bàn giao T023
- **Trạng thái:** verifying, chưa production-ready.
- **Đã làm:** UI web nền giấy/teal/night, SVG, hai luồng; báo thức local và đồng bộ cấu hình; WebAudio/MP3, Dừng khẩn cấp; lấy câu/nộp bài qua API; timer mốc thời gian pause/resume/finish/restore; chat chữ với timeout/retry/error, fallback có nhãn, không lưu chat mặc định.
- **File:** services/api/app/product.html, product_ui.py, main.py, services/api/run_product.py, START-MINDCLOCK.cmd.
- **Test:** xem tests.md; backend 13 passed, Node VM pass, HTTP qua TestClient 200.
- **Chạy:** nhấp START-MINDCLOCK.cmd, mở http://127.0.0.1:8010/product. Launcher chạy migration và bind loopback.
- **Giới hạn:** chuông browser cần tab/máy hoạt động. SQL hiện theo cấu hình local SQLite, không giả PostgreSQL. AI đang trả fallback, chưa chứng minh live. CUA bị guard chặn, shell loopback timeout; chưa thao tác âm/thị giác thật.
- **Điểm tiếp tục:** chạy launcher ngoài phiên công cụ, mở Chrome, kiểm Thử chuông/Dừng/timer/chat; chẩn đoán upstream Gemini nếu fallback. Không ghi đè demo_ui.py đang do T022 sửa.
''',
    'worklog.md': '''# Nhật ký
- 14/11: tạo file UI/route riêng để tránh chỉnh chồng T022.
- Tái hiện AI HTTP200 nhưng trả hướng dẫn dự phòng; UI sửa nhận safety_status/model offline, không coi là live; Node VM test pass.
- Một lệnh shell chỉnh HTML lỗi quoting, chưa sửa file; chuyển script Python và test lại pass.
- CUA bị URL guard dừng, không vượt guard; API/logic kiểm qua TestClient/Node, không thay browser QA.
''',
}
for name, content in records.items():
    (root / name).write_text(content, encoding='utf-8')
print('Task records updated')
