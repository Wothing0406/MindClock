# iOS — lộ trình sau demo Android

**Quyết định 12/11/2026:** cuộc thi/demo đầu tiên chỉ cam kết **Android** theo [docs/47](47-demo-android-va-moi-truong-kiem-thu.md). iOS là giai đoạn phát triển sau khi Android P0 qua kiểm thử máy thật và có nhu cầu được xác nhận. Không chuẩn bị iPhone/TestFlight/AlarmKit như một điều kiện của buổi thi; không gọi prototype Safari là app iOS. Repo hiện chưa có app iOS/build/chứng cứ kiểm thử.

## Điều kiện mở task iOS

1. Android đã có báo thức local, Dừng khẩn cấp, offline và bài học đạt cổng [docs/09](09-ke-hoach-kiem-thu.md); kiến trúc `AlarmScheduler` không trộn UI Flutter với hành vi OS.
2. Có Mac/Xcode, iPhone thật, người phụ trách native Swift và thời gian test. [Flutter yêu cầu Xcode trên macOS để build iOS](https://docs.flutter.dev/platform-integration/ios/setup); Windows hiện tại không tạo build iOS thật.
3. Chốt nhóm phiên bản iOS mục tiêu và tính khả thi AlarmKit theo [Apple AlarmKit](https://developer.apple.com/documentation/AlarmKit) tại thời điểm làm. iOS 26+ có AlarmKit; phiên bản cũ hơn nếu dùng notification phải ghi `nhắc ôn`, không gọi báo thức hệ thống tương đương.
4. Rà quyền camera/mic, consent, xóa dữ liệu, Firebase iOS config và quyền phát hành. Phát hành TestFlight/App Store là task sau; không đưa phí vào phương án demo 0 đồng.

## Hợp đồng dự kiến

Flutter dùng cùng UI/logic bài học, iOS có adapter native riêng để `requestPermission`, `schedule`, `cancel`, `getStatus`, `openChallenge`; lưu ID OS và ánh xạ `authorized/denied/unavailable/error`. Mọi báo thức phải chạy và dừng tại thiết bị, kể cả mất mạng/Gemini lỗi. Không đưa câu hỏi, ảnh hay dữ liệu riêng vào metadata màn khóa. AlarmKit không cho MindClock vô hiệu nút Dừng do OS cung cấp; không hứa bắt giải đúng mới tắt được chuông. Người học dừng không bị phạt.

## Cổng kiểm thử khi iOS được mở

- Mac/Xcode build thật, signing hợp lệ; iPhone thật, không chỉ Simulator.
- Lập lịch, reo, mở thử thách, dừng/hủy; màn khóa, app đóng, offline, Focus/Silent, reboot, đổi múi giờ, quyền bị từ chối/thu hồi. Ghi model/iOS version và ít nhất 10 lần thử theo từng đường quan trọng trước pilot.
- VoiceOver, chữ lớn, Reduce Motion, nhập chữ thay camera; không lộ câu/ảnh trên lock screen.
- Một phiên không ghi XP hai lần khi deep link hoặc callback lặp.
- Chỉ sau các cổng trên mới viết docs phát hành/TestFlight riêng, cập nhật API/contract tests trong task coding.

**Nguồn:** [Flutter iOS setup](https://docs.flutter.dev/platform-integration/ios/setup), [Apple AlarmKit](https://developer.apple.com/documentation/AlarmKit). Kiểm tra lại tài liệu và chính sách Apple khi bắt đầu task iOS.
