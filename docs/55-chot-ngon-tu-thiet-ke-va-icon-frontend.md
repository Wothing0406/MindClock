# Chốt ngôn từ, thiết kế và quy chuẩn icon frontend MindClock

**Trạng thái ngày 14/11/2026:** đặc tả chuẩn hóa ngôn từ, design tokens và icon cho Flutter Android trước khi mở code `FE-S01` (`chưa có app Flutter/APK`). Tài liệu này tổng hợp và chốt một nguồn tra duy nhất từ [docs/05](05-ux-va-noi-dung-tieng-viet.md), [docs/13](13-he-thiet-ke-ui.md), [docs/27](27-quy-chuan-giao-dien-va-figma.md), [docs/30](30-ngon-ngu-va-tai-san-giao-dien.md), [docs/31](31-bao-thuc-thu-thach.md), [docs/45](45-khong-gian-hoc-va-che-do-tap-trung.md), [docs/46](46-pvp-ba-nhan-vat-luat-ui-asset-networking.md), [docs/52](52-ho-so-avatar-huy-hieu-va-lich-su.md) và [docs/53](53-quy-dinh-ten-avatar-va-noi-dung-nguoi-dung.md).

---

## 1. Chốt các nhãn từng mâu thuẫn (dùng thống nhất trong Flutter)

| Vị trí | Biến thể cũ trong docs/demo | Nhãn CHỐT cho code Flutter | Lý do & Quy tắc đi kèm |
| --- | --- | --- | --- |
| Nút chính màn chuông reo (`S07`) | `Bắt đầu` (`docs/04`, `13`) vs `Mở câu hỏi` (`docs/05`, `31`) | **`Mở câu hỏi`** | Mô tả đúng hành động mở đề sau chuông; tránh nhầm với `Bắt đầu học` của Không gian học (`docs/45`). |
| Nút an toàn màn chuông (`S07–S10`) | `Tắt khẩn cấp` (`docs/09`, `13`) vs `Tắt chuông` (`docs/05`) vs `Dừng khẩn cấp` (`docs/04`, `05`, `27`, `31`) | **`Dừng khẩn cấp`** | Dùng 1 tên duy nhất ở `S07–S10` (hoặc mở trong ≤1 thao tác); **không** dùng màu đỏ trừng phạt; luôn hiện nhãn chữ, không ẩn trong menu. |
| Nút hoãn (`S07`) | Có/không ở docs cũ | **`Hoãn 5 phút`** *(chỉ mode thường)* | Ẩn hoàn toàn ở chế độ `Báo thức thử thách` (`docs/31`). |
| Đường chụp ảnh (`S08` → `S09`) | `Chụp nháp` (`docs/05`, `31`) vs `Chụp bài` (`docs/27`, `30`) | Nút chọn ở `S08`: **`Chụp nháp`**; tiêu đề màn chụp `S09`: **`Chụp bài làm`**; nút hành động `S09`: **`Chụp lại`** · **`Gửi bài`** | Khớp `docs/05 §4`, `docs/30 §1`, `docs/31 §6`. Luôn đặt cạnh đường chữ `Viết cách làm`. |
| Đường bỏ qua chấm (`S08`/`S10`) | `Hoàn thành không chấm` vs `Làm sau` | **`Hoàn thành không chấm`** | `Làm sau` chỉ dùng **sau khi** người học đã dừng chuông ở `S07` hoặc hoãn ở Không gian học (`Để sau`), không thay thế `Dừng khẩn cấp` (`docs/23 §2`). |
| Cặp động từ thao tác → phản hồi | Chưa đồng bộ | `Lưu báo thức` → **`Đã lưu báo thức`**; `Gửi bài` → **`Đã nhận bài`**; `Lưu lịch` → **`Đã lưu lịch`** | Cùng một động từ gốc giữa nút và thông báo kết quả (`docs/27 §4`). |
| XP & mốc mẫu ở `demo/index.html` | `+15 XP mẫu`, `160 / 250 XP` | Bỏ hoàn toàn; dùng thang `docs/04`: **`+10 XP`** (đúng lần đầu), **`+6 XP`** (đúng sau gợi ý), **`+2 XP`** (hoàn thành không chấm có attempt server), **`0 XP`** (Dừng/Hoãn/offline) | Mốc `Hạng học tập`: Học viên `0`, Đồng `100`, Bạc `300`, Vàng `700`, Bạch Kim `1500`, Kim Cương `3000`. |
| Kiểu viết tiêu đề màn/tag | `LUYỆN TẬP · TOÁN 9` (`demo/index.html`) | **`Luyện tập · Toán 9`** (Title/Sentence case bình thường) | Tránh chữ in hoa toàn bộ giãn rộng (`docs/27 §1`). |
| Vùng chạm mục tiêu | `44 CSS px` ở web demo (`docs/51`) | **`≥ 48×48 dp`** mọi nút/icon bấm được trên Flutter | Chuẩn accessibility Android & `docs/05 §6`, `docs/27 §2`, `docs/46 §4`. |

---

## 2. Quy chuẩn giọng nói, từ cấm và tách bạch thuật ngữ

### 2.1. Quy tắc viết chuỗi tiếng Việt (`vi-VN`)

- **Ngắn và chỉ hành động:** nhãn nút `2–4 từ`, thông báo một ý rõ ràng (`docs/30 §1`).
- **Thông báo lỗi gồm 2 phần:** *(chuyện gì đang xảy ra)* + *(người học làm gì tiếp)*. Không dùng câu mơ hồ kiểu `"Có lỗi xảy ra"`. Không dùng toast tự biến mất cho lỗi cần người dùng xử lý (`docs/27 §4`).
- **Minh bạch giả lập & offline:** phần nào chưa nối server hoặc chưa xác minh phải gắn nhãn **`Bản xem thử`**, **`Dữ liệu mẫu`** hoặc **`Chưa đồng bộ`**. Không dùng phần trăm giả (`"Đang chấm 80%"`) khi chờ API.
- **Giọng Không gian học (`docs/45 §3`):** hỗ trợ 3 mức tự chọn (`Êm`, `Rõ ràng`, `Nghiêm túc`); mức `Nghiêm túc` vẫn lịch sự, không mắng hay dọa.

### 2.2. Bảng từ và mẫu câu CẤM dùng trong app

| Nhóm cấm | Ví dụ tuyệt đối tránh (`docs/05, 27, 30, 45, 52, 53`) | Lý do | Mẫu thay thế chuẩn |
| --- | --- | --- | --- |
| **Phán xét / gán nhãn** | `lười`, `thất bại`, `ngu`, `yếu kém`, `học bá`, `siêu chiến thần`, `bị bắt gặp`, `phạt`, `tụt hạng`, `linh thú suy dinh dưỡng` | Không tạo xấu hổ hoặc suy đoán năng lực (`docs/05`, `30`, `41`, `45`) | `Bước này cần xem lại.`, `Bạn vừa ra khỏi MindClock 2 phút. Tiếp tục việc đang làm?` |
| **Quy kết gian lận / giám sát** | `gian lận`, `AI đang nhìn bạn`, `đã tỉnh táo`, `chứng minh đã thức` | AI không kết luận gian lận; tắt chuông/camera không chứng minh đã thức (`docs/31`, `45`, `52`) | `Mình chưa đọc rõ bài làm`, `Hoàn thành thử thách` |
| **Phóng đại / hứa hẹn sai** | `AI quét và hiểu mọi nét chữ`, `AI chấm công tâm tuyệt đối`, `chắc chắn tỉnh táo`, `đã đảm bảo đúng giờ`, `không thể tắt chuông` | Không hứa vượt khả năng AI và hệ điều hành (`docs/30`, `31`, `47`, `53`) | `Ảnh này sẽ được gửi để AI đọc và phản hồi.`, `Đã sẵn sàng` *(chỉ khi OS schedule thành công)* |
| **Khẩu hiệu trong màn dùng hằng ngày** | `Đánh thức thiên tài trong bạn`, `Chinh phục thử thách trí tuệ đỉnh cao`, `Tôi nhất định sẽ làm được` | Slogan chỉ nằm ở pitch/giới thiệu, không chen vào thao tác buổi sáng (`docs/04`, `30`) | `Báo thức tiếp theo: 06:30`, `Thử một câu Toán` |
| **Thuật ngữ game hóa / Anh hóa ở tác vụ học** | `Quest`, `Battle pass`, `AI-powered`, `ELO` (ở màn báo thức/onboarding) | Học sinh lớp 9–12 cần tiếng Việt tự nhiên (`docs/27 §1`) | `Một câu ôn ngắn`, `Giao hữu`, `Bảng tuần`, `Điểm đấu trường` |

### 2.3. Tách bạch 6 khái niệm dễ nhầm trong UI

1. **XP & Hạng học tập (`Tôi`):** tích lũy từ nỗ lực học tập cá nhân được server xác nhận (`+10/+6/+2`), chỉ mang tính trang trí/động viên cá nhân (`Học viên → Kim Cương`), **không** phải điểm thi đấu.
2. **Điểm đấu trường / RP & Huy hiệu hạng (`M3`):** chỉ tính từ trận ranked hợp lệ theo `{Môn · Khối · Mùa}`, hiển thị kèm nhãn chữ + bậc `1–5` (ví dụ `Đồng 4 · Toán 9`), **tách hẳn** với XP bằng thẻ riêng và tooltip: `"XP ghi nhận quá trình học; RP chỉ tính từ trận có hạng."` (`docs/23 §4`, `27 §4`, `52 §1`).
3. **Avatar hồ sơ:** 1/6 avatar mặc định (hoặc ảnh tải lên ở M3 sau khi duyệt) đại diện người học ở tab `Tôi`/bảng.
4. **Khung avatar:** viền trang trí quanh avatar (`Thường`, `Đồng`..`Tinh Anh`), **không** biểu thị RP nếu chưa có rank (`docs/52 §1`).
5. **Nhân vật đấu (`M3`):** concept trong Đấu trường (`Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bối Tháp`/`Hàn Bối Pháp`), khóa theo trận, không thay avatar hồ sơ.
6. **Uy tín (`M3`):** trạng thái nội bộ chống quấy rối (`normal/review/limited`), **không** tạo điểm uy tín công khai và **không bao giờ** trừ vì sai bài, `uncertain` hay `Dừng khẩn cấp` (`docs/52 §4`).

---

## 3. Bộ chuỗi UI chuẩn cho Flutter (`AppStrings`)

### 3.1. Điều hướng, Onboarding & Màn hình chính (`S01–S06`, `L01`, `S11–S12`)

| Nhóm / Màn | Key gợi ý | Nội dung tiếng Việt chuẩn |
| --- | --- | --- |
| **Tab bar** | `navToday`, `navPractice`, `navArena`, `navMe` | `Hôm nay` · `Luyện tập` · `Đấu trường` *(ẩn nếu `!cohortArenaEnabled`)* · `Tôi` |
| **S01–S02 / A01** | `welcomeTitle`, `welcomeDesc`, `tryGuest`, `createAccount`, `signIn`, `later`, `strongPasswordHint`, `passwordMismatch` | `"Dậy đúng giờ. Nghĩ bằng chính mình."` · `"Một câu ôn ngắn theo lịch học, mỗi buổi sáng."` · `Dùng thử không cần tài khoản` · `Tạo tài khoản` · `Đăng nhập` · `Để sau` · `"Mật khẩu cần tối thiểu 8 ký tự gồm chữ hoa, chữ thường và số hoặc ký tự đặc biệt."` · `"Mật khẩu xác nhận chưa khớp."` |
| **S03–S05** | `setupSkip`, `selectLevelAndSubjects`, `importTimetable`, `timetablePreviewConfirm`, `pickDefaultAvatar`, `subjectNoApproved`, `alarmOnlyOption`, `saveTimetable`, `timetableSaved`, `wakeSuggestion` | `Để sau` · `Chọn trình độ và môn học` · `Tải TKB có sẵn` · `"Kiểm tra lại các tiết trước khi lưu vào hệ thống."` · `Chọn avatar có sẵn` · `"Môn này chưa có câu ôn sáng."` · `Chỉ báo thức` · `Lưu lịch` · `Đã lưu lịch` · `"Đề xuất {time} · kịp tiết {classTime} theo thời gian bạn nhập"` (`Dùng giờ này` / `Sửa thời gian`) |
| **S04 Hôm nay** | `nextAlarm`, `addCustomAlarm`, `todaySubjects`, `todayReviewOne`, `noSubjectToday`, `pickReview`, `unsyncedProgress` | `"Chuông tiếp theo: {time}, {weekday}"` · `Thêm báo thức tùy chọn giờ` · `Môn/việc hôm nay` · `Một điều cần ôn lại` · `"Hôm nay chưa có môn trong lịch."` · `Chọn câu ôn` · `Chưa đồng bộ` |
| **S06 Báo thức & Vòng quay 24h** | `bedtimeLabel`, `wakeTimeLabel`, `tonightLabel`, `tomorrowLabel`, `sleepDuration`, `sleepGoalShortNotice`, `alarmOptionsTitle`, `soundAndHaptics`, `challengeModeTitle`, `challengeModeNotice`, `saveAlarm`, `alarmSaved`, `testRing`, `alarmReady` | `Giờ đi ngủ` · `Giờ thức dậy` · `Đêm nay` · `Ngày mai` · `"{hours} giờ"` · `"Lịch trình này chưa đạt mục tiêu ngủ bạn đặt."` *(không chẩn đoán y tế, không gắn chữ Sức khỏe của hãng khác)* · `Tùy chọn báo thức` · `Âm thanh & Cảm ứng` · `Báo thức thử thách` · `"Không có Hoãn. Dừng khẩn cấp luôn có."` · `Lưu báo thức` · `Đã lưu báo thức` · `Thử chuông` · `Đã sẵn sàng` |
| **S11 Tôi** | `xpAwarded`, `weekCompleted`, `studyRankLabel`, `arenaRpLabel`, `editProfile`, `alarmHistory` | `"+{xp} điểm kinh nghiệm"` · `"Bạn đã hoàn thành {n} buổi sáng tuần này."` · `Hạng học tập` · `Điểm đấu trường` · `Sửa hồ sơ` · `Lịch sử báo thức` |
| **S12 Cài đặt** | `reportGrading`, `exportData`, `deleteAccount`, `privacyTitle` | `Báo kết quả chấm chưa đúng` · `Xuất dữ liệu` · `Xóa tài khoản` · `Quyền riêng tư` |

### 3.2. Luồng Chuông → Làm bài → Xem ảnh → Phản hồi (`S07–S10`)

| Màn / Tình huống | Nội dung tiếng Việt chuẩn |
| --- | --- |
| **S07 Chuông reo** | `{time}` · `Một câu {subject}` · Nút chính: `Mở câu hỏi` · Nút phụ: `Dừng khẩn cấp` · *(nếu mode thường thêm)* `Hoãn 5 phút` |
| **S07 Không có câu tải sẵn** | `"Chuông vẫn hoạt động. Câu ôn sẽ có khi kết nối lại."` · `Dừng khẩn cấp` · *(sau khi đã dừng)* `Bắt đầu ôn sau` |
| **S08 Làm bài** | `Chọn/nhập đáp án` · `Viết cách làm` · `Chụp nháp` · `Gửi bài` *(disabled khi chưa nhập lý do)* · `Dừng khẩn cấp` |
| **S08 Offline / Nháp** | `"Không có mạng. Chuông vẫn hoạt động; bài này chưa được chấm."` · `Hoàn thành không chấm` · `Lưu trên máy để gửi sau` · Khi online lại: `"Gửi bài này để nhận nhận xét?"` |
| **S09 Xem ảnh** | Tiêu đề: `Chụp bài làm` · Minh bạch AI: `"Ảnh này sẽ được gửi để AI đọc và phản hồi. MindClock không lưu ảnh mặc định."` · Nút: `Chụp lại` · `Gửi bài` |
| **S09 Ảnh lỗi** | `"Ảnh chưa gửi được. Hãy chụp lại hoặc chọn ảnh nhỏ hơn."` · `Chụp lại` |
| **S08/S09 Đang chấm** | `"Đang đọc từng bước bài làm…"` · `Hủy chấm và kết thúc` *(không % giả)* |
| **S10 Đúng (`correct`)** | `"Bài làm đúng. Xem cách giải."` hoặc `"Bạn làm đúng rồi!"` · `"Bạn đã biến đổi đúng ở bước …"` |
| **S10 Sai lần 1–2 (Thử thách)** | `"Bài này chưa đúng. Bạn có thể thử lại."` · Nút: `Thử lại` *(không có `Xem gợi ý`, không lộ bước sai/đáp án)* |
| **S10 Sai lần 3+ (Thử thách)** | `"Hãy xem lại bước này…"` / `"Gợi ý: hãy xét …"` · Nút: `Xem gợi ý` · `Thử lại` · *(sau kết thúc)* `Xem lời giải` |
| **S10 Chưa đủ rõ (`uncertain`)** | `"Mình chưa đọc rõ bài làm. Bạn có thể chụp lại dưới ánh sáng tốt hơn hoặc nhập đáp án."` · `Chụp lại` · `Viết cách làm` · `Hoàn thành không chấm` |
| **S10 Timeout / Lỗi AI** | `"Chưa thể chấm lúc này. Bạn vẫn có thể kết thúc báo thức."` · `Hoàn thành không chấm` · `Dừng khẩn cấp` |

### 3.3. Lỗi quyền hệ thống & Không gian học & Hồ sơ/Đấu trường (`P1/M3`)

| Tình huống | Nội dung tiếng Việt chuẩn |
| --- | --- |
| **Thiếu quyền báo thức chính xác** | `"Thiết bị chưa cho phép báo thức đúng giờ."` · `Mở cài đặt quyền` |
| **Thiếu quyền camera** | `"Bạn có thể viết cách làm bằng chữ."` · `Viết cách làm` · `Mở cài đặt` |
| **Token hết hạn** | `"Cần đăng nhập lại để đồng bộ tiến độ."` · `Đăng nhập` · `Dùng báo thức` |
| **Không gian học (`docs/45`)** | `Bắt đầu học` · `"Bạn đang học: {task}"` · `"Còn {minutes} phút"` · `Tạm nghỉ` · `Kết thúc` · `Hỏi MindClock` · `"Bạn vừa ra khỏi MindClock {minutes} phút. Tiếp tục việc đang làm?"` · `"Mình chỉ gợi ý bước tiếp theo. Bạn đã thử cách nào?"` · `Lưu phiên` |
| **Hồ sơ & Nội dung (`docs/52–53`)** | `"Chọn ảnh của bạn hoặc dùng avatar có sẵn. Ảnh công khai cần được duyệt."` · `"Tên hiển thị cần 3–20 ký tự và không chứa thông tin liên hệ."` · `"Ảnh đang được xem lại. Người khác vẫn thấy avatar mặc định."` · `"Đã nhận báo cáo. Chúng tôi sẽ xem nội dung này."` |
| **Đấu trường (`docs/23, 46` — M3)** | `Đấu trường học tập` · `Giao hữu không tính hạng` · `"Thi đấu là tùy chọn"` · `"Thông số đang thử nghiệm"` · `"Đang kiểm tra bài làm"` · `"Chưa tìm thấy bạn cùng môn. Thử giao hữu với mã mời hoặc luyện một mình."` · `"Trận này chưa đủ cơ sở tính hạng; chúng mình sẽ cho bạn xem cách giải."` · `Ẩn tôi khỏi bảng` |

---

## 4. Chốt Design Tokens, Layout & Accessibility (`MindClockTheme`)

| Nhóm | Giá trị chốt (`docs/13 §2, §5`, `docs/27 §2`, `docs/30`) | Ghi chú khi triển khai Flutter |
| --- | --- | --- |
| **Màu nền & chữ ban ngày** | `paper #F7F7F2`, `surface #FFFFFF`, `ink #1B2741`, `inkMuted #526078`, `outline #D7DFE5` | Nền giấy ấm ban ngày (`ink/paper ≈ 13.8:1`, `inkMuted/paper ≈ 5.9:1`). |
| **Màu chuông nền đêm** | `night #101A30`, `nightSurface #1C2944`, `nightText #F7FAFF` | Dùng cho `S07` chuông reo (`nightText/night ≈ 16.6:1`); hỗ trợ giao diện tối học buổi tối ở `F02` không ép độ sáng. |
| **Màu nhấn & trạng thái** | `primary #126F73` *(chữ trắng trên nền primary ≈ 5.9:1)*, `sunrise #F4B95F`, `error #B23A48`; màu phụ dịu tham khảo từ prototype: `primarySoft #E7F2EF`, `sunriseSoft #FCE6BC` | Đo lại độ tương phản thực tế cho mọi biến thể nút/disabled trước khi khóa (`≥4.5:1` chữ thường, `≥3:1` chữ lớn & viền điều khiển). `EmergencyDismiss` **không** dùng `error #B23A48`. |
| **Typography** | 1 font hỗ trợ tiếng Việt đầy đủ (đề xuất `Be Vietnam Pro` sau xác nhận licence/glyph; fallback `Noto Sans`). Chỉ dùng 3 weight: `400 / 600 / 700`. | Giờ chuông `56–64 sp`, tiêu đề màn `26–28 sp`, tiêu đề mục `18–20 sp`, nội dung `16 sp`, chú thích `14 sp`, tối thiểu `≥12 sp`. Không cố định chiều cao widget chứa chữ. |
| **Khoảng cách & Bo góc** | Lưới `4 dp`; khoảng `8 / 12 / 16 / 24 / 32 dp`; lề `20 dp` (màn hẹp) / `24 dp` (rộng). Bo góc 3 cấp: `8 dp` chip, `14–16 dp` nút/card, `24 dp` tờ đề. | Không bo đồng loạt mọi thẻ; vùng nội dung ưu tiên khoảng trắng thay vì nhiều viền bóng đổ. |
| **Chuyển động** | Nhấn nút `120–180 ms`, chuyển màn `180–260 ms`, vòng đồng hồ `≤ 400 ms` (`opacity`/`transform`, không blur toàn màn). | Khi `MediaQuery.disableAnimations` (`Reduce Motion`) bật: chuyển tức thì, ảnh tĩnh. **Không** animation lặp trên màn báo thức. |
| **Responsive & Trợ năng** | Thiết kế/kiểm tại `320 / 360 / 390 / 600 dp` và text scale `100% / 150% / 200%`. | Vùng chạm `≥48×48 dp`; TalkBack đi theo thứ tự `giờ → đề → hành động chính → hoãn → Dừng khẩn cấp`; bàn phím mở không che `Gửi bài` hoặc `Dừng khẩn cấp`. |

---

## 5. Chốt Quy chuẩn Icon & Asset UI cho Flutter

### 5.1. Nguyên tắc chọn bộ icon

- **Dùng 1 bộ icon vector nét duy nhất** (`24×24 dp`, nét `2 px`, đầu nét bo tròn), đồng nhất hình học `outline` (chưa chọn) và `filled` (tab đang chọn — kèm nhãn chữ luôn hiện).
- **Cấm tuyệt đối:** dùng emoji hệ thống thay icon; trộn nhiều bộ icon; dùng biểu tượng kiếm/khiên/vương miện/tia sét trên màn báo thức hoặc màn làm bài (`docs/27 §3`); dùng logo Google/Gemini cho nút chấm (`docs/30 §3`).
- **Lựa chọn thư viện Flutter (cần chốt trong `T013` trước khi thêm `pubspec.yaml`):**
  1. **Khuyến nghị — SVG subset từ Lucide (`ISC license`):** nét đồng đều `24×24`, `stroke-width: 2`, bo đầu tròn, không bị pha style Sharp/Two-tone, bundle chỉ những SVG thật sự dùng qua `flutter_svg`.
  2. **Dự phòng — Material Symbols Rounded (`Apache-2.0`):** chỉ dùng 1 biến thể `Rounded` (weight `400`, optical size `24`) và không trộn với Material Icons mặc định.

### 5.2. Danh mục Icon & `semanticLabel` theo màn hình

| Vị trí / Chức năng | Hình học chuẩn (`docs/27 §3`) | Trạng thái | `semanticLabel` tiếng Việt |
| --- | --- | --- | --- |
| Tab `Hôm nay` | Đồng hồ kim đơn | Outline / Filled + nhãn `primary` | `Tab Hôm nay` |
| Tab `Luyện tập` | Quyển vở mở / bút trên trang | Outline / Filled + nhãn `primary` | `Tab Luyện tập` |
| Tab `Đấu trường` *(chỉ hiện theo cohort)* | Hai thẻ đối diện hoặc hai chấm đối xứng (không dùng kiếm) | Outline / Filled + nhãn `primary` | `Tab Đấu trường` |
| Tab `Tôi` | Hình người đơn giản | Outline / Filled + nhãn `primary` | `Tab Tôi` |
| Câu hôm nay (`S04`/`S08`) | Quyển vở | Tĩnh (trang trí thì ẩn TalkBack) | `Câu hỏi hôm nay` |
| Gợi ý (`S10` sau lần sai 3) | Bóng đèn nét nhỏ | Active / Disabled | `Xem gợi ý` |
| Chụp nháp (`S08`/`S09`) | Máy ảnh | Active / Disabled | `Chụp nháp bài làm` |
| Viết cách làm (`S08`) | Bàn phím hoặc bút | Active | `Nhập đáp án và cách làm` |
| Dừng khẩn cấp (`S07–S10`) | Hình vuông dừng (`stop`) | Luôn active khi chuông chạy | `Dừng khẩn cấp` |
| Hoãn 5 phút *(mode thường)* | Đồng hồ báo lại | Chỉ hiện ở mode thường | `Hoãn 5 phút` |
| Quyền riêng tư / Xóa dữ liệu | Ổ khóa | Active | `Quyền riêng tư và dữ liệu` |
| Trạng thái Đúng (`S10`) | Dấu tích trong vòng tròn | Luôn kèm chữ `Bài làm đúng` | `Kết quả đúng` |
| Trạng thái Sai (`S10`) | Dấu chấm than nhẹ (`info/alert-circle`) | Luôn kèm chữ `Chưa đúng` | `Kết quả chưa đúng` |
| Trạng thái Chưa rõ (`S10`) | Dấu hỏi trong vòng tròn | Luôn kèm chữ `Chưa đọc rõ` | `Chưa đủ rõ để chấm` |
| Ngoại tuyến (`OfflineBanner`) | Đám mây gạch chéo | Luôn kèm chữ `Không có mạng` | `Đang ngoại tuyến` |
| Thiếu quyền OS (`PermissionStatus`) | Tam giác chú ý dịu (không đỏ gắt) | Luôn kèm hướng dẫn mở cài đặt | `Thiếu quyền báo thức` |
| Giờ đi ngủ (`SleepWakeDial`) | Giường / Trăng khuyết nét mảnh `24×24` | Active / Drag handle | `Điều chỉnh giờ đi ngủ` |
| Giờ thức dậy (`SleepWakeDial`) | Chuông báo thức / Mặt trời nét mảnh `24×24` | Active / Drag handle | `Điều chỉnh giờ thức dậy` |
| Tải TKB có sẵn (`S03`/`S05`) | Tệp tải lên / Lịch tuần nét mảnh | Active / Disabled | `Tải thời khóa biểu có sẵn` |
| Âm thanh báo thức (`S06`) | Nốt nhạc hoặc loa nét mảnh | Active / Muted | `Chọn âm thanh và cảm ứng báo thức` |
| Hiện / ẩn mật khẩu (`A01`) | Con mắt mở / gạch chéo | Toggle ≥48×48 dp | `Hiện mật khẩu` / `Ẩn mật khẩu` |
| Không gian học (`F01–F04`) | Đồng hồ bấm giờ / Tạm dừng / Kết thúc | Active | `Bắt đầu phiên học` / `Tạm nghỉ` / `Kết thúc phiên học` |
