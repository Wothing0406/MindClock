# Đăng ký, đăng nhập và vòng đời tài khoản

**Quyết định MVP:** báo thức và câu hỏi mẫu dùng được **không cần tài khoản**. Khi muốn đồng bộ tiến bộ hoặc thi online, người dùng tạo tài khoản bằng **email + mật khẩu trong app** qua Firebase Authentication. Không yêu cầu số điện thoại, tên thật, trường, địa chỉ hay ngày sinh đầy đủ. Không có paywall. Firebase hỗ trợ [email/password trong Flutter](https://firebase.google.com/docs/auth/flutter/password-auth). Social login là giai đoạn sau; nếu thêm Google làm đăng nhập chính trên iOS, rà soát [quy tắc đăng nhập tương đương của Apple](https://developer.apple.com/app-store/review/guidelines/).

## 1. Các luồng

| Màn | Người dùng làm gì | Bắt buộc? | Lối thoát/lỗi |
| --- | --- | --- | --- |
| Chào mừng | Chọn `Dùng thử không cần tài khoản` hoặc `Tạo tài khoản` | Không | Trở lại |
| Khởi tạo học tập | Chọn khối, môn, giờ; lưu trên máy | Khối/môn có thể bỏ qua | Sửa sau |
| Cổng đồng bộ | Khi bấm `Đồng bộ`/`Đấu trường`, giải thích lợi ích và dữ liệu lên server | Có nếu dùng online | `Để sau` |
| Đăng ký | Email, mật khẩu, xác nhận mật khẩu; xem chính sách và điều khoản | Có khi tạo account | Đăng nhập/Quên mật khẩu |
| Xác minh email | Mở link email, quay lại app | Có trước khi thi/bảng công khai | Gửi lại có giới hạn, đổi email |
| Hồ sơ tối thiểu | Biệt danh, khối, chọn avatar; xác nhận nhóm tuổi theo ngưỡng chính sách | Có trước khi thi | Chỉ học cá nhân |
| Đồng ý thi đấu | Chọn môn, biệt danh hiển thị, phạm vi bảng; đồng ý riêng | Có trước khi vào bảng | Tiếp tục học riêng |

Đăng nhập: email/mật khẩu → Firebase ID token → backend xác minh token → kiểm tra trạng thái tài khoản và quyền → tạo profile tối thiểu nếu chưa có. Không cho client tự ghi quyền `teacher`, `parent`, `admin`. Quên mật khẩu bằng email Firebase; giới hạn gửi lại và thông báo trung tính để tránh dò tài khoản. Không tự tạo tài khoản bằng email của phụ huynh; quyền giám hộ là quan hệ riêng cần xác minh trong pilot.

## 2. Ràng buộc đầu vào và tài khoản

- Email chuẩn hóa chữ thường cho tra cứu, không hiện trên leaderboard. Mật khẩu không lưu trong PostgreSQL/backend/log; Firebase Auth quản lý. Quy tắc độ dài và chống mật khẩu yếu phải dùng chính sách của Auth tại thời điểm coding, không tự cắt hoặc log chuỗi nhập.
- Biệt danh 3–20 ký tự, chỉ ký tự chữ/số/khoảng trắng đơn giản; lọc tên xúc phạm, thông tin liên hệ và tên thật tự nhận diện; cho sửa và có nút báo cáo. Không lấy biệt danh từ email.
- Khối chỉ dùng để chọn nội dung/ghép trận; không công khai trường/lớp cụ thể. Chỉ một tài khoản thi đấu đang hoạt động trên một thiết bị tại một thời điểm là quy tắc chống lạm dụng đề xuất, cần test trải nghiệm đổi máy.
- Xác minh email trước leaderboard; giới hạn đăng ký từ cùng thiết bị/IP bằng dịch vụ và backend, không chặn hàng loạt học sinh dùng chung Wi-Fi trường.
- Trẻ chưa đủ điều kiện đồng ý: chỉ dùng chế độ cục bộ/riêng tư. Ngưỡng tuổi, người đồng ý và văn bản cần chuyên gia rà soát trước pilot; app không suy diễn pháp lý từ khối lớp.
- Đồng ý chính sách cơ bản tách khỏi tùy chọn ảnh AI, thi đấu, thông báo và chia sẻ với giáo viên/phụ huynh. Không dùng checkbox gom tất cả.

## 3. Quản lý tài khoản

`Tôi → Cài đặt → Tài khoản & dữ liệu`: xem email đã xác minh, đổi mật khẩu/email theo Firebase, đăng xuất, tải dữ liệu cá nhân, rút khỏi bảng, xóa tài khoản. Đăng xuất không làm mất báo thức cục bộ; cảnh báo rõ lịch học chưa đồng bộ trên máy khác. Xóa tài khoản cần xác thực lại, xác nhận lần cuối, dừng phiên/ẩn bảng ngay, xóa dữ liệu theo [chính sách](25-bao-mat-va-du-lieu.md), rồi xóa Firebase Auth. Apple yêu cầu app có tạo tài khoản phải [cho bắt đầu xóa ngay trong app](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion/).

## 4. API và test để coding

**API chuẩn theo [docs/07](07-hop-dong-api-va-ai.md):** `GET /v1/me`, `PATCH /v1/me`, `POST /v1/me/export`, `GET /v1/me/exports/{id}`, `DELETE /v1/me` (202 tạo yêu cầu xóa), `GET /v1/me/delete-status`; không dùng các đường `PUT /me/profile` hoặc `POST /me/delete-request` cũ. Firebase SDK xử lý đăng ký/đăng nhập/reset, backend chỉ nhận ID token. Test: người chưa đăng nhập dùng chuông local; token sai/expired bị 401; email chưa xác minh không vào bảng; user A không đọc user B; đăng xuất không hủy chuông; xóa không để tên cũ trên leaderboard; retry xóa idempotent; dữ liệu local được xóa khi người dùng chọn `Xóa cả dữ liệu trên máy`.

**Máy dùng chung:** khi đăng xuất/đổi tài khoản, app không hiển thị lịch, bài nháp, điểm, thông báo chi tiết của tài khoản trước cho người sau. Báo thức local đã đặt vẫn tồn tại cho đến khi chủ máy xác nhận sửa/xóa; UI phải hiện rõ chuông nào còn hoạt động mà không tiết lộ lịch học cá nhân trên màn khóa. Bản nháp chữ offline gắn local profile, xóa sau 24 giờ hoặc khi người dùng chọn xóa; không tự chuyển sang tài khoản mới. Kiểm thử trên một máy với hai tài khoản và khách local.

