# Đặc tả T009

## Vấn đề

Ảnh người dùng cho thấy sprite trái/phải khác tỉ lệ, chân bị cắt, nhân vật không hướng vào nhau; FX dính lên người sai và dùng chung một hiệu ứng cho nhiều chiêu. Bản web desktop dài, trên điện thoại chưa có khung dọc chơi ngay. Còn thiếu âm thanh, thắng trận, map, avatar, khung rank, mô tả tướng trong app và README/cấu trúc dự án.

## Phạm vi và nguyên tắc

- Sân tập web offline, **mô phỏng**, không được tự xưng PvP online/ranked. Số HP/giáp/khí theo docs/46; server authoritative chỉ là thiết kế tương lai.
- Tài sản per-character; hiệu ứng có origin/target/hit time độc lập khỏi ảnh sprite. Trên mobile, khung trận portrait, đề/nút đọc rõ, không che nhau.
- Chủ dự án xác nhận có quyền đăng công khai ảnh tham chiếu/sprite lên GitHub ngày 12/11/2026; ảnh gốc không vào repo. Art AI nghiên cứu, chưa ghi là được cấp phép thương mại.
- Âm thanh chỉ phát sau tương tác, có nút tắt, tôn trọng giảm chuyển động và tắt tiếng; không áp âm trên báo thức.
- Map là battle plate thẩm mỹ, không giả có di chuyển/collision. Khung rank chỉ cosmetic, không mở ranked.

## Acceptance

| ID | Điều kiện | Hành vi | Test |
| --- | --- | --- | --- |
| AC-01 | Chọn 3 nhân vật trên sân | chân cùng baseline, chiều cao hiển thị cùng chuẩn; hai bên hướng vào nhau; không cắt ở 360×800 và desktop | TC-01 |
| AC-02 | Dùng đánh thường/2 chiêu | projectile từ actor tới target, hit FX đúng target; buff/heal/ward đúng người; FX riêng của từng chiêu/nhân vật | TC-02 |
| AC-03 | Trúng đòn/choáng/thắng | trạng thái/clip/âm thanh đúng, số HP/giáp/ward cập nhật, có bỏ qua FX | TC-03 |
| AC-04 | Điện thoại portrait | xem sân, đề mẫu, nút trả lời và chiêu không cần xoay ngang; điều khiển ≥44 CSS px, không tràn | TC-04 |
| AC-05 | Xem nhân vật | tên/vai/nội tại/2 chiêu, chi phí/đánh đổi/hướng chơi hiện tiếng Việt, không quảng cáo quá lời | TC-05 |
| AC-06 | Xem asset | 1 map portrait, 6 avatar mặc định, 6 tier rank, khung avatar, asset folder từng nhân vật và manifest hợp lệ | TC-06 |
| AC-07 | Mở repo | README có vấn đề/giải pháp/phạm vi thật/điểm mới/cách demo/kiến trúc/roadmap/quyền; docs có cấu trúc repo, asset contract, workflow QA | TC-07 |
| AC-08 | Hoàn tất | test tài sản/logic/build/QA, git diff sạch; push commit lên remote theo yêu cầu nếu cổng phát hành an toàn | TC-08 |

## Quyết định

**Bổ sung 13/11/2026 — lỗi hướng nhìn:** hai ảnh người dùng cho thấy Hàn Bối Pháp đang quay ra ngoài ở slot trái, trong khi Hà Nhân/Tuyệt Đỉnh đúng. Native facing của Han đã được gán nhầm `left`; phải là `right`. Chỉ đổi metadata/lật sprite của Han, giữ anchor/kích thước/đòn và hai tướng còn lại.

| ID | Điều kiện | Hành vi | Test |
| --- | --- | --- | --- |
| AC-09 | Hàn Bối Pháp ở trái hoặc phải | mặt/hướng hành động quay về đối thủ ở cả hai slot; không lật số, map hoặc FX; mọi action cùng quy tắc | TC-09 |

Không thể tạo clip image-to-video thật trong môi trường này (T008 doctor no-route). Sprite nhiều frame hiện là sequence art, cần artist review. Không mô tả nó là motion chuẩn phát hành. Dùng portrait battle plate được crop vào logical stage 360×380 với hai actor đối xứng và anchor theo metadata; sprite vẽ 240×240 nên hình alpha cao khoảng 188 px. Độ lớn được chuẩn hóa theo chiều cao alpha của frame đầu khi build, không theo kích thước PNG nguồn. Tên Hàn Bối Pháp là display name, ID giữ `han_boi_thap` tới khi chốt catalog.
