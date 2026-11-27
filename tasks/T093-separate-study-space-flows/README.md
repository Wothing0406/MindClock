# T093 — Tách bạch 3 luồng Không gian học (Một mình, Cùng AI, Cùng bạn) và chuẩn hóa môn theo Hồ sơ

- **Trạng thái:** `verifying`
- **Mục tiêu:** Tách Không gian học thành 3 luồng độc lập, rõ ràng (`Học một mình`, `Học cùng MindClock AI`, `Học cùng bạn`), loại bỏ hoàn toàn tình trạng màn phòng bạn bè vẫn hiện khối `"Học một mình"` bên dưới, tách rõ `Bắt đầu ngay` / `Hẹn giờ` không tạo lịch ngầm, lọc môn học đúng theo `StudyProfile`, giữ `Tạo câu luyện` ở duy nhất một nơi tùy chọn và thống nhất một điểm vào Không gian học trên màn hình chính.
- **Nguồn yêu cầu:** Task 2 trong đặc tả tái cấu trúc sản phẩm và phản hồi + ảnh chụp thực tế của người dùng; `2026-11-27`.
- **Chủ sở hữu/reviewer:** AI Assistant / User.
- **Phạm vi file dự kiến:**
  - `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/lib/ui/features/study_focus/views/study_community_sheet.dart`
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`
  - `app/test/study_focus_local_test.dart`
  - `app/test/community_friends_and_meet_room_test.dart`
  - `app/test/t076_mvp_hub_and_backend_auth_test.dart`
  - `app/test/t093_study_space_three_flows_test.dart`
- **Liên quan:** Sau `T092` (`d340740`); tiền đề giao diện cho `T094` (vòng đời phòng học backend/SQL).
- **Source refs đã đọc:** `AGENTS.md §3`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `docs/02-engineering/07-khong-gian-hoc.md`, `docs/01-product/03-he-thiet-ke.md`.
- **Điểm tiếp tục:** Kiểm chứng trình chọn ảnh thật và mic/TTS trên điện thoại Android vật lý; chuyển sang `T094` cho vòng đời phòng học backend/PostgreSQL.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và cập nhật hoặc ghi quyết định.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt ở mức Flutter widget/unit; phần máy Android vật lý ghi rõ ở `handoff.md`.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/API/schema được rà soát (khớp `docs/01-product/08-phong-hoc-ai-va-ban-be.md`).
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
