# Bàn giao nhiệm vụ T093

- **Trạng thái cuối:** `verifying` (toàn bộ `flutter analyze` và 12 bộ `flutter test` Không gian học đã PASS trên Windows 11; giữ `verifying` vì chưa cắm điện thoại Android vật lý để kiểm trình chọn ảnh hệ thống thật).
- **Git commit & nhánh:** `fdb8a33` trên nhánh `main` (đã push và xác nhận trên `origin/main`).
- **Đã thay đổi:**
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`: tách 3 lựa chọn ngang hàng (`Học một mình`, `Học cùng MindClock AI`, `Học cùng bạn`); cô lập hoàn toàn màn phòng bạn bè (không còn render thiết lập `Học một mình` bên dưới `StudyRoomSessionPanel`); thêm chọn `Bắt đầu ngay` / `Hẹn giờ` chỉ tạo lịch khi bấm xác nhận; thêm ô ghi chú vướng mắc trong phiên `Học một mình`; thêm gửi ảnh đề bài có hộp thoại consent trong phiên `Học cùng MindClock AI`; bỏ lặp `Tạo câu luyện` và dọn sạch nhãn kỹ thuật.
  - `app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`: giữ `subjectCode` khi bắt đầu phiên không nhập tiêu đề tùy chỉnh và truyền đủ môn/lớp/mục tiêu (`goalLabel`, `fallbackSubjectCode`) sang `requestHelp`.
  - `app/lib/ui/features/study_focus/views/study_community_sheet.dart`: lọc môn tạo phòng theo `StudyProfile.selectedSubjectCodes` và đặt mặc định `_newRoomAiEnabled = false` trừ khi chủ phòng chủ động bật mời AI.
  - `app/lib/ui/features/guest_shell/views/today_screen.dart`: xóa `_buildStudySpaceEntryCard` bị lặp để `today-dir-study` là điểm vào duy nhất cho Không gian học.
  - `app/test/t093_study_space_three_flows_test.dart`, `app/test/study_focus_local_test.dart`, `app/test/community_friends_and_meet_room_test.dart`, `app/test/t076_mvp_hub_and_backend_auth_test.dart`: kiểm thử đầy đủ `AC-01`..`AC-04` và đồng bộ khóa điều hướng.
- **Bằng chứng kiểm thử (`2026-11-27`, Windows 11, Flutter VM):**
  - `cd app && flutter analyze --no-pub` -> `No issues found! (ran in 4.8s)`.
  - `cd app && flutter test --no-pub -j 1 test/t093_study_space_three_flows_test.dart test/study_room_modes_and_exp_test.dart test/backend_integration_contract_test.dart test/t068_community_room_controls_test.dart test/t071_study_speech_test.dart test/t072_gemini_voice_test.dart test/t086_study_microcheck_and_arena_stage_test.dart test/alarm_ai_preview_and_candle_test.dart test/custom_avatar_and_audio_picker_test.dart test/community_friends_and_meet_room_test.dart test/study_focus_local_test.dart test/t076_mvp_hub_and_backend_auth_test.dart` -> **ALL PASSED**.
  - `python scripts/check_docs_links.py` & `python scripts/check_task_records.py` -> **PASS**.
- **Rủi ro & giới hạn còn lại:**
  - Chưa cắm thiết bị Android thật (`adb devices` trống) để kiểm thử hộp thoại chọn ảnh Android thật trong phiên AI.
  - Vòng đời phòng học trên server PostgreSQL (`waiting -> active -> closing -> closed | expired`, heartbeat TTL, chuyển chủ phòng khi rời, thu hồi/hết hạn mã mời) được tách riêng sang task kế tiếp `T094`.
- **Điểm tiếp tục chính xác:**
  1. Thực hiện `T094` cho vòng đời phòng học backend/PostgreSQL và dọn state phòng đã đóng trên client.
  2. Khi có máy Android thật qua USB, mở `Không gian học -> Học cùng MindClock AI -> Bắt đầu -> Gửi ảnh đề bài` để xác nhận picker cục bộ.
