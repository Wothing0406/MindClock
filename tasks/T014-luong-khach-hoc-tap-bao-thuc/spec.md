# Đặc tả nhiệm vụ T014 — Luồng khách thiết lập học tập & cấu hình báo thức local

## Vấn đề và kết quả mong muốn

Repo hiện chưa có ứng dụng Flutter (`app/`). Nhiệm vụ này tạo lát cắt dọc P0 (rút gọn, lược bỏ Đấu trường) để người học ở chế độ **khách không cần tài khoản** có thể:
1. Bắt đầu dùng thử ngay không cần email/mật khẩu, hoặc chọn `Để sau` / `Chỉ báo thức`.
2. Thiết lập và chỉnh sửa bất cứ lúc nào: lớp/khối, nhiều môn đang học, môn ưu tiên ôn thi (0–5 môn) và nhãn mục tiêu cá nhân.
3. Quản lý thời khóa biểu 7 ngày (Thứ 2 → Chủ nhật): bật/tắt ngày nghỉ, thêm/sửa/xóa tiết môn học (môn + giờ bắt đầu).
4. Cấu hình báo thức local: giờ, ngày lặp `0..7` ngày, âm thanh, rung, chế độ thường hoặc tự bật `Báo thức thử thách` (có giải thích rõ không Hoãn, luôn có `Dừng khẩn cấp`). Môn chưa có câu đã duyệt vẫn cho đặt chuông và giải thích rõ.
5. Nếu dùng gợi ý giờ dậy: nhập tiết học/giờ bắt đầu + đi đường + chuẩn bị + đệm → hiển thị rõ phép tính trừ từng thành phần và **bắt buộc người dùng xác nhận `Dùng giờ này`** mới điền giờ vào form; sửa lịch hoặc gợi ý mới tuyệt đối không tự đổi giờ báo thức đang bật/đã lưu.
6. Lưu bền vững cục bộ trên thiết bị và khôi phục nguyên vẹn khi mở lại app.
7. Tách interface `AlarmSchedulerService` để giai đoạn native Android (`MethodChannel` / `AlarmManager`) nối vào sau; khi chưa nối OS, chỉ hiển thị trạng thái `Đã lưu cấu hình` (tuyệt đối không hiển thị `Đã sẵn sàng` hoặc giả đã cấp quyền OS).
8. Giao diện Flutter theo phong cách MindClock Android (`ThemeExtension<MindClockTheme>`, `MindClockPressable` không ripple Material mặc định, tiếng Việt `vi-VN`, không emoji, vùng chạm ≥48×48 dp, lược bỏ hoàn toàn Đấu trường).

## Phạm vi

- **Trong phạm vi (`app/`):**
  - `app/pubspec.yaml`, `app/analysis_options.yaml`
  - `app/lib/domain/`: `StudyProfile`, `WeeklyTimetable`, `AlarmConfig`, `WakeSuggestion`, `ApprovedQuestionCatalog`, `AlarmSchedulerService` (interface + `UnboundAlarmSchedulerService` chưa nối OS)
  - `app/lib/data/`: `LocalKeyValueStore` interface + `SharedPreferencesKeyValueStore` + `GuestWorkspaceRepository` (lưu/khôi phục JSON local)
  - `app/lib/ui/`: `MindClockTheme` + `MindClockPressable` + shell 3 tab (`Hôm nay`, `Luyện tập`, `Tôi`) + màn `S01` Chào mừng khách, `S03` Thiết lập nhanh, `S04` Hôm nay, `S05` Thời khóa biểu & Môn học, `S06` Cấu hình báo thức & Gợi ý giờ dậy
  - `app/test/`: unit tests + widget tests cho toàn bộ AC-01..AC-08.
- **Ngoài phạm vi:**
  - Kotlin `AlarmManager` Receiver/BootReceiver/FullScreenIntent thật (để interface chờ nối giai đoạn native), Firebase Auth online, FastAPI backend, AI Gemini, camera chấm bài, Không gian học timer, và **toàn bộ Đấu trường** (lược bỏ).
- **Tài liệu chuẩn:** `docs/05 §§2–6`, `docs/24 §1`, `docs/31 §§1–2,6`, `docs/32 §§1–2,4–5,7`, `docs/41 §§2–3`, `docs/54`, `docs/55`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi mở app lần đầu (`S01`) | Hiển thị `Dùng thử không cần tài khoản`, `Để sau` và `Chỉ báo thức` không yêu cầu email/mật khẩu; thanh dưới chỉ có 3 tab (`Hôm nay`, `Luyện tập`, `Tôi`), không có Đấu trường | `TC-01` |
| AC-02 | Khi thiết lập hồ sơ (`S03`/`S05`) | Cho chọn lớp, nhiều môn, môn ưu tiên (0–5 môn) và sửa nhãn mục tiêu; có nút `Để sau` / `Chỉ báo thức` bất kỳ lúc nào | `TC-02` |
| AC-03 | Khi thao tác Thời khóa biểu 7 ngày (`S05`) | Cho bật/tắt `Ngày nghỉ` từng ngày từ Thứ 2 đến Chủ nhật, thêm/sửa/xóa tiết môn học (môn + `HH:mm`) và lưu được | `TC-03` |
| AC-04 | Khi cấu hình báo thức (`S06`) | Cho đặt giờ, ngày lặp (T2–CN), âm thanh, rung, chọn thường vs tự bật `Báo thức thử thách` (giải thích rõ không Hoãn, luôn có `Dừng khẩn cấp`); môn chưa có câu duyệt vẫn cho lưu chuông và hiện giải thích rõ | `TC-04` |
| AC-05 | Khi dùng gợi ý giờ dậy & sửa lịch (`S06`, `S05`) | Tính `giờ bắt đầu − đi đường − chuẩn bị − đệm`, hiển thị phép tính rõ ràng, chỉ đặt vào giờ chuông khi người dùng bấm `Dùng giờ này`; khi sửa TKB hoặc đổi gợi ý, **không tự đổi giờ chuông đã chọn/lưu** (chỉ hiện nhắc xem lại) | `TC-05` |
| AC-06 | Khi lưu cấu hình qua `AlarmSchedulerService` chưa nối OS | Gọi interface `AlarmSchedulerService`; khi chưa nối OS chỉ hiển thị `Đã lưu cấu hình` và trạng thái quyền `Chưa kiểm tra (chưa nối OS)`, không hiển thị `Đã sẵn sàng` hay giả đã cấp quyền | `TC-06` |
| AC-07 | Khi đóng và mở lại app (`GuestWorkspaceRepository`) | Khôi phục đầy đủ lớp, môn, môn ưu tiên, mục tiêu, thời khóa biểu 7 ngày, ngày nghỉ và báo thức đã lưu từ storage local | `TC-07` |
| AC-08 | Khi kiểm UI Android (`320/360/390/600 dp`, chữ `100/150/200%`) | Không dùng emoji hệ thống, dùng `MindClockTheme` + `MindClockPressable` (≥48 dp), không overflow | `TC-08` |

## Hợp đồng và trường hợp biên

- **Offline hoàn toàn:** 100% logic thiết lập, gợi ý giờ dậy và lưu/khôi phục báo thức chạy local không cần mạng.
- **Vượt qua nửa đêm:** nếu `giờ học 00:15` trừ tổng `65 phút` → `23:10` ngày hôm trước (wrap modulo 1440 phút).
- **Môn chưa có câu duyệt:** giả định catalog local ban đầu có câu đã duyệt cho `Toán`, `Tiếng Anh`, `Sinh học` (theo `docs/32` / ngân hàng mẫu nội bộ); các môn khác đánh dấu `hasApprovedQuestion = false` → vẫn cho bật/lưu chuông kèm banner giải thích, không chặn người học.
- **Chuỗi khi chưa nối OS:** nghiêm cấm xuất hiện chuỗi `"Đã sẵn sàng"` hay icon tích xanh OS granted khi `isOsBridgeConnected == false`.

## Quyết định/mâu thuẫn

- `docs/54` liệt kê 4 tab có `Đấu trường` bật theo cohort flag; theo yêu cầu nhiệm vụ hiện tại (*"tóm gọn trong 4 tiếng, lược bỏ luôn đấu trường"*), shell UI lát cắt này chỉ dựng 3 tab (`Hôm nay`, `Luyện tập`, `Tôi`) và không đưa UI/route Đấu trường vào app.
- Máy dev hiện chưa cài Flutter SDK (`flutter`/`dart` không có trong `PATH`, có `adb.exe` tại `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`), do đó code + test Dart được xây chuẩn mực theo `flutter_test` nhưng việc thực thi `flutter analyze`/`flutter test`/`flutter run` ghi rõ là bị chặn chờ cài Flutter SDK.
