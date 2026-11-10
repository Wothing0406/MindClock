# Hệ thiết kế UI MindClock

**Mục tiêu thị giác:** một buổi sáng rõ ràng và dễ bắt đầu, kết hợp hình ảnh mặt đồng hồ với nét giấy học tập. Trò chơi hóa là lớp động viên sau khi hoàn thành, không biến báo thức thành màn game chói mắt. Nền tảng chính: Flutter Android; dashboard web tương lai dùng cùng token nhưng bố cục riêng.

## 1. Hướng nghệ thuật

- **Chủ đề:** “Bình minh trên trang vở”. Vòng tròn của đồng hồ là hình nhận diện; đường kẻ vở và dấu bút chì chỉ xuất hiện ở màn bài tập/phản hồi.
- **Hai nhịp sáng/tối:** trước khi dậy dùng nền xanh đêm ít chói; sau khi hoàn thành chuyển sang nền sáng ấm. Thay đổi trạng thái bằng ánh sáng và vị trí, không nháy liên tục.
- **Cảm giác:** bình tĩnh, tập trung, trẻ trung nhưng đủ nghiêm túc cho học sinh lớp 9–12. Không dùng neon RPG, biểu tượng kiếm/khiên chiếm giao diện học, hoặc mascot chen vào lúc chuông reo.
- **Điểm nhấn duy nhất:** vòng đồng hồ tiến trình ở trang chủ và màn chuông. Những phần còn lại tối giản để đọc nhanh.

## 2. Design tokens đề xuất

Giá trị dưới đây là **bản v1 để thiết kế và coding**, cần đo tương phản trên màn hình thật trước khi khóa. Tất cả giá trị nằm trong một nguồn token, widget không tự viết màu/khoảng cách tùy ý.

| Token | Giá trị | Vai trò |
| --- | --- | --- |
| `ink` | `#1B2741` | Chữ chính nền sáng |
| `inkMuted` | `#526078` | Chữ phụ nền sáng |
| `paper` | `#F7F7F2` | Nền ban ngày |
| `surface` | `#FFFFFF` | Mặt nội dung |
| `night` | `#101A30` | Nền báo thức |
| `nightSurface` | `#1C2944` | Mặt nội dung nền tối |
| `nightText` | `#F7FAFF` | Chữ nền tối |
| `primary` | `#126F73` | Hành động chính, tiến độ |
| `sunrise` | `#F4B95F` | Mốc hoàn thành, vòng đồng hồ |
| `error` | `#B23A48` | Lỗi cần chú ý; luôn kèm chữ/biểu tượng |
| `outline` | `#D7DFE5` | Viền và đường kẻ nhẹ |

**Typography:** ưu tiên một font hỗ trợ tiếng Việt đầy đủ, ví dụ Be Vietnam Pro nếu kiểm tra giấy phép, glyph và bundle; fallback Noto Sans/Android sans. Chữ số giờ dùng cùng font với trọng lượng đậm để tránh tải font thứ hai. Cỡ gợi ý: giờ báo thức 56–64sp; tiêu đề 28sp; tiêu đề phụ 20sp; nội dung 16sp; chú thích 14sp; nút 16–18sp. Tôn trọng text scaling của hệ điều hành; không cố định chiều cao làm cắt chữ.

Đã tính thử tương phản cho các cặp chính: `ink/paper` ≈ 13.8:1, `inkMuted/paper` ≈ 5.9:1, chữ trắng/`primary` ≈ 5.9:1, `nightText/night` ≈ 16.6:1. Khi coding vẫn cần đo lại trên các biến thể nút, disabled state và màn hình thật.

**Không gian:** lưới 4dp; khoảng chính 8/12/16/24/32dp; lề màn hình 20dp ở điện thoại hẹp, 24dp ở điện thoại rộng. Bo góc có ba cấp 8/16/24dp; vòng đồng hồ tròn. Không áp cùng một bo góc cho mọi thứ.

**Chuyển động:** nhấn nút 120–180ms; chuyển màn 180–260ms; vòng đồng hồ chuyển trạng thái tối đa 400ms. Tắt hoặc giảm chuyển động khi người dùng bật “giảm chuyển động”. Không dùng animation tự chạy lặp trên màn báo thức.

## 3. Bố cục theo màn

| Màn | Bố cục chính | Ưu tiên thị giác |
| --- | --- | --- |
| Trang chủ | Vòng đồng hồ phía trên; báo thức kế tiếp; thẻ môn ngày mai; tiến độ ở dưới | Giờ reo kế tiếp rõ nhất |
| Thiết lập báo thức | Chọn giờ lớn, ngày lặp, quyền; nút lưu cố định cuối màn | Biết đã được OS cho phép hay chưa |
| Chuông reo | Nền đêm; giờ cực lớn; câu hỏi một đoạn; nút Bắt đầu; Hoãn/Tắt ở vùng cuối | Dễ thấy Tắt khẩn cấp kể cả chữ phóng to |
| Làm bài | Nền sáng dịu; đề trong thẻ giấy; một gợi ý; chụp bài | Câu hỏi, không phải đồng hồ đếm ngược |
| Xem ảnh | Ảnh chiếm vùng chính, có khung cắt, chỉ dẫn ánh sáng | Xác nhận ảnh trước khi gửi |
| Phản hồi | Trích bước AI đã đọc, đánh dấu bước cần xem; gợi ý một câu | “Tôi cần sửa gì?” |
| Tiến bộ | Biểu đồ 7 ngày, số buổi, chủ đề nên ôn; XP thứ yếu | Tiến bộ cá nhân, không áp lực thứ hạng |

## 4. Component inventory để Flutter coding

`ClockRing`, `NextAlarmCard`, `SubjectChip`, `QuestionPaper`, `HandwritingPreview`, `StepFeedback`, `HintPanel`, `ProgressWeek`, `PrimaryAction`, `SecondaryAction`, `EmergencyDismiss`, `PermissionStatus`, `OfflineBanner`, `PetBadge` (M3). Mỗi component có trạng thái `default/pressed/disabled/loading/error` nếu tương ứng; mọi control có semantic label và key ổn định để test.

**Quy tắc tương tác:** nút hành động chính nằm trong vùng ngón cái, đủ lớn; “Tắt khẩn cấp” luôn có nhãn chữ, không ẩn trong menu ba chấm. `EmergencyDismiss` không dùng màu đỏ trừng phạt, vì đó là hành động an toàn. Camera chỉ bật sau thao tác rõ ràng. Không hỏi quyền thông báo/camera/ảnh cùng lúc khi onboarding.

## 5. Accessibility và kiểm tra hình ảnh

- Mục tiêu tương phản: văn bản thường ít nhất 4.5:1, chữ lớn và thành phần điều khiển ít nhất 3:1; đo thực tế cho mọi cặp token trước khi dùng.
- Thiết kế tại 320dp, 360dp, 390dp, 600dp; cỡ chữ hệ thống 100%, 150%, 200%. Nút tắt không bị khuất bởi bàn phím hoặc camera preview.
- Trạng thái đúng/sai/chưa rõ có biểu tượng + văn bản, không chỉ xanh/đỏ.
- TalkBack đi theo thứ tự: giờ → đề → hành động chính → hoãn → tắt; thông báo chấm không đọc lại toàn bộ màn hình.
- Ảnh bài làm có hướng dẫn chụp dưới ánh sáng tốt và nhận biết ảnh mờ trước gửi nếu có thể; không tự sửa nội dung lời giải trong ảnh.
- Khi có bản UI, chụp screenshot trên thiết bị thật cho mọi trạng thái, đánh giá cùng người dùng mục tiêu lúc sáng sớm.

## 6. Dashboard web tương lai

Nếu triển khai giáo viên/phụ huynh trên web, có thể dùng React/Next.js nhưng **không dùng UI web để giả báo thức hệ thống**. Dashboard ưu tiên bảng chủ đề, mẫu số, lọc tuần, trạng thái dữ liệu chưa đủ, quyền xem rõ ràng. Dùng cùng màu/font nhưng bố cục rộng và không sao chép giao diện điện thoại. Khi quyết định stack web, bổ sung skill và quy tắc web lúc đó.

