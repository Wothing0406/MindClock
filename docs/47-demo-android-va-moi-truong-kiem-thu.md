# Demo Android trên Windows — môi trường, chạy thử và bàn giao

**Trạng thái 12/11/2026:** runbook cho **lúc app Flutter Android được tạo**. Repo hiện có docs và `demo/index.html`, **chưa có `pubspec.yaml`, APK, backend chạy hay báo thức native**. Các lệnh Flutter/API bên dưới là lệnh điều kiện, không phải bằng chứng đã chạy. iOS để giai đoạn sau theo [docs/20](20-ios-demo-va-phat-hanh.md).

## 1. Mục tiêu demo và phạm vi

Đường chính trên **một điện thoại Android thật**: mở lịch hôm nay → đặt chuông thử 1–2 phút sau → khóa màn hình → chuông reo theo khả năng OS → mở câu đã duyệt → nhập đáp án và một bước giải → nhận `correct/incorrect/uncertain` → Dừng khẩn cấp hoạt động ngay. Chỉ gọi “đã chạy” cho bước đã quan sát trên máy. Không gian học có thể trình bày timer cục bộ nếu đã code; PvP dùng storyboard/prototype có nhãn cho đến khi hai máy và backend thật đạt [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md).

| Mức demo | Có gì thật | Cách nói với giám khảo |
| --- | --- | --- |
| A — hiện tại | `demo/index.html`, dữ liệu mẫu, chuyển màn | `Đây là bản xem giao diện, chưa có báo thức Android hoặc AI chạy.` |
| B — app local | Flutter APK trên Android, timer/chuông local, câu đóng gói | `Báo thức chạy trên thiết bị; phản hồi nào là mẫu phải ghi Mô phỏng.` |
| C — app + backend | B + FastAPI, PostgreSQL, Auth, câu/chấm đã duyệt | Chỉ nói `AI live` nếu request thật và fallback được phân biệt; không hứa PvP/ranked nếu chưa có |

**Cổng sân khấu:** B chỉ được gọi báo thức thật sau khi thử máy khóa, app đóng, offline, quyền bị từ chối và Dừng khẩn cấp. Máy ảo chỉ chứng minh UI/luồng thông thường, không thay kiểm thử báo thức trên máy thật.

## 2. Ai cần cài gì, chi phí

| Vai | Cần cài trên Windows | Không cần cho lát cắt Android |
| --- | --- | --- |
| Dev mobile | Git, Flutter SDK, Android Studio bản chính thức (SDK, platform-tools, emulator tùy chọn), editor; một máy Android + cáp USB | Mac/Xcode/Apple Developer Program |
| Dev backend | Python, môi trường ảo, FastAPI/deps **sau khi có mã**, PostgreSQL khi test online hai máy; công cụ xem log | Firebase/Cloud nếu chỉ demo local fixture |
| Tester/pitch | Android thật đã cài APK, cáp/sạc, laptop trình chiếu, bản HTML/PDF/video dự phòng | Android Studio nếu chỉ thao tác app |

Android Studio **không có bản “Lite” chính thức**; Android Emulator nằm trong Android Studio. Theo [yêu cầu Windows của Android Studio](https://developer.android.com/studio/install), IDE cần tối thiểu 8 GB RAM, IDE + Emulator cần tối thiểu 16 GB; nếu máy yếu, dùng Android thật qua USB thay emulator. Cần bật ảo hóa phần cứng nếu dùng emulator. Không mua công cụ cho demo Android; quota dịch vụ ngoài có thể đổi, xem [docs/26](26-bo-cong-cu-mien-phi-va-kich-ban-demo.md).

## 3. Chuẩn bị một lần trên máy dev

1. Cài Flutter SDK và thêm `flutter/bin` vào PATH theo [Flutter setup Android](https://docs.flutter.dev/platform-integration/android/setup); cài Android Studio stable cùng Android SDK/Platform Tools; chấp nhận Android SDK licences theo hướng dẫn Flutter.
2. Mở terminal mới, chạy `flutter doctor -v`; sửa mục Android toolchain. Chạy `flutter devices` để thấy emulator hoặc điện thoại. **Hiện tại chưa có app để `flutter run`.**
3. Điện thoại: bật Developer options và USB debugging; cắm USB, chấp nhận RSA fingerprint. Chạy `adb devices`; trạng thái phải là `device`, không phải `unauthorized`. Khi trình chiếu, bật chế độ không hiện thông báo cá nhân và giữ sạc.
4. Nếu dùng emulator: trong Android Studio Device Manager tạo một AVD điện thoại phổ biến với image Google APIs; bật virtualization. Chỉ mở một AVD trên máy RAM hạn chế. Emulator dùng địa chỉ `10.0.2.2` để gọi server chạy ở `localhost` máy Windows; điện thoại thật dùng IP LAN của laptop cùng mạng, **không dùng `localhost` của điện thoại**. Backend production dùng HTTPS; cấu hình HTTP dev cục bộ nếu cần phải giới hạn build debug, không mang sang release.
5. Khi app được tạo: chạy `flutter pub get`, `flutter analyze`, `flutter test`; chạy `flutter run -d <deviceId>` hoặc `flutter build apk --debug` từ **thư mục app chứa `pubspec.yaml`**, ghi đường dẫn build thực tế khi code có. Không đoán rằng `demo/index.html` là app Flutter.

**Nếu chưa có app:** mở `demo/index.html` trên laptop, bấm qua bốn màn và nói rõ là prototype. Có thể chiếu trình duyệt điện thoại bằng local server khi cùng mạng; file HTML hiện không có Android alarm, camera, AI hoặc PvP thật. Không cài plugin IDE để giả rằng code đã tồn tại.

## 4. Ma trận Android phải chạy khi có APK

| ID | Tình huống | Bằng chứng/kỳ vọng |
| --- | --- | --- |
| AD01 | Chuông 1–2 phút sau, app foreground rồi màn khóa | Ghi máy/Android version/giờ dự kiến & thực tế; âm/rung/UI theo quyền OS |
| AD02 | App bị swipe khỏi recent hoặc process chết | Chuông vẫn reo nếu đã schedule và OS cho phép; nếu OEM chặn, ghi giới hạn thực |
| AD03 | Tắt Wi-Fi/dữ liệu, token hết hạn | Chuông và Dừng khẩn cấp cục bộ; câu cache hoặc `Bắt đầu ôn sau` |
| AD04 | Từ chối/thu hồi exact alarm/notification/full-screen permission | App báo đúng trạng thái, không hiện `đã sẵn sàng` giả |
| AD05 | Bấm Dừng khẩn cấp khi chuông, đang đọc, đang chấm | Âm/rung dừng ngay một chạm; không phạt XP/streak |
| AD06 | Chế độ thường vs thử thách | Hoãn chỉ ở thường; thử thách không Hoãn nhưng luôn Dừng khẩn cấp |
| AD07 | Reboot, đổi múi giờ/giờ, cập nhật app | Lịch reo được tái tính/kiểm tra, không chuông trùng; ghi OEM nếu có sai lệch |
| AD08 | Camera bị từ chối/ảnh mờ/AI timeout | Nhập chữ được; `uncertain` không bị coi sai/gian lận; ảnh không vào log |
| AD09 | Chữ 200%, TalkBack, Reduce Motion | Giờ, đề, nút Dừng và kết quả còn đọc/dùng được |
| AD10 | Hai máy nếu demo PvP thật | Cùng câu/deadline/event server; không tự chấm HP ở client; reconnect/void rõ |

Test AD01–AD09 phải ghi `device model`, Android/API level, build hash, thời gian, quyền đang bật, kết quả thực, screenshot/video **không lộ dữ liệu cá nhân**. Test trên emulator chỉ ghi `emulator`; AD01/02/07 cần máy thật. Mỗi build thay đổi Android alarm/Manifest phải chạy lại AD01–AD07. Dùng [docs/09](09-ke-hoach-kiem-thu.md) cho cổng P0; không tuyên bố pass khi chưa có APK.

## 5. Luồng 90 giây và phương án dự phòng

1. **0–15 giây:** `Hôm nay` hiện môn/lịch mẫu; nói phần nào local/live.
2. **15–30 giây:** đặt chuông thử gần thời điểm hiện tại; khóa máy. Nếu giờ sân khấu không cho chờ, dùng video quay **trên cùng build/máy** có nhãn `Video kiểm thử`, không nói đang reo trực tiếp.
3. **30–50 giây:** mở câu theo lịch, nhập đáp án + một bước, không cần ép camera.
4. **50–70 giây:** hiện một trong ba kết quả chấm; nếu fixture thì nhãn `Mô phỏng`, nếu Gemini live thì nói kết quả có thể `Chưa đủ rõ`.
5. **70–90 giây:** Dừng khẩn cấp thật nếu chuông đang reo; sau đó `Hôm nay`/việc học. PvP chỉ một ảnh concept sau demo chính nếu còn thời gian.

**Dự phòng:** APK debug đã cài sẵn, file HTML offline, video ngắn có nhãn, PDF 5 màn, hotspot/sạc/cáp/adapter, một câu đội tự viết với đáp án/rubric. Nếu mạng mất, bỏ AI live và nói đúng trạng thái; nếu chuông không reo, dùng video kiểm thử và công khai lỗi/giới hạn. Không hiển thị ảnh học sinh thật hoặc token/key. Mang bảng `đã chạy / mô phỏng / kế hoạch` để người thuyết trình không nói quá.

## 6. Checklist trước khi nộp

- [ ] Quy chế cuộc thi cho phép mức chuẩn bị hiện có; giờ nộp được xác minh từ ban tổ chức.
- [ ] Có **một** luồng Android đáng tin cậy trên đúng máy đem thi; AD01–AD09 ghi kết quả thực.
- [ ] `flutter analyze`, test phù hợp, backend/contract test nếu dùng API; ghi lệnh và kết quả, không đánh dấu giả.
- [ ] Chế độ demo không dùng tài khoản/dữ liệu học sinh thật; asset và câu hỏi có quyền dùng.
- [ ] Video/PDF/prototype có nhãn; không gọi bảng mẫu là live hoặc iOS là app đã chạy.
- [ ] Người điều khiển demo và người nói đã tập tối thiểu 3 lần, có đường lui khi mạng/AI lỗi.

**Nguồn nền tảng:** [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup), [Android Studio install](https://developer.android.com/studio/install), [Android exact alarms](https://developer.android.com/develop/background-work/services/alarms), [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests). Kiểm tra lại phiên bản SDK/permission trước coding.
