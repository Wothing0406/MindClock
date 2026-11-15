# Ca nghiệm thu gắn PRD

Đây là **thiết kế test**. Chỉ ghi `pass` trong `tasks/TNNN/tests.md` sau khi chạy với lệnh/máy/ngày. ID trong [PRD](../01-product/01-prd.md) dẫn đến bảng này; các ca Android AD01–AD09 chi tiết ở [test plan](01-ke-hoach-kiem-thu.md). Khi thêm yêu cầu mới, thêm AC/TC tương ứng trước code.

| ID | Liên kết PRD | Kịch bản và expected | Tầng |
| --- | --- | --- | --- |
| UX-01 | P-01 | Cài mới thấy giải thích quyền/đăng ký; thiếu mạng có `Chỉ dùng báo thức trên máy`, không gọi Auth để dừng chuông | Flutter widget + Android manual |
| AUTH-01 | P-01 | Đăng ký/verify token hợp lệ tạo profile đúng owner; token sai/hết hạn 401; local alarm không gọi `/v1/me` | Flutter/API contract |
| AL-01 | P-02 | Thêm/sửa/xóa alarm, occurrence tuần/timezone/reboot đúng | Kotlin unit + AD01/07 |
| AL-02 | P-02 | Quyền OS chưa cấp: UI `saved_local/needs_permission`, không ghi `scheduled_os` | bridge + AD04 |
| AL-03 | P-02 | API lưu alarm thành công nhưng OS schedule thất bại: UI không báo đã sẵn sàng | integration |
| AL-04 | P-02 | AI gợi giờ và user không xác nhận: không có alarm mới/đổi giờ | widget/domain |
| AL-05 | P-03 | Challenge offline/màn khóa/app chết vẫn reo/Dừng ngay | AD01–03/05 |
| AL-06 | P-03 | Challenge không có Hoãn; Dừng khẩn cấp không disabled bởi camera/AI loading | AD05/06 + widget |
| AL-07 | P-03 | Không có câu cache: vẫn dừng, `Ôn sau`, không tự cấp XP | Android E2E + API |
| AL-08 | P-03 | Reboot/timezone/quyền đổi không tạo chuông trùng hoặc mất mà UI báo sai | AD04/07 |
| AL-09 | P-03 | Chữ 200%/TalkBack vẫn thấy/chạm Dừng | AD09 |
| AL-10 | P-04 | Mode thường Hoãn local đúng thời lượng, mode thử thách không Hoãn | Kotlin unit + AD06 |
| LEARN-01 | P-05 | Mất mạng/câu chưa duyệt: hoàn thành không chấm, không lộ rubric/XP | content + integration |
| LEARN-02 | P-06 | Nhập đáp án + bước giải chữ, nộp thành công một lần | widget/API |
| LEARN-03 | P-06 | Camera từ chối/ảnh mờ/ảnh quá lớn: đường chữ và `uncertain`, ảnh không lưu | AD08 + API/security |
| LEARN-04 | P-06 | Câu có cách giải tương đương được duyệt không bị chấm sai | human rubric + AI eval |
| LEARN-05 | P-06 | Submit kép/cùng key trả cùng kết quả và XP một lần; khác payload 409 | PostgreSQL transaction |
| LEARN-06 | P-07 | Sai rõ lần 1–2 không hint; lần 3 mở hint một bước; uncertain không tăng sai | API + UI contract |
| MORNING-01 | P-03 | Mở từ alarm vào cảnh ngắn rồi cùng câu; bỏ cảnh không bỏ câu; asset lỗi/Reduce Motion dùng chữ tĩnh | Flutter/Android E2E |
| MORNING-02 | P-07 | Đếm 3/5 lần `incorrect` duy nhất; lần 5 mới có Bỏ lượt; retry/uncertain/lỗi không tăng; Dừng âm luôn dùng được | API/PostgreSQL + Android |
| MORNING-03 | P-08 | Chỉ câu đúng đủ bước cấp EXP/ngày chuỗi một lần; bỏ lượt/dừng/đóng app hết ngày không cấp; planned rest và system grace không làm đứt chuỗi oan | API/PostgreSQL A/B + ngày/timezone |
| AI-01 | P-06 | Gemini/validator bất đồng, ảnh mờ, timeout → uncertain, không phạt/không cấp XP sai | AI eval/API |
| AI-02 | P-07 | Socratic không trả đáp án cuối trước nỗ lực, không lộ rubric qua field/lỗi | prompt injection + contract |
| EDU-01 | P-06 | EduSkills tạo nháp câu/rubric/hook; không reviewer/quyền hoặc lệch outcome thì không publish/scored | content pipeline/contract |
| EDU-02 | P-07 | `HINT_ONE_STEP` và response trước kết thúc không lộ đáp án/đoạn kết; post-attempt mới giải thích | prompt eval/API |
| EDU-03 | P-06 | Bộ môn/khối đúng catalog, cách giải tương đương, đơn vị và thuật ngữ cho kết quả công bằng | human-labeled eval đa môn |
| EDU-04 | P-06 | OCR Tesseract không được dùng chấm chữ viết tay; ảnh không đọc rõ trả uncertain và có đường nhập chữ | pipeline/security/AI eval |
| DATA-01 | P-08 | XP/streak do server, dữ liệu tiến độ riêng, giờ dậy không vào rating | SQL/API A/B |
| FOCUS-01 | P-09 | Timer chạy offline, pause/resume/finish | Dart unit/widget |
| FOCUS-02 | P-09 | Background/kill/restart không tạo phạt hoặc kẹt phiên | Android lifecycle |
| FOCUS-03 | P-09 | Finish retry idempotent, API lỗi vẫn thoát được | Flutter/API contract |
| FOCUS-04 | P-09 | Camera/mic opt-in, từ chối vẫn học được | permission/manual |
| FOCUS-05 | P-09 | Rời app không khóa app khác hoặc trừ điểm | Android manual |
| FOCUS-06 | P-09 | AI gợi một bước, không tự bật camera/mic hay đưa đáp án cuối trước nỗ lực | prompt/API review |
| FOCUS-07 | P-09 | Room timer/các nút chính đọc/chạm được với 320dp, chữ 200%, TalkBack/Reduce Motion | Flutter/Android manual |
| FOCUS-08 | P-09 | Không thu app list, mặt/video hoặc nhãn cảm xúc/lơ là mặc định | inspection/network/log review |
| AUTH-04 | P-10 | Xóa yêu cầu lặp idempotent, ẩn bảng ngay, trạng thái và xóa local chọn riêng | API/SQL/manual |
| PRIV-01 | P-10 | Rút consent dừng upload/Live/bảng, xóa ảnh tạm/log/caches theo policy | API/security/manual |
| PLAN-01 | P-11 | Nhập/sửa TKB nhiều môn, lịch lặp và ngoại lệ/nghỉ cho đúng ngày theo timezone | domain/widget/API |
| PLAN-02 | P-11 | Chụp TKB gợi parse rồi hủy: không lưu ảnh/bản gợi; xác nhận mới thay lịch | permission/UI/API |
| PLAN-03 | P-11 | Gợi giờ dậy/câu/việc nhưng không xác nhận: không đổi alarm/TKB/task | domain/widget |
| PLAN-04 | P-11 | Tắt quyền nhắc, quiet hours, sửa lịch: không tạo notification trùng/dồn | Android local notification |
| PLAN-05 | P-11 | Thiếu môn/câu phù hợp/offline: hiện lý do, vẫn xem lịch và dừng chuông được | Android integration |
| PROFILE-01 | P-12 | Account mới có empty state, chỉ hiện lịch sử của owner; `uncertain` không tính đúng | widget/API A/B |
| PROFILE-02 | P-12 | Share mặc định tắt; rút share/xóa account ẩn public profile/bảng ngay | API/cache/security |
| PROFILE-03 | P-12 | Tên/avatar pending/reject/appeal, upload sai MIME/EXIF/size, không lộ trước duyệt | API/moderation |
| PROFILE-04 | P-12 | Người khác không thấy giờ dậy/TKB/bài/ảnh/email; đổi account dọn cache hiển thị | API A/B/Flutter |
| ON-01 | P-01 | Cài mới giải thích quyền, chỉ xin khi dùng; Auth lỗi vẫn đặt/dừng alarm local | Flutter/Android manual |
| ON-02 | P-01 | Form email/biệt danh/mật khẩu/xác nhận: sai khớp, yếu, trùng, lỗi mạng có thông báo; không log mật khẩu | widget/Firebase emulator/API |
| ON-03 | P-01 | Email chưa xác minh/draft giữa chừng/restart: đúng bước, công khai bị khóa | Flutter/API integration |
| ON-04 | P-01 | Lớp 10–12 chỉ thấy môn catalog đúng version; môn riêng không có câu scored giả | catalog contract/content review |
| ON-05 | P-01 | AI plan lỗi/không xác nhận: bản cơ bản hoặc empty state, không đổi alarm/task | planner/widget/API |
| ON-06 | P-01 | Logout/đổi account không lộ TKB/draft/avatar người trước, alarm local vẫn sửa/xóa được | Android/API A/B |
| SLEEP-01 | P-13 | Nhiều alarm độc lập, vòng 24h và nhập số giống nhau; lời nhắc thời lượng ngủ không ép | Dart/Kotlin/widget |
| SLEEP-02 | P-13 | OS từ chối DND: chỉ quiet hours thông báo của app, trạng thái UI trung thực | Android thật API/OEM |
| SLEEP-03 | P-13 | Màn khóa mặc định ẩn môn/TKB, full-screen hoặc notification fallback và Dừng local | AD01/04/09 máy thật |
| SLEEP-04 | P-13 | Sai/ảnh mờ/offline/AI timeout: thử lại/Ôn sau/Dừng; không kéo dài chuông tới đúng | Android E2E/API |
| SLEEP-05 | P-13 | MP3 lỗi/không đọc được: fallback âm OS, chuông không mất | Android thật |
| ROOM-01 | P-14 | Chọn solo/AI/bạn, sâu/ngắt quãng, mức nhắc; mic/cam off mặc định | widget/Android |
| ROOM-02 | P-14 | Từ chối/tắt mic/cam giữa phiên: timer/text tiếp tục, indicator tắt thật | Android permission/media |
| ROOM-03 | P-14 | AI Live hết quota/rớt mạng: hạ cấp text/timer, không phát avatar/audio giả | integration/2 mạng |
| ROOM-04 | P-14 | Rời app/tạm nghỉ/rời phòng: không chửi/phạt/giữ app, nhắc chỉ khi opt-in | lifecycle/copy review |
| ROOM-05 | P-14 | Invite TTL, hai account, block/report: người lạ không vào, việc riêng không lộ | API/room security/2 máy |
| ROOM-06 | P-14 | Hỏi ngoài chủ đề/đáp án: AI chuyển nhẹ về mục tiêu, gợi một bước; dừng/nghỉ vẫn được | prompt eval/human review |
| GAME-01 | P-15 | Hai bên cùng câu/rubric/deadline, cần đáp án và lý do; khoanh lụi không kích hoạt skill | server contract/content eval |
| GAME-02 | P-15 | Ảnh mờ/AI uncertain/network fault → void/review, không đổi RP, không tự xử thua | 2 máy/API transaction |
| GAME-03 | P-15 | Submit/action kép/reconnect → HP/event/result/ledger một lần từ server | API PostgreSQL/2 máy |
| GAME-04 | P-15 | Không có câu/rubric đủ chuẩn cùng lớp/môn thì không ghép ranked | catalog/content/matchmaker |
| GAME-05 | P-15 | Tướng/FX/balance/reduced motion/asset quyền được kiểm trước mở game | playtest/art/performance review |

Một TC có thể chưa triển khai vì feature chưa mở; task phải ghi `không áp dụng giai đoạn này` hoặc `chưa chạy`, không xóa dòng để có vẻ pass. Ngưỡng AI/pilot được chốt trước thử người dùng tại [release](02-van-hanh-phat-hanh.md).
