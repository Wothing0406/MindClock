# Báo thức Android local và thử thách

**Owner:** Android/Flutter. **P0 safety invariant:** `Dừng khẩn cấp` dừng âm và rung ngay một chạm kể cả offline, token hết hạn, app không có UI Flutter, đang chấm hoặc camera lỗi. Không khóa thiết bị, chặn gỡ app, tự mở khóa màn hình hoặc hứa che nút Dừng của OS. [PRD](../01-product/01-prd.md), [UX](../01-product/02-hanh-trinh-ux.md).

## 1. Cấu hình và trạng thái

`AlarmConfig`: local ID, giờ theo múi IANA, ngày lặp, enabled, mode `normal|challenge`, snooze chỉ mode thường, âm thanh/rung, môn/câu dự phòng (nếu có), revision local. Nhiều alarm độc lập; sửa/xóa một alarm không làm mất alarm khác. `SleepSchedule` local có giờ ngủ/giờ dậy/lời nhắc/quiet hours, không âm thầm sửa alarm. Gợi ý giờ dậy lấy tiết đầu − chuẩn bị − di chuyển − đệm, hiển thị phép tính và **không tự lưu**. Không yêu cầu login. [UX vòng ngủ](../01-product/09-giac-ngu-va-bao-thuc.md).

| Trạng thái | Có nghĩa | UI |
| --- | --- | --- |
| `saved_local` | Cấu hình đã lưu trên máy, OS chưa xác nhận | `Đã lưu trên máy. Cần kiểm tra quyền.` |
| `scheduled_os` | Kotlin đã lập lịch và trả occurrence kế tiếp | `Báo thức tiếp theo...`; vẫn kiểm sau reboot/quyền đổi. |
| `needs_permission` | OS từ chối hoặc mất quyền | Hướng mở Settings, thử lại, fallback rõ. |
| `ringing` | Service phát âm/rung, notification/Activity theo quyền | Dừng khẩn cấp luôn thao tác trực tiếp native. |
| `sound_stopped_review_active` | Người dùng bấm `Mở câu`, âm/rung dừng cục bộ, lượt học chưa hoàn thành | Flutter mở cảnh/câu đã cache; không cấp EXP chỉ vì tắt âm. |
| `dismissed`/`snoozed` | Local đã dừng khẩn cấp hoặc hoãn thường | Ghi local trước; sync server sau nếu được phép. |

Không hiện `Đã sẵn sàng` chỉ vì DB/API lưu thành công. Flutter bridge có version, mã lỗi ổn định và callback khi lifecycle thay đổi; native là nguồn trạng thái OS.

## 2. Máy trạng thái và luồng reo

```text
draft → saved_local → scheduled_os → ringing → sound_stopped_review_active → câu/feedback
                    ↘ needs_permission      ↘ dismissed (Dừng khẩn cấp)
                                           ↘ snoozed (normal only) → scheduled_os
```

Kotlin dùng khả năng OS phù hợp với phiên bản/quyền thiết bị, tính occurrence theo timezone/ngày lặp, không đặt trùng sau boot/time change/update. Receiver chỉ khởi động phần tối thiểu cần cho âm/rung/notification; full-screen UI theo quyền OS, có fallback notification và đường thao tác Dừng. Màn khóa mặc định hiện nội dung trung tính, môn/TKB chi tiết chỉ khi user chọn công khai; không tự mở khóa. `Mở câu` phải dừng native âm/rung **trước** khi phát cảnh mở màn trong Flutter; nhánh Dừng khẩn cấp không chờ Flutter. Không tải câu/media/Gemini trước khi cho người dùng dừng chuông. Câu và cảnh published nên cache trước giờ reo; nếu không có, fallback chữ hoặc `Ôn sau` khi thiếu câu. Âm MP3 tích hợp/tệp user phải có quyền đọc/sử dụng, chuẩn mức âm lượng, và fallback âm OS khi lỗi; tắt âm/rung không phụ thuộc codec/network. [Android exact alarm](https://developer.android.com/develop/background-work/services/alarms), [full-screen intent và lock-screen visibility](https://developer.android.com/develop/ui/compose/notifications/create-notification#full-screen_intent).

Đến giờ ngủ, app chỉ tự im lặng **thông báo của chính mình** theo quiet hours. Nếu user muốn DND toàn máy, mở flow xin Notification Policy access/thiết lập quy tắc được OS cho phép, rồi kiểm trạng thái thật. Android 15+ thay đổi hành vi DND với app target API 35; không code `setInterruptionFilter` rồi mặc định toàn máy đã tắt thông báo. Quyền từ chối → hướng dẫn người dùng mở Settings, không ảnh hưởng alarm. [Android DND permission](https://developer.android.com/reference/kotlin/android/provider/Settings#ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS), [thay đổi Android 15](https://developer.android.com/about/versions/15/behavior-changes-15).

## 3. Mode thường và thử thách

| Hành vi | Thường | Thử thách |
| --- | --- | --- |
| Hoãn | Có nếu người dùng bật, local | Không có nút Hoãn |
| Dừng khẩn cấp | Luôn có | Luôn có |
| Câu hỏi | Có thể ôn sau | Câu ngắn đã duyệt/cache, chọn theo môn hôm nay |
| Sai rõ 1–2 lần | Thử lại | Thử lại, không lộ hint/đáp án qua UI/API |
| Sai rõ từ lần 3 | Gợi ý theo luồng học | Có gợi ý bước đầu, không đáp án cuối |
| Sai rõ từ lần 5 | Có thể kết thúc ôn | `Bỏ lượt` hoặc `Thử tiếp`; bỏ không EXP/ngày chuỗi mới |
| `uncertain`/ảnh mờ/AI timeout | Không tính sai | Không tăng wrong count, nhập chữ/thử lại/hoàn thành không chấm |
| Mất mạng/không có câu | Dừng như thường | Vẫn dừng được; không “khóa” vào câu chưa chấm |

Ảnh viết tay và câu hỏi có thể tạo một bước học chủ động, **không chứng minh đã tỉnh táo và không chống gian lận tuyệt đối**: điện thoại thứ hai/AI ngoài app vẫn có thể giải hộ. Không chụp màn hình ngoài quyền hoặc theo dõi app khác. Khi sai rõ, cho làm lại và từ lần thứ 3 gợi bước đầu; từ lần thứ 5 có `Bỏ lượt`, còn Dừng khẩn cấp luôn có. Âm báo không kéo dài đến khi đáp đúng; cảnh video không phát khi âm chuông còn chạy. Bỏ lượt/dừng không được EXP/chuỗi mới nhưng không trừ điểm cũ; lỗi hệ thống không làm mất chuỗi oan. [Nguồn cảnh](../01-product/11-canh-mo-man-va-nguon-video.md).

## 4. Test thiết bị bắt buộc

AD01 foreground/khóa màn; AD02 app bị swipe/process chết; AD03 offline/token hết hạn; AD04 quyền exact/notification/full-screen từ chối/thu hồi; AD05 Dừng khi reo/đọc/chấm; AD06 Hoãn thường vs thử thách; AD07 reboot/đổi giờ/múi/cập nhật app; AD08 camera/AI timeout; AD09 chữ 200%/TalkBack/giảm chuyển động. Ghi model, API level, OEM, quyền, build hash, thời gian dự kiến/thực, log/video không lộ dữ liệu. **Emulator không thay máy thật** cho AD01/02/07. [Ma trận](../03-quality/01-ke-hoach-kiem-thu.md).

## 5. Ranh giới code và release

Flutter: `AlarmSchedulerService` + ViewModel/UI; Kotlin: Scheduler/Receiver/Service/Activity và manifest/notification; test bridge/occurrence/âm/tắt (`AlarmOccurrenceCalculatorTest`, `AlarmSoundResolverTest`, `AlarmRingPrivacyAndStateTest` trong `app/android/app/src/test/kotlin/com/mindclock/app/`). Không thêm quyền chỉ để “khắt khe” hơn. Mỗi thay đổi Manifest/OS alarm cần chạy lại AD01–AD07 trên máy thật. Cấu hình release không được xem API là điều kiện để báo thức reo. iOS có giới hạn khác ở [lộ trình tương lai](../05-future/01-ios.md).
