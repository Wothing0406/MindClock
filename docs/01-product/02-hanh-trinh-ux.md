# Hành trình và trạng thái giao diện

**Nền tảng:** Flutter Android, dọc, tiếng Việt. [PRD](01-prd.md) quyết định hành vi; [design system](03-he-thiet-ke.md) quyết định thị giác; [Android alarm](../02-engineering/02-bao-thuc-android.md) quyết định khả năng OS. Màn web cũ không là tham chiếu runtime. Luồng này là sản phẩm dùng lâu dài, không phải kịch bản demo.

## Bản đồ màn hình P0

```text
Chào mừng → Giải thích quyền → Đăng ký/Đăng nhập (local alarm nếu offline)
→ Xác minh email → Lớp 10/11/12 → Môn/tổ hợp → Mức tự đánh giá
→ Avatar/biệt danh → Kế hoạch nháp AI + rule → Xác nhận → Hôm nay
Hôm nay ┬─ Đồng hồ: nhiều chuông → lịch ngủ → âm/quyền → thử chuông
        ├─ Lịch: TKB → việc hôm nay → thông báo
        ├─ Học: chọn một mình/AI/bạn → việc/môn/nhịp → phòng → tổng kết
        ├─ Đấu trường: giao hữu → trận → kết quả (khi feature mở)
        └─ Tôi: hồ sơ/rank/lịch sử/bạn bè/quyền/đăng xuất/xóa
OS alarm → màn khóa/notification → Dừng khẩn cấp | Mở app → mở màn 6–12 giây → câu bắt buộc để hoàn thành → phản hồi → Hôm nay
```

Happy path có tài khoản và hồ sơ học; nếu mạng/Auth lỗi, `Chỉ dùng báo thức trên máy` vẫn đặt/dừng chuông được. Không đòi quyền camera/mic/DND ở màn mở đầu. Đấu trường chỉ hiện như tính năng khả dụng khi backend/câu/chấm đạt; không gắn tab P0 giả.

## Các luồng chi tiết

| Luồng | Bước và nội dung chính | Đường lỗi/thoát |
| --- | --- | --- |
| Thiết lập lần đầu | Giải thích quyền; email/biệt danh/mật khẩu/xác nhận, verify; lớp 10–12, môn theo catalog, tự đánh giá, avatar; xem/sửa/xác nhận plan nháp. TKB có thể nhập sau. | `Chỉ dùng báo thức` khi Auth/mạng lỗi; khôi phục draft sau kill; email chưa xác minh không vào tính năng công khai. [Chi tiết](07-dang-ky-va-khoi-tao-lo-trinh.md). |
| Lưu báo thức | Danh sách nhiều chuông, vòng 24h ngủ/thức có nhập số tương đương, ngày lặp/âm/rung/mode/lần reo; `Lưu` chỉ hiện `Đã sẵn sàng` sau OS schedule. Lịch ngủ cảnh báo thời lượng chung; DND bật theo quyền/OS và xác nhận. | Quyền bị từ chối: fallback + `Cần quyền`; DND không bật thì chỉ quiet hours của app. MP3 lỗi có âm OS. [Chi tiết](09-giac-ngu-va-bao-thuc.md). |
| Chuông reo | Nền tối ít chói, giờ, `Mở câu`, Dừng khẩn cấp cố định. Màn khóa mặc định ẩn môn/TKB riêng tư; trong app vào ngay mở màn gắn với câu rồi tới bài, không có màn hỏi đồng ý hay thao tác chụp nước/điểm sáng. Chế độ thường có Hoãn; thử thách không Hoãn. | Mất mạng/câu: `Ôn sau`; Dừng luôn dùng được. Full-screen intent/notification tùy OS, không tự mở khóa. |
| Mở màn câu sáng | Một cảnh 6–12 giây bằng hình/hoạt ảnh nhẹ hoặc bản chữ tương đương; dừng ở câu hỏi liên quan trực tiếp nội dung sắp ôn. `Bỏ qua mở màn` đi thẳng đến **cùng câu hỏi**, không cấp điểm khi chỉ xem. | Reduce Motion/chưa tải asset: bản chữ tĩnh; không chờ mạng; khi lỗi vẫn mở câu. |
| Làm bài | Câu, thời gian tham khảo (không đếm ép), đáp án và bước giải chữ; `Chụp bài` tùy chọn → xem ảnh → xác nhận gửi. | Camera từ chối/ảnh mờ: chuyển nhập chữ. API timeout: giữ bài nháp local nếu người dùng chọn, có `Thử lại` hoặc hoàn thành không chấm. |
| Phản hồi | `Đúng`, `Cần xem lại`, `Chưa đủ chắc để chấm`; chỉ ra bước có căn cứ và gợi ý tiếp. Cho thử lại, báo chấm sai. `incorrect` rõ lần 3 mở gợi ý; lần 5 mở `Bỏ lượt`. | Không có rubric/AI mâu thuẫn → `uncertain`; không tăng số lần sai. Bỏ lượt không EXP/chuỗi; Dừng khẩn cấp vẫn luôn có. |
| Không gian học | Chọn `Một mình`/`MindClock AI`/`Mời bạn`, môn/việc, nhịp sâu/ngắt quãng, mức nhắc; mic/cam off trước khi vào phòng. Timer + avatar AI có nhãn rõ, `Hỏi`, `Tạm nghỉ`, `Rời phòng`. | Rời app/khóa màn: timer local tiếp tục theo cấu hình, quay lại hỏi tiếp tục; không phạt. Live/media lỗi hạ cấp text/timer. [Chi tiết](08-phong-hoc-ai-va-ban-be.md). |
| Hồ sơ/xã hội | Avatar/biệt danh, môn, tiến độ, lịch sử alarm riêng tư, lịch sử đấu/rank nếu có; kết bạn hai chiều/mời phòng. | Đăng xuất giữ alarm local và xóa cache học theo account; block/report/opt-out; quên mật khẩu, xóa tài khoản rõ đường đi. |

## Mẫu nội dung `vi-VN`

| Trạng thái | Chuỗi hiển thị | Hành động |
| --- | --- | --- |
| Lưu local, OS chưa xác nhận | `Đã lưu trên máy. Cần cấp quyền để chuông reo đúng giờ.` | `Kiểm tra quyền` |
| OS đã lập lịch | `Báo thức tiếp theo: 06:00, Thứ hai.` | `Thử chuông` |
| Offline | `Bạn vẫn có thể dừng chuông và ôn câu đã tải.` | `Tiếp tục` |
| AI đang chấm | `Đang xem bài làm…` | Dừng khẩn cấp vẫn luôn dùng được |
| `uncertain` | `Chưa đủ chắc để chấm bài này.` | `Nhập lại bằng chữ` / `Ôn sau` |
| Sai rõ lần 3 | `Thử xem lại bước đầu tiên.` | `Xem gợi ý` |
| Sai rõ lần 5 | `Bạn có thể ôn lại câu này sau. Lượt sáng hôm nay sẽ không được tính.` | `Bỏ lượt` / `Thử tiếp` |
| Bỏ lượt | `Lượt sáng đã kết thúc. Không có EXP hoặc ngày chuỗi mới.` | `Xem lời giải` / `Hôm nay` |
| Không có câu môn | `Môn này chưa có câu đã duyệt cho hôm nay.` | `Chọn môn khác` / `Ôn sau` |
| Live chưa mở/hết quota | `Bạn có thể tiếp tục học bằng chữ và đồng hồ.` | `Tiếp tục` |
| DND chưa cấp | `MindClock chỉ tắt nhắc của ứng dụng. Bạn có thể bật Không làm phiền trong Cài đặt.` | `Mở cài đặt` |
| Rời phòng | `Bạn muốn tiếp tục phiên học?` | `Tiếp tục` / `Kết thúc` |

Không dùng câu kiểu “phá đảo”, “AI biết hết”, “bắt buộc dậy”, “không thể tắt” trong luồng hằng ngày. Humor nhẹ ở avatar/phòng tự nguyện, không trong lỗi, quyền, chấm sai hay Dừng khẩn cấp. Mức nhắc `Nghiêm túc` không dùng lời xúc phạm.

## UI states bắt buộc cho mỗi màn

`initial/loading/ready/empty/offline/permission_denied/timeout/error/success` theo chức năng; màn báo thức còn `saved_local/scheduled_os/synced_server/ringing/dismissed`. Nút khi loading không tạo request kép; Dừng khẩn cấp không bị disabled bởi loading. Navigation phải khôi phục khi app bị kill, màn hẹp/bàn phím mở, TalkBack và chữ 200%. Test liên kết ở [quality](../03-quality/01-ke-hoach-kiem-thu.md).
