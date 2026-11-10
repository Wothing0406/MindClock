# MindClock trên iOS: kiến trúc, cài đặt và demo

**Quyết định:** dùng một UI Flutter cho Android/iOS, có cầu nối native Swift riêng cho AlarmKit trên iOS 26+. iOS là nhánh triển khai sau lát cắt Android. Không thể tạo build iOS thật từ máy Windows hiện tại: [Flutter yêu cầu Xcode trên macOS](https://docs.flutter.dev/deployment/ios). Tài liệu này là checklist chuẩn bị, chưa phải xác nhận đã cài hay build.

## 1. Điều hệ điều hành cho phép

[AlarmKit](https://developer.apple.com/documentation/AlarmKit) hỗ trợ báo thức một lần/lặp lại, cấp quyền, trình bày trên màn khóa và hành động tùy chỉnh trên iOS/iPadOS 26+. [Ví dụ chính thức của Apple](https://developer.apple.com/videos/play/wwdc2025/230/) có nút **Dừng** cùng nút phụ mở app qua App Intent. Vì vậy MindClock **không cam kết buộc giải đúng mới tắt được chuông hệ thống**. Trải nghiệm chuẩn: chuông reo → người dùng mở thử thách học → hoàn thành để ghi tiến bộ; luôn có Dừng/Hoãn và không phạt khi dùng.

Với iOS cũ hơn 26, chỉ hứa trải nghiệm **nhắc ôn tập** qua notification nếu đội triển khai, không gọi đó là báo thức hệ thống tương đương. Không dùng vòng phát âm thanh nền, VoIP hoặc cách lách quyền để giữ chuông. Bất kỳ phương án fallback nào đều phải thử trên thiết bị thật và mô tả đúng giới hạn.

## 2. Ba mức demo, chọn theo nguồn lực

| Mức | Chuẩn bị | Trình diễn được | Không được tuyên bố |
| --- | --- | --- | --- |
| A. Prototype trên iPhone | Figma hoặc web prototype, Safari, backend demo nếu có | Giao diện tiếng Việt, câu hỏi, chụp ảnh nếu web hỗ trợ, rank/nhân vật mô phỏng | Báo thức nền iOS, TestFlight, push/AlarmKit đã chạy |
| B. Flutter iOS build | Mac, Xcode, iPhone thật, ký build, Flutter, Firebase config; app đã code | UI native app, đăng nhập/quiz/camera/backend thật; có thể mô phỏng sự kiện reo | Báo thức đáng tin nếu chưa tích hợp AlarmKit |
| C. AlarmKit thật | Toàn bộ mức B + iPhone iOS 26+, cầu nối Swift, quyền AlarmKit, test màn khóa | Lên lịch chuông trước 1–2 phút, reo trên iPhone, nhấn mở thử thách | “Không thể tắt nếu chưa giải”; OS vẫn có Dừng |

**Khuyến nghị DevFest:** demo Android thật là tuyến chính nếu đã làm được. Mang iPhone ở mức A hoặc B làm bằng chứng thiết kế đa nền tảng. Chỉ chọn C khi đã test lặp lại trên chính thiết bị mang đi thi. Demo online leaderboard có thể dùng hai điện thoại hoặc điện thoại + máy chiếu; ghi “dữ liệu mẫu” cho mọi dữ liệu fixture.

## 3. Checklist cài đặt cho đội có Mac

1. Chuẩn bị Mac chạy bản macOS/Xcode tương thích với iOS mục tiêu; cài Xcode, iOS SDK, công cụ dòng lệnh, Flutter SDK và CocoaPods theo [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup).
2. Chạy kiểm tra môi trường Flutter; giải quyết lỗi signing/plugin trước khi thêm AlarmKit. Chọn bundle ID duy nhất và cùng ID trong Firebase iOS config.
3. Dùng Apple ID và team signing cho thử trực tiếp trên iPhone; bật Developer Mode, tin cậy máy Mac, cắm thiết bị. Phát hành TestFlight cần cấu hình App Store Connect/Apple Developer Program theo [hướng dẫn Apple](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).
4. Tạo app iOS trong Firebase, đưa file cấu hình vào phần iOS theo quy trình của Firebase; không commit secret. Kiểm tra đăng nhập, camera permission và gọi backend HTTPS trên máy thật.
5. Tạo adapter Flutter `AlarmScheduler` với hai implementation: Android và iOS. iOS bridge gọi `AlarmManager` của AlarmKit, yêu cầu quyền khi người dùng bật báo thức, lưu `alarmId` để update/cancel, ánh xạ kết quả `authorized/denied/unavailable/error` lên UI.
6. Đặt chuỗi mô tả quyền AlarmKit, camera và notification bằng tiếng Việt trong cấu hình iOS; chỉ xin quyền tại đúng lúc cần. Xác minh tên quyền và entitlement theo SDK/Xcode thực tế trước khi build, đặc biệt `NSAlarmKitUsageDescription` từ [hướng dẫn Apple](https://developer.apple.com/videos/play/wwdc2025/230/).
7. Kiểm tra giờ địa phương, lặp ngày, đổi múi giờ, tắt quyền, khởi động lại, Focus/Silent, màn khóa, pin thấp, app bị đóng, không mạng. Cảnh báo người dùng ngay nếu lịch chuông không được hệ thống chấp nhận.
8. Khi bản chạy ổn định, archive/upload lên App Store Connect, tạo nhóm TestFlight và mời người thử; bản cho người ngoài có thể cần Apple review. TestFlight không thay test trực tiếp trước ngày thi.

## 4. Hợp đồng native–Flutter đề xuất

| Hàm | Đầu vào | Kết quả | Lỗi cần UI xử lý |
| --- | --- | --- | --- |
| `requestAlarmPermission()` | không | `authorized/denied/unavailable` | Từ chối hoặc OS cũ |
| `scheduleAlarm()` | `alarmId`, giờ địa phương, ngày lặp, tiêu đề, `questionSnapshotId` | `scheduledAt`, `platformAlarmId` | Quyền, giờ không hợp lệ, OS từ chối |
| `cancelAlarm()` | `platformAlarmId` | `cancelled` | ID cũ, lịch không tồn tại |
| `getAlarmStatus()` | `platformAlarmId` | `scheduled/ringing/stopped/unknown` | Bridge chưa sẵn sàng |
| `openChallenge()` | `alarmId`, nguồn `system_alarm` | deep link tới thử thách | App chưa khởi tạo: dùng snapshot local |

`questionSnapshotId` tham chiếu dữ liệu cục bộ; không đưa đề hay ảnh cá nhân vào metadata hiển thị công khai. Server không điều khiển chuông. Khi OS gửi sự kiện Dừng, ghi `dismissed` cục bộ rồi đồng bộ sau; không ghi “bỏ cuộc”. App Intent mở thử thách phải test khi app chưa chạy.

## 5. Kịch bản sân khấu 4 phút

1. **0:00–0:40:** nói rõ bài toán, chỉ một màn lịch học và báo thức; trên iPhone chọn mức demo thực tế đã đạt.
2. **0:40–1:40:** đặt chuông 1–2 phút sau hoặc dùng chuông đã chuẩn bị; có video dự phòng 20–30 giây quay trên chính máy và nhãn “video dự phòng”.
3. **1:40–2:40:** mở câu Toán theo lịch, chụp ảnh đáp án, xem phản hồi/gợi ý. Nếu mạng lỗi, dùng câu offline và nói rõ AI chưa chạy.
4. **2:40–3:30:** hai tài khoản demo hoàn thành trận giao hữu online, cập nhật bảng môn/tuần; chỉ gọi ELO nếu hệ thống rating thật đã chạy.
5. **3:30–4:00:** cho thấy linh thú nhận phụ kiện và kết luận tác dụng; nhấn vào đường tắt/hoãn an toàn.

## 6. Tiêu chí chấp nhận iOS

- iPhone iOS 26+ cho quyền: lên lịch, reo, mở app, dừng/hoãn và hủy lịch đúng; test ít nhất 10 lần ở các trạng thái màn khóa/app đóng.
- Từ chối quyền hoặc OS không hỗ trợ: không hiện “báo thức đã sẵn sàng”; có hướng dẫn và lối dùng quiz thủ công.
- Mất mạng/Gemini lỗi: chuông vẫn reo và dừng được; câu cached hoặc bỏ qua thử thách.
- Deep link không mở trùng phiên, không ghi XP hai lần, không lộ đề/ảnh trên màn khóa.
- VoiceOver, chữ lớn, giảm chuyển động, nút Dừng dễ tìm; ảnh/chụp bài có đường nhập tay.

