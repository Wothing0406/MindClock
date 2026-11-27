# Nhật ký làm việc T093

## 2026-11-27

- **Khảo sát root-cause:**
  1. Trong `StudySpaceScreen.build()`, khối `if (_activeMeetRoom != null) StudyRoomSessionPanel(...)` không tách nhánh `else`, khiến bên dưới phòng học bạn bè vẫn tiếp tục render toàn bộ `_buildSetupAndHistory` (`"1. Chọn việc học cụ thể"`, `"Học một mình"`).
  2. `_buildPersonalizedPracticeCard` và `_buildGeminiLiveOptInCard` bị gọi lặp ở cả `_buildSetupAndHistory` lẫn `_buildActiveSession`, kèm chữ kỹ thuật `(0 XP, không thay ngân hàng báo thức đã duyệt)` và `gemini-3.8-live`.
  3. Trong `StudyFocusViewModel.startSession()`, khi người dùng chọn môn (`_draftSubjectCode`) nhưng để trống ô tiêu đề việc học (`rawTitle.isEmpty`), `resolvedSubject` bị gán về `null`, làm `requestAiHelp` gửi `subjectCode = null` lên backend.
  4. Trên `TodayScreen`, vừa có ô `today-dir-study` trong Danh mục tính năng vừa có thẻ `_buildStudySpaceEntryCard` ở cuối màn.
- **Sửa lỗi và kiểm thử:**
  - Tách rõ 3 nhánh `_StudyEntryBranch { solo, withAi, withFriends }` cùng lựa chọn tường minh `Bắt đầu ngay` / `Hẹn giờ` (`_StudyStartScheduleMode`).
  - Sửa `StudyFocusViewModel.startSession()` và `requestAiHelp()` để bảo toàn `subjectCode` đã chọn hoặc fallback từ môn đầu tiên trong `StudyProfile`, kèm nối `goalLabel` vào ngữ cảnh gửi AI.
  - Thêm ô `study-solo-stuck-note-input` cho phiên `Học một mình`, hộp thoại consent chọn ảnh đề bài `study-ai-photo-consent-btn` cho phiên `Học cùng MindClock AI`, lọc môn tạo phòng và tắt mặc định AI phòng trong `StudyCommunitySheet`, xóa `_buildStudySpaceEntryCard` lặp trên `TodayScreen`.
  - Chạy `flutter analyze --no-pub` (`No issues found!`) và toàn bộ 12 file test Không gian học & `TodayScreen` (`52/52` test cases PASS).
