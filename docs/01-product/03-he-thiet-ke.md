# Hệ thiết kế giao diện và asset

**Định hướng:** “bình minh trên trang vở”, tối giản, bình tĩnh, đọc được khi mới thức. Trọng tâm trên giờ báo/câu hỏi, game là lớp phụ. Không emoji hệ thống, gradient/neon RPG lấn nội dung, mascot quấy rầy lúc chuông reo hoặc lời phóng đại. **Nguồn code hiện có:** [`mindclock_theme.dart`](../../app/lib/ui/core/theme/mindclock_theme.dart), [`app_strings.dart`](../../app/lib/ui/core/strings/app_strings.dart); task UI phải so token thực tế với bảng dưới và ghi quyết định khi đổi.

## Tokens mục tiêu v1

| Token | Hex | Dùng cho |
| --- | --- | --- |
| `ink` | `#1B2741` | Chữ chính trên nền sáng |
| `inkMuted` | `#526078` | Chữ phụ |
| `paper` | `#F7F7F2` | Nền ngày |
| `surface` | `#FFFFFF` | Thẻ nội dung |
| `night` | `#101A30` | Màn chuông ít chói |
| `nightSurface` | `#1C2944` | Thẻ nền tối |
| `nightText` | `#F7FAFF` | Chữ nền tối |
| `primary` | `#126F73` | Hành động chính/tiến độ |
| `sunrise` | `#F4B95F` | Hoàn thành/vòng đồng hồ |
| `error` | `#B23A48` | Lỗi, luôn kèm chữ/icon |
| `outline` | `#D7DFE5` | Viền nhẹ |

Lưới 4dp; spacing 8/12/16/24/32dp; lề 20dp ở 320–390dp; radius 8/16/24dp. Một font hỗ trợ dấu tiếng Việt đầy đủ, kiểm license trước bundle; cỡ nội dung 16sp, chú thích tối thiểu 14sp, giờ chuông 56–64sp, nút 16–18sp. Không khóa chiều cao khi text scaling tăng 200%.

## Component và màn

| Component | Trạng thái cần thiết | Ghi chú test |
| --- | --- | --- |
| `ClockRing`, `NextAlarmCard` | chưa có/lưu local/OS đã lập lịch/cần quyền/đang reo | Thời gian chữ rõ, vòng chỉ trang trí. |
| `AlarmEditor`, `PermissionStatus`, `EmergencyDismiss` | default/loading/error/disabled phù hợp | Dừng khẩn cấp luôn hiện, chạm được, semantic label rõ. |
| `QuestionPaper`, `AnswerEditor`, `PhotoPreview` | loading/empty/offline/ready/timeout | Đề ưu tiên diện tích; camera có đường chữ thay thế. |
| `StepFeedback`, `HintPanel` | correct/incorrect/uncertain | Không dùng màu duy nhất; nội dung giải thích từng bước. |
| `StudyTimer`, `TaskCard`, `AiHelpCard` | running/paused/background/finished/offline/rate-limit | Không animation camera hoặc avatar AI giả hiện diện. |
| `ProfileCard`, `AvatarPicker` | private/public-opt-in/upload-review/rejected | Avatar mặc định và ảnh upload; khung rank/badge tách nhau. |

## Motion và hiệu năng

Nhấn nút 120–180ms, chuyển màn 180–260ms, đổi trạng thái đồng hồ ≤400ms; không lặp animation nặng trên màn báo thức. Tôn trọng cài đặt giảm chuyển động; có state tĩnh tương đương. Asset 2D chỉ tải khi vào tính năng game; pre-cache sprite cần thiết trước trận, không gọi mạng/AI trong frame loop. Khi thiết kế animation, ghi số frame, kích thước, memory, fallback máy yếu; đo frame time trên Android mục tiêu trước merge. Art nghiên cứu ở [game asset](../04-game/02-nhan-vat-asset.md).

## Accessibility và quy tắc nội dung

Mục tiêu tối thiểu: chữ thường 4.5:1, chữ lớn/icon điều khiển 3:1; kiểm **cặp thực trong app**, không chỉ token đơn lẻ. Kích thước chạm đủ dùng, thứ tự TalkBack giờ → nội dung → hành động → Dừng; `semanticLabel` cho icon, trạng thái và nút chiêu. Thử 320/360/390/600dp, font 100/150/200%, bàn phím mở, nền tối, Reduce Motion. Dùng SVG/vector/asset có license, không emoji. Màn học dùng văn phong ngắn, cụ thể; không dùng văn quảng cáo hay đổ lỗi cho học sinh.

## Bàn giao thiết kế

Mỗi màn cần frame Figma hoặc ảnh duyệt (nếu có), tên screen/state, component/token, hành động, empty/error/offline/permission, accessibility và asset provenance. AI không được tự lấp màn thiếu bằng web prototype; nếu chưa có thiết kế, dùng component hệ thống hiện có và ghi quyết định trong task. Kiểm ảnh thực trên Android trước khi gọi hoàn chỉnh.
