# Đặc tả T026

## Kết quả

Một AI coding từ `docs/README.md` có thể đi theo chuỗi cài app → tài khoản → hồ sơ học THPT → avatar → kế hoạch AI có xác nhận → dashboard → lịch/giấc ngủ/báo thức → ôn sáng → phòng học với AI/bạn → PvP → profile, biết rõ phần nào đã code/chưa code, quyền OS/AI và test cần đạt.

## AC ↔ TC

| AC | Yêu cầu | Test |
| --- | --- | --- |
| AC-01 | PRD/UX có luồng chính, lựa chọn, empty/error/offline và quyền theo lúc dùng; THPT 10–12 là phạm vi đầu | TC-01 |
| AC-02 | Alarm/DND/lock screen/giấc ngủ có giới hạn OS và Dừng khẩn cấp; không hứa cấm gian lận tuyệt đối | TC-02 |
| AC-03 | Không gian học có lựa chọn học một mình/AI/bạn, giọng nói/video avatar với feature gates, nhân cách nghiêm nhưng không xúc phạm | TC-03 |
| AC-04 | SQL/API/AI/content/game/social/privacy/test/trace/roadmap khớp hành trình mới | TC-04 |
| AC-05 | AGENTS/skills/index/README trỏ đúng nguồn, không còn định hướng thi demo; link/test pass, WIP không bị chạm | TC-05 |

## Quyết định cho docs

Happy path có đăng ký email/mật khẩu và xác minh, nhưng báo thức local/Dừng khẩn cấp không phụ thuộc tài khoản. Quyền OS xin theo ngữ cảnh, màn mở đầu chỉ giải thích. Tên hiển thị là biệt danh; không bắt tên pháp lý hoặc Gmail riêng. Chương trình GDPT 2018 là catalog có version và người duyệt, không để Gemini tự định môn. Camera/voice/phòng bạn bè là opt-in. Voice Live liên tục và video avatar là giai đoạn sau có cost/privacy gates. Không đồng nhất việc hoàn thành câu với quyền dừng chuông.
