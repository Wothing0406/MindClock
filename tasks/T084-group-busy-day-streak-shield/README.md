# T084 — Cơ Chế Ngày Bận & Khiên Bảo Hộ Bảo Lưu Chuỗi Nhóm

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thêm bảng & migration `commitment_group_busy_days` (`0010_add_group_busy_days.py`) cho phép thành viên nhóm báo bận hôm nay (lý do ngắn: *Đi thi / Việc gia đình / Nghỉ ốm*), giới hạn **2 lượt/tháng** mỗi thành viên.
  2. Cập nhật `CommitmentGroupService._pet_summary`:
     - Ngày bình thường: cần 100% thành viên `active` hoàn thành để cộng `+1` Chuỗi.
     - Ngày có thành viên báo bận (còn hạn mức 2 lượt/tháng hoặc nhóm có Khiên từ 7 ngày đủ nhóm): các thành viên không báo bận còn lại đều hoàn thành -> **bảo lưu nguyên `Chuỗi N`** (không tụt về 0, không cộng thêm `+1` cho tới ngày cả nhóm làm đủ lại).
     - Trả thêm `busyCountToday`, `streakPreservedToday`, `shieldsAvailable`, `myBusyQuotaUsed`, `myBusyQuotaLimit`, `busyTodayByMe`.
  3. Thêm endpoint `POST /v1/commitment-groups/{group_id}/busy-today` và xóa trong `DELETE /v1/me`.
  4. Nâng cấp Flutter `CommitmentPetSummary`, `CommunityRepository`, `RemoteCommunityRepository`, `DebugFixtureCommunityRepository`, `CommitmentGroupScreen` & `TodayPetCard` hiển thị nút **Báo bận hôm nay (còn X/2 lượt)** và trạng thái **Đang bảo lưu Chuỗi N** (không lộ tên thành viên bận).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026` (sau `/grill-me`).
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `services/api/app/db/models.py`, `services/api/alembic/versions/0010_add_group_busy_days.py`, `services/api/app/schemas.py`
  - `services/api/app/services/commitment_group_service.py`, `services/api/app/routes/v1.py`, `services/api/tests/test_t084_group_busy_days.py`
  - `app/lib/domain/models/commitment_group_models.dart`, `app/lib/domain/services/community_repository.dart`, `app/lib/data/repositories/remote_community_repository.dart`, `app/lib/data/debug/debug_fixture_community_repository.dart`
  - `app/lib/ui/features/community/views/{commitment_group_screen.dart,today_pet_card.dart}`, `app/test/t084_group_busy_day_test.dart`
- **Liên quan:** Kế thừa `T079`, `T081`.
- **Source refs đã đọc:** `services/api/app/services/commitment_group_service.py`.
- **Điểm tiếp tục:** Tạo model + migration `0010` và cập nhật `CommitmentGroupService`.

## Cổng trước coding

- [x] Đã đọc `CommitmentGroupService._pet_summary` và thống nhất luật Ngày bận qua `/grill-me`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và test xanh.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
