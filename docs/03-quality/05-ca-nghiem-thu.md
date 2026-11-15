# Ca nghiệm thu gắn PRD

Đây là **thiết kế test**. Chỉ ghi `pass` trong `tasks/TNNN/tests.md` sau khi chạy với lệnh/máy/ngày. ID trong [PRD](../01-product/01-prd.md) dẫn đến bảng này; các ca Android AD01–AD09 chi tiết ở [test plan](01-ke-hoach-kiem-thu.md). Khi thêm yêu cầu mới, thêm AC/TC tương ứng trước code.

| ID | Liên kết PRD | Kịch bản và expected | Tầng |
| --- | --- | --- | --- |
| UX-01 | P-01 | Cài mới, chọn `Dùng thử`, bỏ qua khối/môn; đặt chuông được, không yêu cầu Auth | Flutter widget + Android manual |
| AUTH-01 | P-01 | Guest local không gọi `/v1/me`; sau đăng nhập token hợp lệ tạo profile, token sai/hết hạn 401 | Flutter/API contract |
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
| AI-01 | P-06 | Gemini/validator bất đồng, ảnh mờ, timeout → uncertain, không phạt/không cấp XP sai | AI eval/API |
| AI-02 | P-07 | Socratic không trả đáp án cuối trước nỗ lực, không lộ rubric qua field/lỗi | prompt injection + contract |
| DATA-01 | P-08 | XP/streak do server, dữ liệu tiến độ riêng, giờ dậy không vào rating | SQL/API A/B |
| FOCUS-01 | P-09 | Timer chạy offline, pause/resume/finish | Dart unit/widget |
| FOCUS-02 | P-09 | Background/kill/restart không tạo phạt hoặc kẹt phiên | Android lifecycle |
| FOCUS-03 | P-09 | Finish retry idempotent, API lỗi vẫn thoát được | Flutter/API contract |
| FOCUS-04 | P-09 | Camera/mic opt-in, từ chối vẫn học được | permission/manual |
| FOCUS-05 | P-09 | Rời app không khóa app khác hoặc trừ điểm | Android manual |
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

Một TC có thể chưa triển khai vì feature chưa mở; task phải ghi `không áp dụng giai đoạn này` hoặc `chưa chạy`, không xóa dòng để có vẻ pass. Ngưỡng AI/pilot được chốt trước thử người dùng tại [release](02-van-hanh-phat-hanh.md).
