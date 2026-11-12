# Không gian học và chế độ tập trung — đặc tả để coding

**Trạng thái:** thiết kế mới, chưa có chức năng chạy. **Nền tảng đầu:** Android. **Ưu tiên:** sau lát cắt báo thức P0; bản demo có thể dùng đồng hồ học cục bộ trước AI/camera. Tài liệu này là nguồn chuẩn cho phiên tự học, rời app, camera và trợ lý học. Không gian học không thay thế báo thức; có thể vào từ màn `Hôm nay` sau khi chuông kết thúc hoặc tự mở bất cứ lúc nào.

## 1. Mục đích và ranh giới

Người học chọn **một việc cụ thể** và khoảng thời gian, bắt đầu một phiên tập trung, được hỏi gợi mở khi cần và kết thúc bằng ghi nhận ngắn. Vòng chính: `chọn việc → bắt đầu → học → xin gợi ý khi cần → kết thúc/tạm nghỉ → ghi nhận`. Đồng hồ, nhắc cục bộ và thao tác dừng phải hoạt động khi không mạng/không tài khoản. AI không thay thế việc tự làm, không tự cho điểm, không kết luận người học lười hoặc gian lận. Việc rời app/camera **không** ảnh hưởng XP, streak, coin, RP hoặc báo thức.

Không gian học có 3 mức tự chọn trước phiên, mặc định là **Tập trung thường**:

| Mức | Khi rời app | Quyền hệ thống | Dùng khi |
| --- | --- | --- | --- |
| Linh hoạt | Đồng hồ tiếp tục, khi trở lại cho biết thời gian rời; không nhắc | Không | Cần tra tài liệu/app khác |
| Tập trung thường | Sau ngưỡng 30 giây hiển thị một nhắc cục bộ **khi quay lại**; không chồng thông báo | Quyền thông báo chỉ nếu muốn nhắc ngoài app | Tự học hằng ngày |
| Cam kết | Khi app rời foreground quá 10 giây, phần **thời gian tập trung được ghi nhận** dừng; khi trở lại phải bấm `Tiếp tục học`. Đồng hồ thời gian thực vẫn cho biết phiên đã trôi qua bao lâu | Không | Muốn tính đúng phút học trong app; vẫn thoát được |
| Tập trung với công cụ hệ thống | Chọn `Tập trung thường` hoặc `Cam kết`, thêm hướng dẫn tự bật Digital Wellbeing Focus mode và chọn app gây xao nhãng | Người dùng bật/tắt trong Cài đặt Android | Muốn tạm dừng app gây xao nhãng |

**Không có chế độ “khóa không cho vào app khác” trong bản cho điện thoại cá nhân.** Android Focus mode do người dùng cấu hình có thể tạm dừng app đã chọn, nhưng người dùng có thể nghỉ/tắt. Screen pinning cũng thoát được. Lock task kiểu kiosk chỉ dành cho thiết bị được quản trị bằng device policy controller, không phải quyền app MindClock tự nhận. Không dùng Accessibility, overlay, VPN, device-admin hay mẹo che Home/Recent để cưỡng chế. Không dùng quyền Usage Access để liệt kê app khác ở v1. Không tự thay đổi Focus mode/DND của máy.

## 2. Luồng người dùng và trạng thái

1. `Hôm nay` có thẻ `Bắt đầu học`: việc gợi ý từ lịch đã xác nhận, có `Đổi việc` và `Tự nhập`.
2. Thiết lập phiên: môn/chủ đề, việc cụ thể (ví dụ `Làm 3 câu hàm số`), 10/25/45 phút hoặc tùy chỉnh 5–120 phút; chọn mức tập trung, âm báo cuối, camera **tắt mặc định**. Nếu việc rỗng, cho chọn `Học tự do` nhưng không AI tự tuyên bố đã hoàn thành mục tiêu.
3. Bắt đầu lưu `started_at` và `planned_end_at` theo đồng hồ thiết bị; app có màn phiên với timer lớn, việc đang làm, `Hỏi MindClock`, `Tạm nghỉ`, `Kết thúc`. Thời gian còn lại tính từ mốc, không giảm bằng mỗi lần render; mất mạng không làm sai timer.
4. App vào nền: lưu `left_at` cục bộ. Khi quay lại, tính thời gian rời và hiển thị một câu theo mức đã chọn; không khẳng định người dùng đã dùng app nào. Chế độ `Cam kết` trừ quãng rời app khỏi **phút tập trung trong app**, hiện `Đã rời phiên 2 phút · Tiếp tục học`; không xóa bài đã làm hoặc bắt đầu lại toàn bộ. Nếu app bị kill/reboot, khôi phục phiên từ local snapshot, hiển thị `Phiên đã gián đoạn` và cho `Tiếp tục` hoặc `Kết thúc`; không tự gửi AI.
5. Hết giờ: âm/rung cuối phiên tùy chọn, dừng được ngay; chọn `Hoàn thành`, `Cần thêm thời gian`, hoặc `Dừng tại đây`. Cho ghi một dòng đã làm/còn vướng; lưu cục bộ trước, đồng bộ khi có tài khoản/mạng. Không yêu cầu ảnh/camera để hoàn thành.
6. Nghỉ: tạm dừng timer tối đa theo cài đặt hoặc kết thúc phiên; không phạt. Người dùng có thể thoát bất cứ lúc nào. Nếu cuộc gọi, quyền camera bị thu hồi, pin yếu, TalkBack hoặc trợ năng khác can thiệp, timer vẫn có đường dừng và khôi phục.

State machine: `draft → running ↔ paused → completed | ended_early`; `running/paused → interrupted → running | ended_early`. Chỉ transition hợp lệ, `session_id` duy nhất, idempotency khi hoàn thành; không cộng phần thưởng hai lần. Lưu riêng `elapsed_wall_seconds` và `in_app_focus_seconds`; không gắn tên `thời gian học thực` cho chỉ số thứ hai vì người dùng có thể học trên giấy/app khác. `left_at`, `return_at`, `camera_lost_at` là sự kiện **cục bộ tạm thời**, không gửi server mặc định. `interrupted` là trạng thái kỹ thuật, không phải đánh giá hành vi.

## 3. Giao diện tiếng Việt

Phong cách tiếp tục token của [13](13-he-thiet-ke-ui.md), [27](27-quy-chuan-giao-dien-va-figma.md), [30](30-ngon-ngu-va-tai-san-giao-dien.md): nền giấy sáng dịu, mực đậm, một màu nhấn, nhiều khoảng trống, icon vector nét đều. **Không emoji, GIF mạng, khuôn mặt AI, camera mắt nhìn hay mascot giận dữ.** Đồ họa tối đa một vòng tiến độ mảnh; Reduce Motion hoặc máy yếu dùng số tĩnh. Không phát hoạt ảnh liên tục để giả “AI đang quan sát”.

| Màn | Thứ tự nội dung | Nút chính | Trạng thái cần thiết |
| --- | --- | --- | --- |
| Hôm nay | Báo thức kế tiếp → môn/việc hôm nay → thẻ phiên học → tiến độ cá nhân | `Bắt đầu học` | Chưa có lịch / không mạng / việc đã xong |
| Thiết lập | Việc học → thời lượng → mức tập trung → âm báo → camera tùy chọn | `Bắt đầu` | Quyền thông báo/camera chưa cấp; xem trước cách mức tập trung hoạt động |
| Đang học | Timer lớn + tên việc → bước hiện tại → một hàng hành động | `Hỏi MindClock` | Offline, AI bận, đang nghỉ, camera bật/tắt |
| Trợ lý | Một câu trả lời ngắn + một câu hỏi gợi mở; nhập chữ hoặc nhấn giữ để nói | `Gửi câu hỏi` | Timeout, hết hạn mức dùng, không mạng; đóng để về timer |
| Kết thúc | Thời gian thực tế → đã làm gì → còn vướng gì → lưu | `Lưu phiên` | Kết thúc sớm / phiên gián đoạn / chưa ghi nhận |

Nội dung chuẩn: `Bạn đang học: Hàm số`, `Còn 18 phút`, `Bạn vừa ra khỏi MindClock 2 phút. Tiếp tục việc đang làm?`, `Mình quay lại câu đang làm nhé.`, `Muốn nghỉ hay kết thúc?`, `Mình chỉ gợi ý bước tiếp theo. Bạn đã thử cách nào?`. Tùy chọn giọng: `Êm`, `Rõ ràng`, `Nghiêm túc`; mức nghiêm túc vẫn lịch sự, không mắng hoặc đe dọa. Không dùng chữ `bị bắt gặp`, `lười`, `phạt`, `AI đang nhìn bạn`.

Layout 320/360/390 dp, chữ 100–200%, bàn phím không che `Tạm nghỉ`/`Kết thúc`; TalkBack đọc timer theo yêu cầu, không đọc từng giây. Chế độ tối hỗ trợ học buổi tối; không ép độ sáng. Âm AI/mic không tự bật, mọi âm có nút tắt.

## 4. Camera và giọng nói

Camera **opt-in theo từng phiên**, có nhãn đang bật, nút tắt ngay và bản không camera ngang tính năng. Mục đích có thể chọn: `Chụp bài để hỏi` (mặc định, chỉ ảnh do người dùng bấm gửi) hoặc thử nghiệm `Kiểm tra khung hình` với sự đồng ý riêng. Không lưu video, không livestream về server, không nhận diện mặt, không xác định danh tính, không suy luận cảm xúc/tập trung hay giám sát học sinh liên tục. Không gửi frame định kỳ cho Gemini. Rời khung hình có thể do viết giấy/đổi tư thế; **không kết luận xao nhãng**, không phạt và không gửi thông báo phụ huynh/giáo viên. Chế độ thử nghiệm chỉ cho người dùng tự xác nhận `Tôi đang học` khi trở lại.

Giọng nói v1: **nhấn để nói**; mic chỉ mở khi giữ/chạm bắt đầu, hiện trạng thái rõ, dừng khi thả/đóng; có đường nhập chữ. Không mở hội thoại audio liên tục cho bản miễn phí. Nếu thử nghiệm Live API sau này: giới hạn thời lượng, chỉ người dùng bật, hiển thị chi phí/giới hạn kỹ thuật trong màn cài đặt, tắt ở nền, cắt phiên khi im lặng, không dùng camera cùng lúc mặc định. Ảnh/âm thanh từ người chưa thành niên chỉ gửi dịch vụ ngoài sau luồng đồng ý phù hợp ở [25](25-bao-mat-va-du-lieu.md); demo dùng ảnh/giọng của thành viên trưởng thành hoặc fixture giả.

## 5. Hợp đồng AI và tiết kiệm tài nguyên

Không cần AI để chạy timer, phát âm, phát hiện app vào nền, ghi việc, hoặc nhắc quay lại. AI chỉ nhận `subject`, `grade`, `task`, câu người học tự gửi, phần bài người học chọn gửi và **tối đa 3 lượt hội thoại gần nhất**. Không gửi lịch cả tuần, danh sách app, khung hình camera hoặc hồ sơ cá nhân đầy đủ. Backend giữ API key, giới hạn lượt theo phiên/ngày, timeout, rate limit và xóa ngữ cảnh tạm sau phiên theo [25](25-bao-mat-va-du-lieu.md).

Trợ lý theo vai Socratic: hỏi người học đã thử gì; đưa **một gợi ý cấp kế tiếp** từ rubric/chủ đề; không đưa đáp án hoàn chỉnh trong phiên khi người học chưa chủ động kết thúc và chọn xem lời giải; không chấm phẩm chất/tâm lý/độ chăm chỉ. Nếu bị hỏi đề ngoài ngân hàng, AI có thể giải thích khái niệm chung nhưng phải nói khi không có rubric xác minh. Prompt injection trong ảnh/chữ là dữ liệu không đáng tin. Output giới hạn `message_vi` ≤ 240 ký tự, `next_question_vi` ≤ 140 ký tự, `help_level`, `safety_status`; server validate. Không gọi AI mỗi giây hoặc mỗi lần timer tick. Offline trả mẫu cục bộ: `Ghi lại bước bạn đang vướng, rồi thử một cách khác.`

API dự kiến, **chưa triển khai**: `POST /v1/study/sessions` (đồng bộ metadata khi đăng nhập), `POST /v1/study/sessions/{id}/finish` (idempotent), `POST /v1/study/help` (chỉ khi chủ động hỏi). Guest lưu phiên ở máy; backend không nhận `left_at`, danh sách app, frame camera. Không cho client tự gửi `xpAwarded`/`focusScore`. Chưa cấp XP/coin chỉ vì giữ camera mở hoặc không rời app; phần thưởng nếu có cần quy tắc học thật và test riêng.

## 6. Test và cổng mở

| ID | Kiểm thử | Kỳ vọng |
| --- | --- | --- |
| F01 | Bật phiên 25 phút, khóa màn/đổi app/quay lại | Timer đúng mốc, không cộng thời gian ảo, không tự kết luận xao nhãng |
| F02 | Kill app, reboot, mất mạng, token hết hạn | Khôi phục/đóng phiên cục bộ; báo thức độc lập vẫn chạy |
| F03 | Rời app 5 giây/11 giây/31 giây/nhiều lần | Đúng ngưỡng từng mức; `Cam kết` dừng phút tập trung trong app, yêu cầu bấm tiếp tục; không spam/thưởng phạt |
| F04 | Tắt camera, từ chối/thu hồi quyền, che ống kính | Vẫn học/hoàn thành được; không ghi hình/gửi frame |
| F05 | Hỏi AI, timeout, vượt giới hạn, prompt injection trong ảnh | Gợi ý ngắn hoặc fallback; không lộ đáp án/khóa người dùng |
| F06 | Nhấn để nói, tắt mic, app vào nền | Mic dừng; có đường nhập chữ, không phát âm ngoài ý muốn |
| F07 | Kết thúc/retry hai lần, đăng xuất/đổi tài khoản | Một bản ghi; không lộ phiên của tài khoản trước |
| F08 | Android Focus mode không có/không bật; người dùng rời app | UI nói đúng khả năng; không giả khóa app khác |
| F09 | TalkBack, chữ 200%, Reduce Motion, máy yếu | Timer/nút dùng được; không giật hoặc che thao tác |
| F10 | Thử với 5–8 học sinh có đồng ý phù hợp | Hiểu rõ camera tùy chọn, cách nghỉ/thoát, phân biệt nhắc với giám sát |

**Lát cắt coding:** (1) timer + việc + lưu local + kết thúc, (2) nhắc khi quay lại và hướng dẫn Digital Wellbeing, (3) chatbot chữ có quota, (4) chụp bài theo thao tác người dùng, (5) nhấn để nói; video/Live API chỉ nghiên cứu sau khi đo chi phí, riêng tư và nhu cầu. Không đưa camera “theo dõi” hoặc khóa app khác vào demo như chức năng đã chạy.

**Nguồn nền tảng:** [Android Digital Wellbeing Focus mode](https://support.google.com/android/answer/9346420), [Android lock task mode](https://developer.android.com/work/dpc/dedicated-devices/lock-task-mode), [giới hạn camera/mic khi app nền](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start), [Gemini Live API best practices](https://ai.google.dev/gemini-api/docs/live-api/best-practices), [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing). Kiểm tra lại trước khi code/phát hành vì API và chính sách có thể đổi.
