# Bàn giao nhiệm vụ T081

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  1. Nâng cấp `MamPetView` có animation cử động (`idle` thở/nhún nhẹ, `happy`/`celebrate` nhảy vui, tự dừng khi bật Reduce Motion).
  2. Tạo `FloatingMiniPetOverlay` gắn vào `MindClockShellScreen` (bong bóng Pet nổi kéo thả tự do, hiện `Chuỗi N` + `X/Y`, chạm vào mở popup nhanh, có nút thu gọn vào mép).
  3. Tạo màn hình Nhóm chuyên biệt `CommitmentGroupScreen` theo phong cách "bình minh trên trang vở" + Hero thẻ `night` `#101A30` (thanh chuyển tối đa 3 nhóm, copy mã 1 chạm, mời bạn bè, modal Tạo nhóm / Nhập mã tách gọn).
  4. Nối `TodayPetCard` mở `CommitmentGroupScreen` thay cho bottom sheet cũ.
- **Test đã chạy (27/11/2026):** `flutter test --no-pub -j 1 test/t081_pet_motion_and_group_hub_test.dart test/t075_today_pet_share_test.dart test/t079_group_streak_and_clean_arena_test.dart` → **9/9 passed**.
- **Điểm tiếp tục chính xác:** Triển khai tiếp **T082** (Profile Showcase + Vinh danh tuần & Khung bậc mùa Backend + Flutter UI) và **T083** (Game Đấu Thẻ Bài Chiến Thuật 75% Stage).
- **Git:** Chưa commit/push.
