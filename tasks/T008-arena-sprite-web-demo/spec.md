# Đặc tả T008

## Kết quả mong muốn

Docs/46 mới mô tả kit bằng chữ. Người dùng cần xem tạo hình theo ba ảnh và kích hoạt từng hành động, hiệu ứng trong trình duyệt để duyệt hướng mỹ thuật và nhịp trận.

## Phạm vi

- Ba nhân vật Hà Nhân, Hàn Bối Pháp, Tuyệt Đỉnh; asset 2D; frame/pose và FX web; điều khiển trình diễn mọi trạng thái, nội tại, hai chiêu; tài liệu manifest/quy trình.
- Ngoài phạm vi: PvP online, chấm bài Gemini, rank, APK, quyền thương mại.
- Ảnh tham chiếu có nguồn/quyền chưa rõ; không đưa ảnh gốc vào repo. Asset phát sinh chỉ dùng nghiên cứu/demo đến khi rà quyền.
- Nguồn luật: `docs/46-pvp-ba-nhan-vat-luat-ui-asset-networking.md` §§2–5.

## Acceptance

| ID | Điều kiện | Hành vi | Test |
| --- | --- | --- | --- |
| AC-01 | Mở web demo | Chọn đúng 3 nhân vật theo thứ tự ảnh; sprite, tên, vai, kit hiện | TC-01 |
| AC-02 | Kích hoạt mỗi hành động | Idle, đánh thường, chiêu 1/2, nội tại, bị đánh, choáng, hồi phục, thắng có hình/FX và chữ | TC-02 |
| AC-03 | Kích hoạt damage/heal/guard | HP, giáp, chắn thay đổi theo luật minh họa, clamp, đặt lại | TC-03 |
| AC-04 | Mobile/chữ lớn/reduced motion | Điều khiển dùng được, không flash/emoji | TC-04 |
| AC-05 | Mở tài liệu | Prompt, manifest, nguồn, cách chạy, giới hạn và map chiêu→FX | TC-05 |
| AC-06 | Xem đòn và trạng thái trên sân | Mỗi nhân vật có 3 chuỗi đòn nhiều frame và 3 trạng thái; hiệu ứng hồi/chắn/mực/choáng/va chạm là asset riêng; có clip MP4 review | TC-06 |

## Hợp đồng và quyết định

Demo là mô phỏng cục bộ, không gọi mạng/lưu tiến độ/chấm bài. Client demo không có thẩm quyền trận thật. Choáng chỉ preview visual, **không** áp luật bỏ lượt trong docs/46. Người dùng gọi ảnh 2 là **Hàn Bối Pháp**, docs/46 là **Hàn Bối Tháp**: dùng tên hiển thị mới trong demo, tạm giữ ID `han_boi_thap` cho kit; cần chốt trước backend thật. Tạo diễn giải nguyên bản từ nét tổng quát, không sao chép frame hay lưu ảnh gốc.

Phản hồi người dùng sau bản key pose: chuyển động CSS/ảnh đứng chưa đạt. Bổ sung sequence nhiều frame thực và VFX ảnh riêng; không tuyên bố là clip image-to-video vì môi trường không có route.
