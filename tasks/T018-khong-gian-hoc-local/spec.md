# Đặc tả nhiệm vụ T018 — Không gian học local (Nhiệm vụ 6A)

## Vấn đề và kết quả mong muốn

Người học cần có một không gian tự học cục bộ hoàn chỉnh hoạt động độc lập với mạng, đăng nhập, camera, micro và AI: chọn một việc cụ thể (gợi ý từ thời khóa biểu hoặc tự nhập / `Học tự do`), chọn thời lượng (`10 / 25 / 45` phút hoặc tùy chỉnh `5–120` phút), chọn một trong ba mức tập trung (`Linh hoạt`, `Tập trung thường` mặc định, `Cam kết`), theo dõi đồng hồ tính theo mốc thời gian thực, tạm nghỉ/tiếp tục, nhận xử lý đúng ngưỡng khi rời app, khôi phục an toàn sau khi app bị kill/reboot dưới trạng thái `Phiên đã gián đoạn`, kết thúc và lưu lịch sử cục bộ idempotent, đồng thời báo thức local độc lập vẫn hoạt động bình thường.

## Phạm vi

- **Trong phạm vi (6A):**
  - Chọn việc từ lịch học hôm nay / đổi việc / tự nhập / `Học tự do`.
  - Chọn thời lượng `10`, `25`, `45` phút hoặc tùy chỉnh `5–120` phút; chọn mức `Linh hoạt` / `Tập trung thường` (mặc định) / `Cam kết`; tùy chọn âm báo cuối phiên và chế độ số tĩnh (Reduce Motion).
  - Bắt đầu → tạm nghỉ/tiếp tục → kết thúc (`completed` / `ended_early`), state machine chuẩn `docs/45 §2`.
  - Đồng hồ dựa trên mốc thời gian (`startedAt`, `plannedEndAt`, `pausedAt`, `leftAt`), khôi phục sau kill/reboot thành `interrupted` (`Phiên đã gián đoạn`) với `Tiếp tục` hoặc `Kết thúc`.
  - Tách riêng `elapsedWallSeconds` và `inAppFocusSeconds` (không đặt tên là "thời gian học thực").
  - Rời app / quay lại (`paused` → `resumed`) xử lý đúng ngưỡng từng mức (`Linh hoạt`: báo thời gian rời, không nhắc; `Tập trung thường`: >30s hiển thị 1 nhắc cục bộ khi quay lại, không chồng thông báo; `Cam kết`: >10s dừng `inAppFocusSeconds`, trừ quãng rời và hiện nút `Tiếp tục học`).
  - Thẻ hướng dẫn tự bật Android Digital Wellbeing Focus mode trung thực qua Android MethodChannel `mindclock/study_focus`, nói rõ **không khóa được app khác** và fallback khi thiết bị không có Digital Wellbeing.
  - Lưu cục bộ scoped theo `ownerScopeKey`, hoàn thành idempotent theo `sessionId`, tách biệt dữ liệu giữa các tài khoản (`F07`), không cộng XP/coin/streak cho thời gian hay camera.
  - Nối điểm vào từ màn `Hôm nay` (`Bắt đầu học` / `Quay lại phiên học`), tab `Luyện tập`, vẫn ưu tiên màn chuông reo `AlarmRingScreen` khi có báo thức đến giờ.
- **Ngoài phạm vi (giai đoạn sau):**
  - Camera chụp bài / kiểm tra khung hình, micro nhấn để nói, Live API.
  - AI trợ lý Socratic (`/v1/study/help`) và đồng bộ metadata phiên học lên server (`/v1/study/sessions`).
  - Mọi cơ chế Accessibility, overlay, VPN, device-admin, UsageStats hoặc lock task kiosk.
- **Dữ liệu/role/quyền liên quan:**
  - Khách local (`guest`) hoặc tài khoản online đều dùng được không cần mạng; dữ liệu phiên scoped theo `ownerScopeKey`.
  - Chỉ xin `POST_NOTIFICATIONS` khi người dùng tự bật tùy chọn nhắc ngoài app (không ép xin lúc khởi động).
- **Tài liệu chuẩn:** `docs/45 §§1–6`, `docs/05`, `docs/13`, `docs/27`, `docs/30`, `AGENTS.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| `SF-AC-01` | Người học vào từ `Hôm nay` (`Bắt đầu học`), chọn việc (hoặc để rỗng dùng `Học tự do`), chọn `25` phút hoặc tùy chỉnh `5–120` phút và mức tập trung | Timer lưu `startedAt`, `plannedEndAt`; đếm ngược tính từ mốc thời gian (`clock`), khóa màn/rời app quay lại trong `Linh hoạt` không mất mốc và không cộng thời gian ảo | `SF-TC-01` (`F01`) |
| `SF-AC-02` | App đang `running` hoặc `paused` rồi bị kill/mở lại (khôi phục từ `LocalKeyValueStore`) hoặc thiết bị mất mạng / token hết hạn | Lần khởi động kế tiếp chuyển phiên sang `interrupted` (`Phiên đã gián đoạn`), không cộng thêm thời gian tập trung lúc app tắt, cho `Tiếp tục` hoặc `Kết thúc`; `AlarmConfig` và `triggerEmergencyStop` vẫn hoạt động bình thường | `SF-TC-02` (`F02`) |
| `SF-AC-03` | App rời foreground `5s`, `11s`, `31s`, hoặc rời nhiều lần liên tiếp | `Linh hoạt`: chỉ báo thời gian rời, không nhắc ép. `Tập trung thường`: `<=30s` không nhắc; `>30s` hiện đúng 1 nhắc cục bộ khi quay lại (không chồng). `Cam kết`: `<=10s` không dừng; `>10s` dừng `inAppFocusSeconds`, trừ quãng rời và yêu cầu bấm `Tiếp tục học`. Không suy ra xao nhãng hay tên app khác | `SF-TC-03` (`F03`) |
| `SF-AC-04` | Người dùng bấm `Kết thúc` hoặc `Lưu phiên` nhiều lần / gặp retry khi lưu | Mỗi `sessionId` chỉ ghi đúng 1 bản ghi trong lịch sử cục bộ; không tự cộng XP/streak/coin cho thời gian học hay camera | `SF-TC-04` (`F07`) |
| `SF-AC-05` | Đăng xuất hoặc đổi tài khoản `A ↔ B` trong khi A có phiên dở hoặc lịch sử phiên | Tài khoản B không thấy phiên đang dở hay lịch sử của A; quay lại A mới thấy dữ liệu scoped của A; báo thức thiết bị giữ nguyên | `SF-TC-05` (`F07`) |
| `SF-AC-06` | Người dùng mở hướng dẫn Digital Wellbeing Focus mode khi thiết bị hỗ trợ hoặc không hỗ trợ | UI luôn nêu rõ MindClock không khóa app khác; gọi `mindclock/study_focus` mở cài đặt nếu có hoặc thông báo trung thực khi thiết bị không mở thẳng được Digital Wellbeing | `SF-TC-06` (`F08`) |
| `SF-AC-07` | Hiển thị ở `320/360/390/600 dp`, chữ `100%/200%`, TalkBack `Semantics`, chế độ Reduce Motion / số tĩnh | Timer, nút `Tạm nghỉ`, `Tiếp tục`, `Kết thúc` không tràn/che; có `Semantics` rõ ràng; số tĩnh không nhấp nháy từng giây khi Reduce Motion bật | `SF-TC-07` (`F09`) |
| `SF-AC-08` | Chuông báo thức đến giờ trong lúc người dùng đang ở `StudySpaceScreen` | `MindClockShellScreen` vẫn chuyển sang `AlarmRingScreen` với `Dừng khẩn cấp` hoạt động ngay, không làm hỏng phiên học đang lưu | `SF-TC-08` (`F02`) |

## Hợp đồng và trường hợp biên

- **State machine (`docs/45 §2`):** `draft → running ↔ paused → completed | endedEarly`; `running | paused → interrupted → running | endedEarly`.
- **Chỉ số lưu tách biệt:** `elapsedWallSeconds` (thời gian từ `startedAt` tới lúc kết thúc) và `inAppFocusSeconds` (thời gian tập trung trong app, đã trừ nghỉ và trừ quãng rời `>10s` ở chế độ `Cam kết`).
- **Quyền riêng tư:** `leftAt`, `returnAt` chỉ nằm ở local snapshot; không gửi server; camera/mic/AI hoàn toàn tắt và ngoài phạm vi 6A.
- **Bridge Android (`mindclock/study_focus`, version `1`):** `openDigitalWellbeingFocusSettings`, `getNotificationPermissionStatus`, `requestNotificationPermission`, `showSingleStudyReminder`, `cancelStudyReminder` — tách biệt hoàn toàn với `mindclock/alarm_scheduler` và kênh notification của `AlarmRingService`.

## Quyết định/mâu thuẫn

- `docs/45` chưa có điểm sửa trái ngược; quyết định thiết kế rõ: mở `StudySpaceScreen` từ card `Bắt đầu học` trên `Hôm nay` (và từ `Luyện tập`) như một stage đầy đủ của `MindClockShellScreen`, giữ nguyên bottom bar 3 tab chuẩn `Hôm nay / Luyện tập / Tôi` của `T014` & `T017`.
- Sửa thêm lỗi thiếu `MindClockIconKind.warning` trong `mindclock_icon.dart` (cùng thêm `play`, `pause`, `stop`) để toàn bộ màn hình cũ và mới biên dịch đồng bộ.
