# Đặc tả nhiệm vụ T092

## Vấn đề và kết quả mong muốn

Qua 10 ảnh chụp thực tế của người dùng và rà soát mã nguồn:
1. Thanh thông báo `"Đã dừng âm báo · Hoàn thành câu ôn để nhận thưởng. [Dừng khẩn cấp]"` (`_activeAlarmPlayingInQuestion`) chỉ là biến tạm trong `MindClockShellScreen`, không tự tắt khi học sinh đã hoàn thành câu sáng, bỏ lượt hoặc đăng xuất, và mất đồng bộ khi đóng/mở lại app.
2. Dashboard `TodayScreen` không lưu trạng thái lần chuông trong ngày nên sau khi làm xong câu sáng vẫn tiếp tục hiển thị thẻ nhắc làm câu sáng như chưa làm.
3. `PracticeSessionScreen` đặt thẻ `AccountAuthCard` ("Đăng xuất (giữ báo thức local)"), nút `"Mở Không gian học tập trung (local)"` và thẻ tiến độ lên trên câu hỏi, khiến học sinh mở từ chuông báo thức phải cuộn qua nhiều khối thừa và chữ kỹ thuật (`local`, `server`, `Idempotency-Key`, `rubric`, `rev`).
4. `submitMcqAnswer` và `submitMiniQuizAnswers` trong `PersonalFlowViewModel` tạo UUID mới mỗi lần bấm thay vì giữ ổn định cặp `clientAttemptId` + `idempotencyKey` khi mất mạng / phản hồi rơi rồi bấm gửi lại.
5. Bong bóng `FloatingMiniPetOverlay` che khuất các nút ở cuối màn `Hôm nay` và `Luyện tập`.

## Phạm vi

- **Trong phạm vi:** Mô hình `AlarmOccurrenceRecord` lưu trong `GuestWorkspace`, đồng bộ trạng thái occurrence với phiên câu hỏi sáng, khóa chống nộp trùng cho cả tự luận & trắc nghiệm, dọn giao diện `AlarmRingScreen`, `PracticeSessionScreen`, `TodayScreen`, `AlarmConfigScreen`, `TodayPetCard`, `FloatingMiniPetOverlay`.
- **Ngoài phạm vi:** Không gộp phân luồng Không gian học (`T093`) hay vòng đời phòng học backend (`T094`).
- **Tài liệu chuẩn:** `AGENTS.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md`, `docs/02-engineering/02-bao-thuc-android.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Chuông reo -> Mở câu -> Nộp bài -> Đúng / Bỏ lượt / Dừng khẩn cấp | Occurrence gắn `alarmId + dateIso` chuyển đúng `scheduled → ringing → question_open → submitted → completed | skipped | dismissed`; thanh dừng khẩn cấp tự ẩn ngay khi vào trạng thái kết thúc (`completed | skipped | dismissed`). | TC-01 |
| AC-02 | Câu sáng đã `completed` hoặc `skipped`, quay về Dashboard hoặc đóng/mở lại app | Dashboard hiển thị rõ `"Đã hoàn thành hôm nay"`, `"Đang chờ"`, `"Đã bỏ lượt"` hoặc `"Lỗi đồng bộ"`; không hiện lại như nhiệm vụ chưa làm, không mở lại màn chuông cũ của cùng lần reo. | TC-02 |
| AC-03 | App đóng giữa chừng khi đang `question_open`, hoặc bấm gửi nhiều lần / timeout rồi retry (kể cả trắc nghiệm ABCD) | Mở lại app khôi phục đúng occurrence đang chờ mà không tạo attempt mới thừa; bấm kép khi đang gửi hoặc retry sau lỗi mạng giữ nguyên `clientAttemptId` + `idempotencyKey`, chỉ tạo 1 kết quả. | TC-03 |
| AC-04 | Mở câu hỏi từ chuông sáng và xem tab `Luyện tập` / `Hôm nay` | Câu hỏi (môn, nội dung, cách nhập) nằm ngay đầu màn `Luyện tập`; không còn thẻ Đăng xuất hay nút Không gian học lặp trong `Luyện tập`; bỏ nhãn kỹ thuật (`local`, `Idempotency-Key`, `Có câu ôn duyệt`). | TC-04 |

## Hợp đồng và trường hợp biên

- `GuestWorkspace` bổ sung danh sách `alarmOccurrences` tương thích ngược hoàn toàn với JSON cũ (`schemaVersion: 2` đọc thiếu trường sẽ mặc định rỗng).
- Giữ đầy đủ quy tắc hiện hành: sai rõ lần 3 mới mở gợi ý phương pháp, sai rõ lần 5 mở `Bỏ lượt` (`0 EXP`), `uncertain` không tăng lượt sai, `Dừng khẩn cấp` luôn hoạt động 1 chạm.
