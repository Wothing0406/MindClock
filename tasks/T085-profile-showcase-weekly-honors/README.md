# T085 — Profile Showcase Vinh Danh Tuần, Khung Bậc Mùa, Top Học Bá Môn & Nhiều Nhóm Chuỗi

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thêm Backend API `GET /v1/profile/showcase` và `GET /v1/leaderboard/weekly` tính từ dữ liệu thật trên PostgreSQL: Khung bậc mùa (theo XP & cấp độ), Huy hiệu Dậy sớm tuần (`X/7 ngày`, không xếp hạng giờ dậy), Môn sở trường từ `SubjectMemory`, Top Học bá môn tuần theo XP + tỷ lệ đúng, và danh sách tất cả nhóm giữ chuỗi đang tham gia.
  2. Nâng cấp `MeGuestScreen` với Profile Showcase theo phong cách sáng "bình minh trên trang vở" (lấy bố cục khoe thành tích rõ ràng như Liên Quân/Facebook: ảnh bìa trang vở bình minh, Avatar + Khung bậc mùa, Danh hiệu tuần, 3 ô Dấu ấn thành tích, Thẻ nhiều nhóm giữ chuỗi, Trình độ & Môn đang theo học, và nút mở Bảng xếp hạng Học bá tuần theo môn).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa:**
  - `services/api/app/services/profile_showcase_service.py`, `services/api/app/routes/v1.py`, `services/api/tests/test_t085_profile_showcase_and_weekly_leaderboard.py`
  - `app/lib/domain/models/personal_flow_models.dart`, `app/lib/domain/services/personal_flow_repository.dart`, `app/lib/data/repositories/remote_personal_flow_repository.dart`, `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`, `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`
  - `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`, `app/lib/ui/features/guest_shell/widgets/weekly_leaderboard_sheet.dart`, `app/test/t085_profile_showcase_test.dart`
- **Liên quan:** Kế thừa `T078`, `T083`, `T084`.
- **Source refs đã đọc:** `docs/01-product/03-he-thiet-ke.md`, `app/lib/ui/features/guest_shell/views/me_guest_screen.dart`.
- **Điểm tiếp tục:** Kiểm tra hiển thị thật trên thiết bị Android từ bản `dist/apk/mindclock-android.apk`.

## Cổng trước coding

- [x] Đã đọc `MeGuestScreen` và bất biến an toàn (không dùng giờ dậy để xếp hạng người dùng).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và test xanh (`pytest` + `flutter test` toàn suite).
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
