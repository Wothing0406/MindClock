# Đặc tả nhiệm vụ T062

## Vấn đề và kết quả mong muốn

Qua chạy kiểm chứng thật trên ảnh TKB lớp 12/20 của người dùng và rà code hiện tại:
1. `parse_timetable_image` đang ưu tiên `gemini-3.1-flash-lite` với timeout 8s dẫn tới `ReadTimeout`, còn `gemini-3-flash-preview` đọc ảnh thành công nhưng 4 tiết đặc thù THPT (`Chào cờ`, `SHL`, `ND GDĐP`, `HĐTN-HN`) và mã `civic_econ` chưa map chuẩn sang `SubjectCatalog`; bên cạnh đó `TimetableProfileScreen` lại trả 11 tiết cứng giả khi chưa đăng nhập.
2. Khi mất mạng hoặc server lỗi, `PersonalFlowViewModel.startSession` rơi về đúng 1 câu cố định `2x + 4 = 12` không có đáp án/lời giải sẵn trên máy theo môn học; khi có mạng cần cho phép AI tạo câu mới từ đề gốc (`seedQuestionId`) và nạp thẳng vào phiên để học sinh trả lời.
3. Trong Đấu trường Solo chưa có chọn thời gian mỗi lượt (30s/45s/60s/90s/Không giới hạn) kèm đồng hồ đếm ngược tự chuyển lượt, PvP chưa đếm ngược realtime từ `deadlineAt`, và bộ câu hỏi cần quay vòng/nạp thêm liên tục theo phiên đấu.
4. Khi báo thức tới giờ reo và người dùng bấm "Mở câu hỏi" (`AlarmRingActivity` -> `MindClockShellScreen`), nếu `payload.subjectCode` trống khi cấu hình `Theo lịch học hôm nay` thì cần tự phân giải môn từ TKB + Hồ sơ trước khi mở phiên, và bổ sung test tự động cho luồng này.
5. UI vẫn còn các chuỗi gây hiểu nhầm như `Thử phiên báo thức thử thách`, `Đề mẫu:`, `Đang tạo câu mẫu...`, `Mẫu PvP offline`, `Gia Bảo (Demo)`, `mẫu debug`, `mẫu mock`.

## Phạm vi

- **Trong phạm vi:** Backend Vision TKB (`gemini_service.py`, `routes/v1.py`, rebuild Docker `api`), mở rộng kho câu hỏi cục bộ có đáp án & rubric (`solo_training_question_bank.dart`, `subject_catalog.dart`, `morning_question_selector.dart`), luồng offline/online regen câu hỏi (`personal_flow_view_model.dart`, `practice_session_screen.dart`), timer + continuous question feed trong Solo/PvP (`solo_arena_view_model.dart`, `arena_screen.dart`, `arena_pvp_lobby.dart`), đồng bộ môn TKB khi mở từ báo thức (`mindclock_shell_screen.dart`), và xóa các nhãn `demo`/`mẫu` trên UI.
- **Ngoài phạm vi:** Không thay đổi `assets/game/`, không bật Ranked PvP, không tạo web client.
- **Dữ liệu/role/quyền liên quan:** Offline grading không được tự cộng XP/chuỗi có thẩm quyền server; câu hỏi AI online được gắn `target_user_id == uid`.
- **Tài liệu chuẩn:** `AGENTS.md §3–§4`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/05-ngan-hang-cau-hoi.md`, `docs/02-engineering/06-ai-va-cham-bai.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Gửi ảnh TKB bảng trường THPT Việt Nam lên `/v1/timetable/parse-image` (live hoặc unit) | Backend dùng model Vision ổn định (`gemini-3-flash-preview` ưu tiên trước, timeout >= 25s), đọc đủ môn chính + map tiết `Chào cờ`/`SHL`/`ND GDĐP`/`HĐTN-HN` & `civic_econ`; Flutter không bịa TKB giả khi chưa đăng nhập | TC-01, TC-02 |
| AC-02 | Khi mất mạng hoặc không kết nối server trong báo thức/luyện tập | Lấy câu hỏi có sẵn + đáp án/lời giải từ kho cục bộ đúng theo môn/TKB (xoay vòng nhiều câu cho Toán, Lý, Hóa, Sinh, Anh, Văn, Sử, Địa, Tin, KTPL), chấm đối chiếu đáp án cục bộ và hiện gợi ý/lời giải sau nộp nhưng giữ `0 XP server` | TC-03 |
| AC-03 | Khi có mạng và người dùng chọn tạo câu từ đề mẫu | Gọi `/v1/questions/personalized` kèm `seedQuestionId` (tạo & lưu câu mới gắn user), hoặc backend `/v1/challenges/next?mode=ai_regen`, nạp trực tiếp câu vừa sinh vào phiên hiện tại để học sinh trả lời & chấm bình thường | TC-04 |
| AC-04 | Đấu trường Solo và PvP 1v1 | Solo có chọn thời gian mỗi lượt (`30s`/`45s`/`60s`/`90s`/`Không giới hạn`), đếm ngược realtime, hết giờ tự xử lý qua lượt không đóng băng, nạp câu liên tục không lặp kề nhau (và tự prefetch câu AI khi có callback online); PvP 1v1 hiển thị đếm ngược `deadlineAt` realtime | TC-05 |
| AC-05 | Báo thức tới giờ reo -> bấm `Mở câu hỏi` khi dùng quy tắc `Theo lịch học hôm nay` | Nếu payload báo thức thiếu `subjectCode`, `MindClockShellScreen` phân giải môn từ `MorningQuestionSelector` theo TKB + Profile hiện tại và mở đúng câu môn đó (cả offline lẫn online) | TC-06 |
| AC-06 | Rà soát chuỗi UI toàn app | Không còn các từ `Demo`, `Thử phiên báo thức thử thách`, `Đề mẫu`, `mẫu debug`, `mẫu mock`, `Mẫu PvP` trên UI | TC-07 |

## Hợp đồng và trường hợp biên

- `GET /v1/challenges/next` giữ mặc định tương thích cũ; nếu truyền `mode=ai_regen` sẽ sinh biến thể AI từ câu gốc ngân hàng (fallback an toàn về câu gốc khi AI lỗi).
- `POST /v1/timetable/parse-image` mở rộng `subject_code` hợp lệ gồm `civic_econ` (và alias `civics`) + `activity` cho `Chào cờ`/`SHL`/`HĐTN-HN` để khớp `SubjectCatalog` Flutter; `MorningQuestionSelector` bỏ qua tiết `activity` khi chọn môn ôn sáng để lấy môn học chính khóa tiếp theo trong ngày.
- Trong test widget Flutter (`flutter test`), `SoloArenaViewModel` cho phép tắt timer auto-tick hoặc chọn `Không giới hạn` để `pumpAndSettle()` không treo; ở chế độ có timer, `Timer` được hủy sạch trong `dispose()` / chuyển pha / kết thúc trận.

## Quyết định/mâu thuẫn

- `civic_econ` được chọn làm mã chuẩn thống nhất giữa `SubjectCatalog` Flutter và `GeminiService` (giữ alias `civics` -> `civic_econ` ở parser để tương thích ngược).
- Tiết đặc thù `Chào cờ`, `SHL`, `HĐTN-HN` được giữ trên lưới TKB dưới mã `activity` (`Sinh hoạt / HĐTN`) thay vì bỏ mất khỏi ảnh TKB khi parse; riêng câu hỏi báo thức buổi sáng sẽ ưu tiên chọn môn học chính khóa trong ngày.
