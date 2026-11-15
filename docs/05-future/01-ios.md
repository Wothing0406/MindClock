# iOS sau Android P0

**Trạng thái:** roadmap, chưa có iOS build/AlarmKit test. Android là release đầu theo [lộ trình](../00-start/02-lo-trinh.md). Chỉ mở task iOS khi Android alarm/an toàn đã qua máy thật, có người phụ trách Mac/Xcode/iPhone và nhu cầu người dùng rõ.

## Ranh giới tính năng

Flutter UI/domain/data có thể tái dùng, nhưng alarm là tích hợp OS riêng; không suy rằng MethodChannel/Kotlin Android chuyển sang iOS. Phải kiểm API/phiên bản iOS mục tiêu và khả năng AlarmKit/notification hiện hành từ tài liệu Apple tại lúc code. Không hứa app có thể khóa nút Dừng hệ thống, tự mở khóa máy, chặn gỡ app hoặc cưỡng chế như Android. Dừng/thoát theo OS và đường an toàn của app vẫn rõ.

## Việc phải làm trước khi tuyên bố iOS chạy

1. Chọn phiên bản iOS hỗ trợ, thiết bị thật/Mac/Xcode, quyền/signing; lập bảng feature parity và giới hạn OS bằng nguồn chính thức cập nhật.
2. Viết platform alarm/notification/audio bridge riêng, fallback khi quyền bị từ chối, local offline và Dừng an toàn theo khả năng iOS. Tách adapter để PRD không giả hai OS giống nhau.
3. Kiểm onboarding/permission, background/khóa màn, reboot/timezone, âm/rung, accessibility/VoiceOver, account deletion, privacy; test iPhone thật và App Review policy.
4. Sửa UX/copy cho khác biệt iOS, không copy màn Android hoặc web rồi gọi đủ. Mỗi giới hạn phải nói thật trước release.

PvP/AI dùng chung server contract khi đủ điều kiện nhưng chỉ là nhánh sau. Nếu iOS không thể đáp ứng một AC báo thức, thu hẹp hoặc thay đổi PRD iOS rõ ràng; không ẩn khác biệt trong mock.
