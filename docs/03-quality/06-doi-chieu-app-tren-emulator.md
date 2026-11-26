# Đối chiếu app đang chạy trên emulator — 16/11/2026

## Phạm vi bằng chứng

- Thiết bị: Android Emulator `emulator-5554` (`sdk_gphone64_x86_64`), app `com.mindclock.app` đang ở màn `Hôm nay` lúc 20:40. [Ảnh chụp nguyên màn](evidence/2026-11-16-emulator-hom-nay.png).
- Đây là **bản đã cài trên emulator với dữ liệu hiện có**, không chứng minh hành vi cài mới hay mã WIP chưa build. Để xác nhận luồng cài mới, cần build lại APK, dùng tài khoản test và chạy ca ON/PLAN từ đầu mà không xóa dữ liệu người dùng thật.
- Đối chiếu mã Flutter tại thời điểm chụp và `tasks/T035-auth-onboarding-first-run/`; T035 đang được chỉnh tiếp trong cùng workspace. Mã mới xuất hiện sau ảnh chụp chưa là bằng chứng APK đã cài đã đổi.

## Kết quả theo hành vi người dùng

| Hành vi | Bằng chứng hiện tại | Kết luận |
| --- | --- | --- |
| Vào app qua tài khoản trước khi chọn lớp | Tại lúc chụp, `WelcomeScreen` còn nút thiết lập khách. Sau đó mã WIP T035 thêm `onStartAuth`/`AuthScreen`; chưa build và chạy lại từ cài mới. | **Chưa được xác nhận trên app.** Bản APK đang cài vẫn là luồng khách; mã mới cần test dọc. |
| Dashboard chỉ xuất hiện sau onboarding có tài khoản | Ảnh emulator hiện `Chế độ khách · Lưu trên máy`, `Lớp: Chưa chọn`, `Môn học: Chưa chọn`; `onSkipLater` đưa thẳng vào `mainTabs`. | **Chưa đạt.** Dashboard có thể mở khi hồ sơ trống. |
| Tải ảnh thời khóa biểu, AI đọc, cho sửa/xác nhận | `TimetableProfileScreen` chỉ có chọn ngày và thêm/sửa/xóa tiết thủ công; không có chọn ảnh/file, parse, bản nháp nhập hay xác nhận. | **Chưa có.** Chỉ có nhập lịch thủ công. |
| Đăng ký/lưu hồ sơ lên backend | T035 đang nối `AuthScreen` vào shell trong mã WIP; chưa có TC chạy và chưa có bằng chứng `PATCH /v1/me` với PostgreSQL thực. | **Chưa chứng minh được.** Có màn Auth/API riêng không có nghĩa hành trình dọc đã chạy. |
| Task T035 hoàn thành | Lúc kiểm ngày 16/11/2026, `tests.md` ghi TC-01..04 `Chưa chạy`; `handoff.md` ghi `in-progress`; `check_task_records.py` báo trạng thái không hợp lệ; `flutter analyze --no-pub` báo 2 issue ở `auth_screen.dart`. Đây là ảnh chụp trạng thái WIP, cần chạy lại sau chỉnh sửa. | **Đang làm, chưa đạt cổng.** Không đánh dấu `done` hoặc dùng T035 làm bằng chứng sản phẩm. |

## Thứ tự sửa và cổng xác nhận

1. Hoàn thiện T035: màn đầu ưu tiên đăng ký/đăng nhập, giữ `Chỉ dùng báo thức trên máy` làm đường cứu sinh; xác minh email, lớp 10–12/môn/avatar và kế hoạch nháp có xác nhận trước `Hôm nay`. Tách dữ liệu khách và tài khoản. Chạy ON-01..06, Auth A/B, restart/draft trên emulator và backend test; sửa mọi issue analyzer. Không dùng ảnh chụp từ bản APK cũ để kết luận mã mới.
2. Task riêng cho nhập TKB bằng ảnh: chọn ảnh hoặc chụp, quyền đúng lúc dùng, parse thành **bản nháp**, xem/sửa/xác nhận trước lưu, hủy không giữ ảnh. Kiểm lịch nhiều môn, lịch ngoại lệ, ảnh mờ, AI lỗi/offline và A/B. Giữ nhập tay là fallback.
3. Sau mỗi task, ghi lệnh/test/ngày/thiết bị/build/ảnh và giới hạn trong `tests.md`/`handoff.md`; chỉ cập nhật [hiện trạng](../00-start/01-hien-trang.md) khi có bằng chứng. Emulator không thay máy Android thật cho báo thức.

Nguồn đích: [hành trình UX](../01-product/02-hanh-trinh-ux.md), [đăng ký/onboarding](../01-product/07-dang-ky-va-khoi-tao-lo-trinh.md), [thời khóa biểu](../01-product/05-lich-hoc-nhac-viec.md), [ca nghiệm thu](05-ca-nghiem-thu.md).
