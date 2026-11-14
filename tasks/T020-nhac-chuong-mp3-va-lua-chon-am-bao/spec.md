# Đặc tả nhiệm vụ T020

## Vấn đề và kết quả mong muốn

Hiện tại [alarm_config.dart](../../app/lib/domain/models/alarm_config.dart) chỉ có 3 lựa chọn `AlarmSoundOption` (`gentle_dawn`, `clear_bell`, `vibrate_only`) và [AlarmRingService.kt](../../app/android/app/src/main/kotlin/com/mindclock/app/AlarmRingService.kt) đang bỏ qua `soundOption` khi phát chuông (luôn dùng `RingtoneManager.TYPE_ALARM` mặc định).
Sau task T020, người dùng có thể chọn **Nhạc chuông Bermuda** (từ file MP3 trong `mp3/`) ở màn cấu hình báo thức, lưu bền vững trên máy, và khi chuông reo trên Android thì `AlarmRingService` phát đúng tài nguyên `R.raw.alarm_bermuda` ở kênh `USAGE_ALARM` (không phụ thuộc mạng/login), vẫn hỗ trợ `Dừng khẩn cấp` ngay lập tức.

## Phạm vi

- **Trong phạm vi:** đóng gói 1 file MP3 hiện có (`jeremayjimenez-bermuda-eas-alarm-2025-my-own-alarm-441470.mp3`) thành `res/raw/alarm_bermuda.mp3`, thêm `AlarmSoundOption.bermudaAlarm` (`id = 'bermuda_alarm'`, `labelVi = 'Nhạc chuông Bermuda'`), ánh xạ `soundOption` trong `AlarmRingService` + fallback về chuông OS mặc định nếu phát raw resource thất bại, viết test mapping & UI/persistence.
- **Ngoài phạm vi:** trình quản lý upload MP3 tùy biến từ bộ nhớ ngoài của người dùng (`READ_MEDIA_AUDIO`), xem trước sóng âm, hoặc đồng bộ file nhị phân lên server.
- **Dữ liệu/role/quyền liên quan:** chạy hoàn toàn local trên thiết bị, không cần thêm quyền OS mới (tài nguyên `res/raw` nằm trong APK).
- **Tài liệu chuẩn:** `docs/30-ngon-ngu-va-tai-san-giao-dien.md`, `docs/31-bao-thuc-thu-thach.md`, `.agents/skills/mindclock-android-native/SKILL.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| `SND-AC-01` | Người dùng mở màn Cấu hình báo thức | Hiển thị lựa chọn `Nhạc chuông Bermuda` cùng 3 lựa chọn cũ; chọn & lưu giữ nguyên `bermuda_alarm` qua `toJson`/`fromJson` | `SND-TC-01` |
| `SND-AC-02` | `AlarmRingService` khởi động với `soundEnabled=true`, `soundOption="bermuda_alarm"` | Chọn URI `android.resource://<pkg>/<R.raw.alarm_bermuda>`, phát vòng lặp trên `AudioAttributes.USAGE_ALARM`; fallback `RingtoneManager.TYPE_ALARM` nếu load URI lỗi | `SND-TC-02` |
| `SND-AC-03` | `soundOption="vibrate_only"` hoặc `Dừng khẩn cấp` được bấm | `vibrate_only` không phát nhạc chuông; `Dừng khẩn cấp` gọi `stopPlaybackAndForeground()` tắt `MediaPlayer` ngay | `SND-TC-02`, `SND-TC-03` |

## Hợp đồng và trường hợp biên

- `AlarmSoundOption` mở rộng thêm `'bermuda_alarm'` (chuỗi wire giữ tương thích ngược với server `/v1/alarms` vì JSON vẫn gửi/nhận `AlarmConfig`).
- Nếu nhận `soundOption` lạ từ dữ liệu cũ, `AlarmSoundOption.fromId` fallback an toàn về `gentleDawn`; phía Kotlin nếu `res/raw` không đọc được sẽ fallback về `RingtoneManager.getDefaultUri(TYPE_ALARM)` thay vì im lặng khi user đang bật chuông.
