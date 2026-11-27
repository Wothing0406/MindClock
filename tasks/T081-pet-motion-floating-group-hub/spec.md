# Đặc tả T081 — Pet Cử Động, Floating Mini Pet, Dashboard Gọn & Màn Hình Nhóm

## Acceptance Criteria

- **AC-01 (Pet cử động & tôn trọng Reduce Motion):** `MamPetView` có animation thở/nhún nhẹ (`idle`) và nhảy vui (`happy`), tự dừng chuyển động khi `MediaQuery.disableAnimationsOf(context)` bật.
- **AC-02 (Floating Mini Pet nổi & kéo thả):** `FloatingMiniPetOverlay` hiển thị bong bóng Pet nhỏ ở góc màn hình với `Chuỗi N` + `X/Y`, kéo thả đổi vị trí, có nút thu gọn vào mép, chạm vào mở popup tóm tắt & nút mở `CommitmentGroupScreen`.
- **AC-03 (Màn hình Nhóm chuyên biệt):** `CommitmentGroupScreen` có thanh chuyển tối đa 3 nhóm, Hero Card nền `night` (`#101A30`) với `MamPetView` cử động, badge `Chuỗi N`, thanh tiến độ `Hôm nay X/Y người`, nút Sao chép mã 1 chạm, Mời bạn bè, và modal Tạo nhóm / Nhập mã tách gọn. Không hiển thị ai chưa chăm.
- **AC-04 (Dashboard gọn hơn):** `TodayScreen` hiển thị Đồng hồ, Báo thức kế tiếp, 1 hàng tóm tắt Chuỗi/Nhóm gọn và Lưới 6 tính năng MVP; pass `320dp 200%` không overflow.
