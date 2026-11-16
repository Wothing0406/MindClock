# Nhật ký thực hiện T039

## Vòng 1: Khởi tạo nhiệm vụ
- Phân tích yêu cầu: Quét ảnh TKB bằng AI tự động cập nhật lịch báo sáng + Đồng hồ Realtime sản phẩm thực tế.
- Tạo cấu trúc task T039.

## Vòng 2: Triển khai Backend API & Gemini Vision OCR
- Định nghĩa schemas: `TimetableParseImageRequest`, `TimetableParseSlot`, `TimetableParseImageResponse` trong `services/api/app/schemas.py`.
- Triển khai phương thức OCR Gemini trong `GeminiService.parse_timetable_image`, chuẩn hóa tên môn học tiếng Việt sang canonical code (`math`, `literature`, `physics`, v.v.) và tiết học 1–10.
- Viết endpoint `POST /v1/timetable/parse-image` trong `routes/v1.py` với xác thực tài khoản và kiểm tra base64 payload.
- Viết bộ test `test_timetable_image_parser.py`: 3/3 PASS (mock parsing, auth check, invalid payload).

## Vòng 3: Triển khai Frontend Flutter
- Bổ sung `parseTimetableImage` vào `PersonalApiClient`, `PersonalFlowRepository` interface, `RemotePersonalFlowRepository`, và `DebugFixturePersonalFlowRepository`.
- Bổ sung `replaceEntireTimetable(WeeklyTimetable)` vào `GuestWorkspaceViewModel` để cập nhật nguyên tử 7 ngày thời khóa biểu.
- Cập nhật `TodayScreen`: Thêm Hero Realtime Clock Card với nhịp giây `HH:mm:ss`, thứ ngày tháng tiếng Việt, và đếm ngược thời gian chuông reo kế tiếp. Dọn dẹp triệt để các badge kỹ thuật dev-mode (`Đã lưu local`, `OS: Đã sẵn sàng`, `Server: Chưa đồng bộ`).
- Cập nhật `TimetableProfileScreen`: Thêm nút `Quét ảnh thời khóa biểu (AI tự động điền)`, bảng thẻ xem trước bản nháp AI (draft preview) với môn/tiết theo từng thứ trong tuần, nút `Xác nhận & Lưu thời khóa biểu` và `Hủy`.
- Tối ưu responsive: Bọc Hero Clock và các nhãn bằng `FittedBox` + `Wrap` để đảm bảo không bị tràn chữ (RenderFlex overflow) tại 320dp với cỡ chữ 200%.

## Vòng 4: Kiểm thử tự động & Xác minh trên Android Emulator
- Tạo `timetable_ocr_and_realtime_clock_test.dart` kiểm tra `TC-RTC-01` (đồng hồ đếm giây) và `TC-OCR-01` (luồng AI quét và duyệt TKB): 2/2 PASS.
- Chạy toàn bộ test suite Flutter: 47/47 PASS.
- Rebuild Docker container backend `api-api-1` và kiểm tra endpoint.
- Rebuild debug APK `flutter build apk --debug`, cài đặt lên Android emulator (`emulator-5554`), kiểm tra trực tiếp:
  - Đồng hồ thời gian thực nhảy giây `00:22:45` và thứ ngày tiếng Việt hiển thị sắc nét.
  - Mở màn Thời khóa biểu & Hồ sơ, bấm nút quét ảnh AI, duyệt các tiết học (Vật lí, Hóa học...) cho Thứ 3, bấm Xác nhận & Lưu.
  - Màn Hôm nay lập tức hiển thị tiết học lúc 07:00 (Vật lí) và 07:50 (Hóa học) cùng gợi ý giờ dậy.
  - Chụp ảnh màn hình lưu vào artifacts.
