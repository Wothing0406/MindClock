# T062 — Sửa TKB Vision ảnh thật, kho câu hỏi offline/online, timer đấu trường liên tục & xóa nhãn demo UI

- **Trạng thái:** `done`
- **Mục tiêu:** Khắc phục đúng các lỗi/khoảng trống vừa phát hiện qua kiểm chứng thực tế trên ảnh TKB người dùng và luồng báo thức/đấu trường: (1) TKB Vision ưu tiên model ổn định (`gemini-3-flash-preview`), nhận diện được cả tiết sinh hoạt/đặc thù THPT và bỏ TKB giả khi chưa đăng nhập; (2) Mất mạng lấy bộ câu hỏi & đáp án/lời giải sẵn theo môn/TKB từ kho cục bộ (không lặp 1 câu cứng `2x+4=12`), có mạng cho phép lấy đề mẫu gốc rồi AI tái tạo câu mới add thẳng vào phiên trả lời; (3) Đấu trường hỗ trợ thời gian mỗi lượt do người dùng chọn + đồng hồ đếm ngược thật + nạp/xoay vòng câu hỏi liên tục không cạn; (4) Luồng đúng giờ báo thức kêu -> mở đúng câu theo TKB/hồ sơ và có test tự động xác minh; (5) Xóa các từ `demo` / `Thử phiên...` / `Đề mẫu` / `mẫu debug` / `mẫu mock` gây hiểu nhầm trên UI.
- **Nguồn yêu cầu:** Tin nhắn người dùng + ảnh TKB lớp 12/20 ngày 2026-11-19.
- **Chủ sở hữu/reviewer:** Chủ dự án MindClock.
- **Phạm vi file dự kiến:** `services/api/app/services/gemini_service.py`, `services/api/app/routes/v1.py`, `services/api/tests/*`, `app/lib/domain/models/subject_catalog.dart`, `app/lib/domain/services/morning_question_selector.dart`, `app/lib/domain/game/solo_training_question_bank.dart`, `app/lib/data/debug/debug_fixture_pvp_gateway.dart`, `app/lib/ui/features/guest_shell/...`, `app/lib/ui/features/personal_flow/...`, `app/lib/ui/features/arena/...`, `app/lib/ui/features/study_focus/...`, `app/test/*`, `docs/00-start/01-hien-trang.md`.
- **Liên quan:** Nối tiếp `T058`, `T059`, `T060`, `T061`.
- **Source refs đã đọc:** `AGENTS.md §2–§4`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md`, `docs/02-engineering/06-ai-va-cham-bai.md`, `docs/04-game/01-pvp-gdd.md`, `services/api/app/services/gemini_service.py`, `services/api/app/routes/v1.py`, `app/lib/ui/features/personal_flow/view_models/personal_flow_view_model.dart`, `app/lib/ui/features/arena/view_models/solo_arena_view_model.dart`, `app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingActivity.kt`.
- **Điểm tiếp tục:** Triển khai các thay đổi theo `plan.md`, kiểm thử thực tế với ảnh TKB thật, `pytest`, `flutter analyze`, `flutter test`, rebuild Docker API & APK emulator, rồi commit/push lên `origin/main`.

## Cổng trước coding

- [x] Đã đọc tài liệu liên quan và code hiện tại.
- [x] Đã xác định mâu thuẫn/điểm chưa rõ và ghi quyết định trong `spec.md`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt hoặc ghi rõ phần chưa đạt.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường; test không chạy có lý do.
- [x] Docs chuẩn/hiện trạng được cập nhật nếu hành vi thay đổi.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
