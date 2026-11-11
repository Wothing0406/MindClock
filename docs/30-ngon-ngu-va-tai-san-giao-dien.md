# Ngôn ngữ giao diện và tài sản hình ảnh

## 1. Giọng nói sản phẩm

Nói **chức năng và trạng thái**, không hô khẩu hiệu trong màn dùng hằng ngày. Câu ngắn, động từ cụ thể, đúng khả năng đang có. Slogan chỉ dùng ở pitch/trang giới thiệu nếu cần; không lặp trong app. Không gán nhãn người học là lười, giỏi, thất bại hay “sẽ làm được mọi thứ”. Không gọi phản hồi AI là kết quả chắc chắn khi còn `uncertain`.

| Tình huống | Nên dùng | Tránh |
| --- | --- | --- |
| Trang chủ | `Báo thức tiếp theo: 06:30` · `Hôm nay có Toán` | `Đánh thức thiên tài trong bạn` |
| Mời học | `Thử một câu Toán` | `Chinh phục thử thách trí tuệ đỉnh cao` |
| Bắt đầu | `Bắt đầu làm bài` | `Tôi nhất định sẽ làm được` |
| Chụp | `Chụp bài làm` · `Xem lại ảnh` · `Gửi bài` | `AI quét và hiểu mọi nét chữ` |
| Đúng | `Bài làm đúng. Xem cách giải.` | `Bạn là học bá!` |
| Sai | `Bước này cần xem lại.` | `Bạn thất bại rồi` |
| Chưa rõ | `Ảnh chưa đủ rõ để chấm. Chụp lại hoặc nhập đáp án.` | `AI đã chấm chính xác` |
| Mất mạng | `Chưa gửi được bài. Bạn vẫn có thể dừng chuông.` | `Có lỗi xảy ra` |
| Bảng | `Bảng Toán tuần này` · `Điểm được cập nhật lúc 08:10` | `Top siêu chiến thần` |
| Trận | `Giao hữu không tính hạng` | `Đấu sống còn` |

**Mẫu viết:** nhãn nút 2–4 từ, thông báo một ý, lỗi gồm vấn đề + bước xử lý. Nếu tính năng chưa chạy, gắn `Bản xem thử` hoặc `Dữ liệu mẫu` ngay tại vùng liên quan. Kiểm tra câu chữ với học sinh Việt lớp 9 và 12; không giả định mọi bạn hiểu thuật ngữ RPG/ELO.

## 2. Icon, hình động và công nghệ

React là **thư viện giao diện web**, không phải định dạng nhân vật hay icon. App mobile đã chọn Flutter; chỉ dùng React nếu sau này làm dashboard/web riêng. GIF là định dạng ảnh động nhưng thường khó điều khiển trạng thái/tạm dừng và không phải lựa chọn mặc định cho app. Dùng SVG/vector cho icon tĩnh; ảnh WebP/PNG do đội thiết kế cho nhân vật; một chuỗi frame ngắn hoặc animation có thể tạm dừng cho khoảnh khắc hoàn thành. Đo hiệu năng trên máy thật theo [hướng dẫn Flutter](https://docs.flutter.dev/perf/rendering-performance), đặc biệt ở profile mode.

**Không dùng emoji hệ thống trong UI cuối hoặc prototype trình giám khảo:** chúng đổi hình theo OS, không cùng phong cách và có thể bị đọc không đúng bởi trợ năng. Dùng một bộ icon nét có licence và sprite nhân vật gốc. Avatar SVG trong [demo](../demo/index.html) hiện là placeholder; chưa phải sprite 2D đã duyệt. Khung rank là vector tĩnh; chỉ một animation ngắn khi lên bậc, có đường tắt khi giảm chuyển động.

## 3. Kiểm duyệt trước khi nhận asset

- Có file nguồn, tên tác giả, licence/quyền sử dụng, phiên bản và kích thước xuất.
- Không sao chép nhân vật game/meme; không dùng logo Google/Gemini làm icon nút chấm.
- Ở 48 px vẫn phân biệt được nhân vật/khung rank; ở nền sáng/tối vẫn rõ.
- Ảnh/animation có bản tĩnh dự phòng, không tải từ mạng lúc chuông reo.
- Animation tạm dừng khi tab ẩn/app background; không flash hoặc lặp vô hạn trên màn báo thức.

Quy chuẩn token, khung rank và ngân sách animation chi tiết ở [docs/27](27-quy-chuan-giao-dien-va-figma.md).

