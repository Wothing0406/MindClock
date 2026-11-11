# Công cụ miễn phí cho đội và kịch bản demo

> **Cập nhật 11/11/2026:** để làm trước 30% sản phẩm, chọn FastAPI + SQLite local theo [docs/29](29-ke-hoach-chuan-bi-30-phan-tram.md). Firebase Emulator/Spark ở các mục dưới là lựa chọn khi đội bật xác thực/online, không bắt buộc cho lát cắt 30%.

**Mục tiêu chi phí DevFest: 0 đồng tiền dịch vụ.** Không tạo project billing/Blaze, không mua Apple Developer Program, không cần domain. Mọi tài khoản demo là tài khoản thử, mọi ảnh là bài tự viết của thành viên hoặc fixture có quyền. Giới hạn miễn phí có thể đổi; kiểm tra lại trước ngày thi theo [Firebase Pricing](https://firebase.google.com/pricing/) và [Gemini Pricing](https://ai.google.dev/gemini-api/docs/pricing).

## 1. Mỗi thành viên cài gì

| Vai trò | Bắt buộc | Chỉ khi làm phần đó |
| --- | --- | --- |
| Tất cả | Git, tài khoản GitHub, trình duyệt Chrome/Edge, VS Code hoặc IDE quen dùng, đọc docs/README | Figma bản miễn phí để xem prototype nếu dùng |
| Flutter Android | Flutter SDK, Android Studio/Android SDK, JDK tương thích với Flutter, điện thoại Android + cáp USB hoặc emulator | Xcode/Mac chỉ nếu làm iOS |
| Backend | Python bản được pin khi tạo code, venv, Firebase CLI + Emulator Suite, tài khoản Firebase Spark | Gemini API key demo giới hạn, chỉ backend giữ |
| UI/đồ họa | Figma free hoặc Penpot, trình duyệt; font có licence, export PNG/SVG | Không cần phần mềm vẽ trả phí |
| Pitch/demo | Laptop có HDMI/USB-C phù hợp, trình duyệt, điện thoại Android, bộ sạc, video dự phòng, hotspot | OBS miễn phí nếu cần quay màn hình |

**Không phải ai cũng cài tất cả.** Đội chọn một người giữ quyền Firebase/Gemini, không chia sẻ key qua chat/Git. Khi code bắt đầu phải pin phiên bản và ghi lệnh thực trong README; hiện repo chưa có app nên không có lệnh `flutter run` bảo đảm chạy.

## 2. Tích hợp ở mức 0 đồng

| Thành phần | Chọn cho demo | Giới hạn cần nói rõ |
| --- | --- | --- |
| GitHub | Repo hiện có để chia docs và code | Đội tự quản lý quyền ghi |
| Figma/Penpot hoặc [demo HTML](../demo/index.html) | Xem UI trên laptop/iPhone qua browser | Prototype không chứng minh báo thức nền |
| Firebase Emulator Suite | Đăng ký/Firestore/Rules offline trên máy dev | Chỉ laptop cùng máy/mạng; không phải dịch vụ production |
| Firebase Spark | Nếu cần hai máy thi online thật | Theo quota miễn phí; không bật dịch vụ cần billing; kiểm tra quota hiện hành |
| Gemini free tier | Một vài ảnh **do đội tự tạo** để demo live | Rate limit; nội dung free tier có điều kiện sử dụng dữ liệu; có fixture fallback |
| Android APK debug | Cài trực tiếp trên máy của đội | Không cần Google Play; phải test đúng máy đi thi |
| iPhone prototype Safari | Xem UI tương tác | Không có AlarmKit; muốn build iOS cần Mac/Xcode, TestFlight cần membership trả phí |

[Apple Developer Program](https://developer.apple.com/help/account/membership/program-enrollment/) hiện nêu phí thường niên 99 USD (có trường hợp miễn cho tổ chức giáo dục đủ điều kiện). Để giữ 0 đồng, không chọn TestFlight trong demo. Nếu có Mac + iPhone, có thể thử ký build phát triển bằng Apple ID cá nhân theo [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup), nhưng phải kiểm tra giới hạn tài khoản/thiết bị và chuẩn bị trước ngày thi.

## 3. Demo cho giám khảo trong một buổi sáng

1. Mở [demo giao diện](../demo/index.html) trên laptop, trình chiếu màn `Hôm nay` và chọn `Đấu trường`. Nếu mở file trực tiếp thì chạy offline; trên iPhone cần đưa file vào cùng mạng/local server hoặc host tĩnh có kiểm tra trước.
2. Trên Android thật cho xem lát cắt có code nếu đội đã hoàn thành: đặt chuông, câu đã duyệt, chụp bài, phản hồi. Nếu chưa có, ghi rõ `Prototype` trên màn và lời nói.
3. Hai tài khoản thử/thiết bị thực hiện giao hữu nếu backend đã chạy; nếu chưa, dùng bảng mẫu có nhãn `Dữ liệu mô phỏng`. Không gọi dữ liệu mẫu là live.
4. Trình bày ba trạng thái AI: đúng, cần xem lại, chưa đọc rõ; dùng ảnh tự viết của đội. Khi mạng lỗi, phát video dự phòng có nhãn.
5. Chốt bằng giới hạn thật: báo thức không khóa nút Dừng, ELO chưa mở nếu chưa có câu hiệu chuẩn, quyền riêng tư opt-in.

**Túi đồ demo:** laptop + sạc, Android + sạc/cáp, adapter trình chiếu, ảnh viết tay giấy thật, bản HTML offline, video 20–30 giây, slide/PDF offline, danh sách tài khoản thử, hotspot dự phòng. Đặt thiết bị ở chế độ không hiện thông báo cá nhân.

## 4. Điều kiện 0 đồng và rủi ro

Không thể vừa yêu cầu TestFlight/phát hành App Store vừa đảm bảo 0 đồng nếu đội không có membership/miễn phí phù hợp. Cloud Run/Blaze hay các dịch vụ có billing không nằm trong phương án này. Demo live Gemini có thể chạm quota hoặc Internet yếu, nên đường mock/fixture là bắt buộc và phải gắn nhãn. Firebase Spark có giới hạn; không dùng làm cơ sở hứa miễn phí vĩnh viễn cho toàn bộ học sinh.

