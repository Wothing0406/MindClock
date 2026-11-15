# Báo thức Android local và thử thách

**Owner:** Android/Flutter. **P0 safety invariant:** `Dừng khẩn cấp` dừng âm và rung ngay một chạm kể cả offline, token hết hạn, app không có UI Flutter, đang chấm hoặc camera lỗi. Không khóa thiết bị, chặn gỡ app, tự mở khóa màn hình hoặc hứa che nút Dừng của OS. [PRD](../01-product/01-prd.md), [UX](../01-product/02-hanh-trinh-ux.md).

## 1. Cấu hình và trạng thái

`AlarmConfig`: local ID, giờ theo múi IANA, ngày lặp, enabled, mode `normal|challenge`, snooze chỉ mode thường, âm thanh/rung, môn/câu dự phòng (nếu có), revision local. Gợi ý giờ dậy lấy tiết đầu − chuẩn bị − di chuyển − đệm, hiển thị phép tính và **không tự lưu**. Không yêu cầu login.

| Trạng thái | Có nghĩa | UI |
| --- | --- | --- |
| `saved_local` | Cấu hình đã lưu trên máy, OS chưa xác nhận | `Đã lưu trên máy. Cần kiểm tra quyền.` |
| `scheduled_os` | Kotlin đã lập lịch và trả occurrence kế tiếp | `Báo thức tiếp theo...`; vẫn kiểm sau reboot/quyền đổi. |
| `needs_permission` | OS từ chối hoặc mất quyền | Hướng mở Settings, thử lại, fallback rõ. |
| `ringing` | Service phát âm/rung, notification/Activity theo quyền | Dừng khẩn cấp luôn thao tác trực tiếp native. |
| `dismissed`/`snoozed` | Local đã dừng hoặc hoãn thường | Ghi local trước; sync server sau nếu được phép. |

Không hiện `Đã sẵn sàng` chỉ vì DB/API lưu thành công. Flutter bridge có version, mã lỗi ổn định và callback khi lifecycle thay đổi; native là nguồn trạng thái OS.

## 2. Máy trạng thái và luồng reo

```text
draft → saved_local → scheduled_os → ringing → dismissed
                    ↘ needs_permission      ↘ snoozed (normal only) → scheduled_os
```

Kotlin dùng khả năng OS phù hợp với phiên bản/quyền thiết bị, tính occurrence theo timezone/ngày lặp, không đặt trùng sau boot/time change/update. Receiver chỉ khởi động phần tối thiểu cần cho âm/rung/notification; full-screen UI theo quyền OS, có fallback notification và đường thao tác Dừng. Không tải câu/Gemini trước khi cho người dùng dừng chuông. Âm MP3 tích hợp phải có quyền sử dụng, chuẩn mức âm lượng, và fallback âm OS khi lỗi; tắt âm/rung không phụ thuộc codec/network.

## 3. Mode thường và thử thách

| Hành vi | Thường | Thử thách |
| --- | --- | --- |
| Hoãn | Có nếu người dùng bật, local | Không có nút Hoãn |
| Dừng khẩn cấp | Luôn có | Luôn có |
| Câu hỏi | Có thể ôn sau | Câu ngắn đã duyệt/cache, chọn theo môn hôm nay |
| Sai rõ 1–2 lần | Thử lại | Thử lại, không lộ hint/đáp án qua UI/API |
| Sai rõ từ lần 3 | Gợi ý theo luồng học | Có gợi ý bước đầu, không đáp án cuối |
| `uncertain`/ảnh mờ/AI timeout | Không tính sai | Không tăng wrong count, nhập chữ/thử lại/hoàn thành không chấm |
| Mất mạng/không có câu | Dừng như thường | Vẫn dừng được; không “khóa” vào câu chưa chấm |

Ảnh viết tay và câu hỏi tăng khả năng tỉnh táo, **không chống gian lận tuyệt đối**: điện thoại thứ hai/AI ngoài app vẫn có thể giải hộ. Không chụp màn hình ngoài quyền hoặc theo dõi app khác. Học sinh không bị phạt vì nghỉ, sai, dừng khẩn cấp hoặc quyền bị từ chối.

## 4. Test thiết bị bắt buộc

AD01 foreground/khóa màn; AD02 app bị swipe/process chết; AD03 offline/token hết hạn; AD04 quyền exact/notification/full-screen từ chối/thu hồi; AD05 Dừng khi reo/đọc/chấm; AD06 Hoãn thường vs thử thách; AD07 reboot/đổi giờ/múi/cập nhật app; AD08 camera/AI timeout; AD09 chữ 200%/TalkBack/giảm chuyển động. Ghi model, API level, OEM, quyền, build hash, thời gian dự kiến/thực, log/video không lộ dữ liệu. **Emulator không thay máy thật** cho AD01/02/07. [Ma trận](../03-quality/01-ke-hoach-kiem-thu.md).

## 5. Ranh giới code và release

Flutter: `AlarmSchedulerService` + ViewModel/UI; Kotlin: Scheduler/Receiver/Service/Activity và manifest/notification; test bridge/occurrence/âm/tắt. Không thêm quyền chỉ để “khắt khe” hơn. Mỗi thay đổi Manifest/OS alarm cần chạy lại AD01–AD07 trên máy thật. Cấu hình release không được xem API là điều kiện để báo thức reo. iOS có giới hạn khác ở [lộ trình tương lai](../05-future/01-ios.md).
