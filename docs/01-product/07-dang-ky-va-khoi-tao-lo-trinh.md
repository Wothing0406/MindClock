# Đăng ký, hồ sơ học và khởi tạo lộ trình

**Nguồn hành vi:** [PRD](01-prd.md). Đây là happy path đầu tiên cho học sinh THPT lớp 10–12. Báo thức và Dừng khẩn cấp vẫn hoạt động cục bộ khi chưa đăng nhập; mọi mục tiêu AI/đồng bộ cần tài khoản và đồng ý phù hợp. Không gọi bản kế hoạch đầu là chẩn đoán năng lực.

## Hành trình màn hình

```text
Mở app → Giới thiệu ngắn → Giải thích quyền → Đăng ký/Đăng nhập
→ Xác minh email → Chọn lớp 10/11/12 → Chọn môn theo catalog → Tự đánh giá từng môn
→ Chọn avatar/biệt danh → Xem bản kế hoạch nháp → Xác nhận → Dashboard Hôm nay
```

Màn giải thích quyền liệt kê chuông chính xác, thông báo, màn hình khóa, DND, camera/mic theo tác dụng. **Không bật hàng loạt hộp thoại OS ở lần mở đầu.** Quyền chuông hỏi lúc tạo alarm, thông báo lúc bật nhắc, DND lúc bật lịch ngủ, camera/mic lúc vào tính năng. Cho `Để sau`; phần thiếu quyền có nhãn `Cần bật` và đường đến cài đặt. Nếu thiếu mạng/Auth, người dùng vẫn vào `Chỉ dùng báo thức trên máy`, sau đó có thể chuyển sang tài khoản mà không mất cấu hình chuông.

## Đăng ký và trạng thái tài khoản

Form gồm `Email`, `Biệt danh`, `Mật khẩu`, `Xác nhận mật khẩu`, ô đồng ý điều khoản/dữ liệu theo phiên bản và xác nhận nhóm tuổi phù hợp. Không bắt email phải thuộc `gmail.com`, không thu tên pháp lý. Hiện/ẩn mật khẩu, giải thích độ mạnh theo chính sách Auth; kiểm hai trường khớp phía client, server/Auth vẫn xác minh. Tạo tài khoản Firebase Email/Password, gửi email xác minh; backend chỉ nhận ID token đã xác minh và ánh xạ `auth_subject`, không lưu mật khẩu. Có `Đăng nhập`, `Quên mật khẩu`, `Gửi lại email`, `Đổi email`, `Đăng xuất`, `Xóa tài khoản`. Google Sign-In là tùy chọn tương lai, không là điều kiện cho P0. [Tài khoản/quyền](04-tai-khoan-quyen-rieng-tu.md), [Firebase Email/Password](https://firebase.google.com/docs/auth/flutter/password-auth), [email verification](https://firebase.google.com/docs/auth/flutter/manage-users).

Máy trạng thái: `anonymous_local → registering → pending_email_verification → profile_incomplete → plan_draft → ready`. Token hết hạn đưa về đăng nhập mà **không** hủy alarm local. Draft onboarding lưu tối thiểu theo user ID, khôi phục đúng bước sau kill/restart; logout/đổi user không lộ draft trước. Email trùng, mật khẩu yếu, mất mạng, email chưa xác minh và tài khoản bị xóa đều có thông báo tiếng Việt ngắn, không hiện thông tin thừa về tài khoản khác.

## Chọn lớp, môn, trình độ

Đầu tiên chọn `Lớp 10`, `Lớp 11`, `Lớp 12`. Catalog môn/chuyên đề có `curriculum_version`, hiệu lực, nguồn Bộ GD&ĐT và reviewer; UI chỉ hiện môn hợp lệ theo lớp/chương trình, phân biệt môn bắt buộc/lựa chọn/tự chọn và **môn học thực tế của người dùng**. User có thể bỏ qua môn không học, chọn tổ hợp thi và thêm môn tự học; không ép 3 môn mặc định cho mọi học sinh. Cho đổi lớp/môn ở hồ sơ, với xác nhận tác động lên TKB/câu/ghép trận. Không tự suy “lực học” từ điểm số hoặc diện mạo.

Từng môn được chọn có mức tự đánh giá `Mới bắt đầu / Cơ bản / Đang ôn thi / Muốn thử thách`, mục tiêu nhỏ và số buổi/tuần tùy chọn. Đây là điểm khởi đầu, không phải điểm năng lực; câu đầu dễ, điều chỉnh sau các bài được chấm chắc và phản hồi người dùng. Khi catalog thiếu môn/chủ đề, cho `Thêm môn vào lịch` nhưng ghi `Chưa có câu ôn được duyệt`, không sinh câu scored. [Catalog kỹ thuật](../02-engineering/10-catalog-chuong-trinh-va-ke-hoach.md) và [chương trình phổ thông Bộ GD&ĐT](https://moet.gov.vn/content/vanban/Lists/VBPQ/Attachments/1483/vbhn-ttu-322018-202021-132022-ttbgddt.pdf).

## Avatar và bản kế hoạch đầu

Chọn một trong các avatar mặc định gốc, biệt danh, màu khung cơ bản; upload ảnh riêng là bước tùy chọn sau consent/moderation. Avatar profile không là tướng PvP. Sau đó rule engine dựng **kế hoạch nháp** từ lớp/môn/mục tiêu/TKB nếu có: tối đa 3 việc hôm nay, một buổi ôn 10–25 phút, câu đã duyệt phù hợp, thời gian linh hoạt. Gemini có thể diễn đạt/gợi thứ tự với lý do và nhãn `Gợi ý từ MindClock`; không bịa lịch/chương trình/đánh giá năng lực. Người dùng sửa hoặc `Bỏ qua kế hoạch`, xác nhận mới lưu. Nếu AI lỗi/quota: bản rule-based vẫn có, hiện rõ `Chưa có gợi ý AI`.

## Acceptance

| ID | Khi | Phải xảy ra |
| --- | --- | --- |
| ON-01 | Cài mới, chưa cấp quyền | Xem giải thích, đăng ký được; quyền OS hỏi đúng lúc dùng; có local alarm fallback. |
| ON-02 | Email hợp lệ, hai mật khẩu khác nhau hoặc email trùng | Không tạo profile sai; lỗi rõ, không log mật khẩu. |
| ON-03 | Email chưa xác minh hoặc mạng đứt ở giữa | Giữ draft đúng user; giới hạn tính năng công khai; alarm local vẫn chạy. |
| ON-04 | Chọn lớp 10/11/12 và môn | Catalog version đúng lớp, chọn được môn học thật/tổ hợp; thiếu pool hiện lý do. |
| ON-05 | AI kế hoạch lỗi hoặc user không xác nhận | Dashboard dùng kế hoạch cơ bản hoặc trống có hướng dẫn; không tự bật alarm/nhắc. |
| ON-06 | Logout/đổi account | Draft/TKB/ảnh/avatar riêng không lộ cho account khác; alarm local còn và sửa/xóa được. |

THCS, sinh viên, phụ huynh/giáo viên và Google Sign-In là release sau; catalog/schema được thiết kế mở rộng nhưng UI đầu không hứa đủ nội dung mọi lớp.
