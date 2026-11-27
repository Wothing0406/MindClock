# Kế hoạch thực hiện T081

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T081-pet-motion-floating-group-hub/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Nâng cấp `MamPetView` có animation cử động + Reduce Motion | Widget render mượt không lỗi ticker | [x] |
| 3 | Tạo `CommitmentGroupScreen` & `FloatingMiniPetOverlay` | Mở nhóm chuyên biệt, chuyển tối đa 3 nhóm, copy mã, kéo thả mini pet | [x] |
| 4 | Gắn `FloatingMiniPetOverlay` vào `MindClockShellScreen` & nối nút mở Nhóm từ `TodayPetCard` | Dashboard gọn, không overflow `320dp 200%` | [x] |
| 5 | Viết `t081_pet_motion_and_group_hub_test.dart`, chạy `dart analyze` + test liên quan | Toàn bộ test xanh | [x] |
