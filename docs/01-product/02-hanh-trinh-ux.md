# Hành trình và trạng thái giao diện

**Nền tảng:** Flutter Android, dọc, tiếng Việt. [PRD](01-prd.md) quyết định hành vi; [design system](03-he-thiet-ke.md) quyết định thị giác; [Android alarm](../02-engineering/02-bao-thuc-android.md) quyết định khả năng OS. Màn web cũ không là tham chiếu runtime.

## Bản đồ màn hình P0

```text
Chào mừng → Dùng thử / Đăng nhập
          → Thiết lập nhanh (khối, môn, TKB, âm/giờ; có Để sau)
          → Hôm nay ┬─ Báo thức: danh sách → tạo/sửa → quyền → thử chuông
                    ├─ Luyện tập: câu → nhập đáp án/bước giải → phản hồi → ôn lại
                    ├─ Không gian học: chọn việc → timer → kết thúc/gợi ý
                    └─ Tôi: hồ sơ local/tài khoản, quyền, dữ liệu, trợ giúp
OS alarm → màn reo → Dừng khẩn cấp | Mở câu → làm bài → phản hồi → Hôm nay
```

Không ép đăng nhập để đặt chuông. Đấu trường xuất hiện như mục tự nguyện **sau** khi backend/câu/chấm đạt; không gắn vào tab P0 nếu chưa có hành vi thật.

## Các luồng chi tiết

| Luồng | Bước và nội dung chính | Đường lỗi/thoát |
| --- | --- | --- |
| Thiết lập lần đầu | Chọn lớp/khối, môn/tổ hợp, môn ưu tiên, thời khóa biểu (nhập tay trước; ảnh/import là task sau), giờ dậy. Xem phép tính gợi ý giờ: giờ tiết đầu − di chuyển − chuẩn bị − đệm; **người dùng xác nhận**. | `Để sau` và `Chỉ báo thức`; nếu môn không có câu đã duyệt, giải thích và dùng chuông thường/ôn sau. |
| Lưu báo thức | Giờ lớn, ngày lặp, âm/rung, thường/thử thách, lần reo kế tiếp, quyền exact/notification/full-screen. `Lưu` chỉ hiện `Đã sẵn sàng` sau OS schedule thành công. | Quyền bị từ chối: `Mở cài đặt`/fallback notification và trạng thái `Cần quyền`; không giả đã đặt. `Thử chuông` không tự ghi XP. |
| Chuông reo | Nền tối ít chói, giờ, môn/câu ngắn nếu có, `Mở câu`, Dừng khẩn cấp cố định. Chế độ thường có Hoãn; thử thách không Hoãn. | Mất mạng/câu: `Ôn sau`; Dừng luôn dùng được. Hệ thống OS vẫn có giới hạn nút/notification; không che giấu. |
| Làm bài | Câu, thời gian tham khảo (không đếm ép), đáp án và bước giải chữ; `Chụp bài` tùy chọn → xem ảnh → xác nhận gửi. | Camera từ chối/ảnh mờ: chuyển nhập chữ. API timeout: giữ bài nháp local nếu người dùng chọn, có `Thử lại` hoặc hoàn thành không chấm. |
| Phản hồi | `Đúng`, `Cần xem lại`, `Chưa đủ chắc để chấm`; chỉ ra bước có căn cứ và gợi ý tiếp. Cho thử lại, báo chấm sai. | Không có rubric/AI mâu thuẫn → `uncertain`; không trừ điểm. Nếu đã dừng khẩn cấp, không ép quay lại. |
| Không gian học | Chọn một việc, 10/25/45 phút hoặc tùy chỉnh, `Bắt đầu`, `Tạm dừng`, `Nghỉ`, `Kết thúc`; gợi ý AI chỉ khi hỏi. | Rời app/khóa màn: timer cục bộ tiếp tục hoặc tạm theo cấu hình; quay lại nhắc nhẹ, không phạt/khóa app. Camera/mic off mặc định. |
| Tài khoản | Dùng khách → cổng đồng bộ giải thích dữ liệu → email/password → xác minh khi cần → consent riêng → hồ sơ. | Đăng xuất giữ alarm local và xóa cache cá nhân trên máy dùng chung; quên mật khẩu, xóa tài khoản, rút bảng rõ đường đi. |

## Mẫu nội dung `vi-VN`

| Trạng thái | Chuỗi hiển thị | Hành động |
| --- | --- | --- |
| Lưu local, OS chưa xác nhận | `Đã lưu trên máy. Cần cấp quyền để chuông reo đúng giờ.` | `Kiểm tra quyền` |
| OS đã lập lịch | `Báo thức tiếp theo: 06:00, Thứ hai.` | `Thử chuông` |
| Offline | `Bạn vẫn có thể dừng chuông và ôn câu đã tải.` | `Tiếp tục` |
| AI đang chấm | `Đang xem bài làm…` | Dừng khẩn cấp vẫn luôn dùng được |
| `uncertain` | `Chưa đủ chắc để chấm bài này.` | `Nhập lại bằng chữ` / `Ôn sau` |
| Sai rõ lần 3 | `Thử xem lại bước đầu tiên.` | `Xem gợi ý` |
| Không có câu môn | `Môn này chưa có câu đã duyệt cho hôm nay.` | `Chọn môn khác` / `Ôn sau` |

Không dùng câu kiểu “phá đảo”, “AI biết hết”, “bắt buộc dậy”, “không thể tắt” trong luồng hằng ngày. Humor chỉ ở asset/game tự nguyện, không trong lỗi, quyền, chấm sai hay Dừng khẩn cấp.

## UI states bắt buộc cho mỗi màn

`initial/loading/ready/empty/offline/permission_denied/timeout/error/success` theo chức năng; màn báo thức còn `saved_local/scheduled_os/synced_server/ringing/dismissed`. Nút khi loading không tạo request kép; Dừng khẩn cấp không bị disabled bởi loading. Navigation phải khôi phục khi app bị kill, màn hẹp/bàn phím mở, TalkBack và chữ 200%. Test liên kết ở [quality](../03-quality/01-ke-hoach-kiem-thu.md).
