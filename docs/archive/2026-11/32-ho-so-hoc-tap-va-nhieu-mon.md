# Hồ sơ học tập cá nhân và câu hỏi nhiều môn

**Mục tiêu:** một học sinh chọn môn đang học, môn ưu tiên thi, chủ đề cần ôn và thời khóa biểu của mình; chuông/nhắc lịch dùng hồ sơ đó để chọn câu phù hợp. **Không cố định “tổ hợp thi” theo một danh sách cứng**, vì kỳ thi, môn chọn và năm học có thể đổi. App cho người học tự chọn và sửa bất cứ lúc nào. Không suy luận năng lực/tổ hợp từ điểm số hoặc lớp.

Môn dùng cho Solo 1v1 chỉ được mở theo chất lượng [ngân hàng câu](34-ngan-hang-cau-hoi-da-mon.md) và luật [đấu trường](35-solo-rpg-dong-bo-va-ky-nang.md); việc chọn môn ưu tiên trong hồ sơ **không tự bật ranked** hay chia sẻ môn đó công khai.

## 1. Onboarding tối thiểu

1. Chọn cấp/lớp hoặc năm học; có `Để sau` cho người chỉ dùng báo thức.
2. Chọn các môn học đang học từ danh mục có mã ổn định: Toán, Ngữ văn, Tiếng Anh, Vật lí, Hóa học, Sinh học, Lịch sử, Địa lí, Tin học, Công nghệ, Giáo dục kinh tế và pháp luật; danh mục mở rộng theo nội dung đội thật sự có quyền biên tập. Chỉ **môn có câu được duyệt** mới bật chế độ thử thách.
3. Chọn `Môn ưu tiên ôn thi` (0–5 môn) và đặt mức ưu tiên `Cao / Vừa`; có thể lưu một nhãn tự đặt như `Ôn thi cuối kỳ` hoặc `Tổ hợp xét tuyển` nhưng **không tự xác nhận quy chế thi chính thức**.
4. Nhập thời khóa biểu theo thứ và tiết, hoặc chụp ảnh để AI trích xuất **bản nháp**; người dùng kiểm tra từng môn/tiết/ngày rồi nhấn `Lưu lịch`. Không gửi thông báo từ bản AI chưa xác nhận.
5. Chọn buổi/khung giờ nhắc bài, ngày nghỉ, môn muốn loại khỏi báo thức, và phương thức trả lời phù hợp. Có thể chọn `Theo môn trong lịch ngày mai` hoặc `Luân phiên các môn ưu tiên`.

## 2. Cách chọn một câu buổi sáng

1. Lấy danh sách môn **được bật và có câu đã duyệt**, đúng lớp/cấp và phương thức chấm có fallback an toàn khi offline.
2. Ưu tiên môn có trong lịch hôm nay (hoặc buổi sáng tiếp theo theo giờ địa phương); nếu nhiều môn, dùng môn chưa xuất hiện trong các lần gần đây và thuộc mức ưu tiên của người dùng.
3. Nếu hôm nay không có môn, chọn chủ đề đến hạn ôn từ các môn ưu tiên; nếu không có thì câu dự phòng dễ hoặc `Chỉ báo thức` theo cài đặt. Không tự chuyển sang môn người dùng đã loại.
4. Chọn câu đúng chủ đề, độ khó cá nhân theo [quy tắc ba phiên đầu và tăng dần](39-bai-lam-co-trinh-bay-va-cham-cong-bang.md#5-độ-khó-ngày-đầu-và-tăng-dần), thời lượng mục tiêu 60–90 giây; tránh lặp `questionId`/biến thể gần đây. **Rank/ELO không quyết định độ khó**.
5. Tải trước `questionId`, revision, **đề và yêu cầu trình bày**, không có đáp án/rubric trong API cache; có câu dự phòng đội tự biên soạn ở máy. Đến giờ reo không chờ AI/mạng. Offline chỉ hoàn thành không chấm theo [docs/07 §8](07-hop-dong-api-va-ai.md#8-quy-tắc-offline-khách-local-và-đồng-bộ-bài).

**Công thức lựa chọn v1 để đội có thể code/test:** lọc điều kiện bắt buộc → xếp theo `môn có tiết hôm nay` (+4), `môn ưu tiên cao` (+3), `chủ đề đến hạn` (+2), `chưa hỏi 7 ngày` (+2), `vừa hỏi 2 ngày` (−5); hòa thì xoay vòng cố định theo UID+ngày, không random lại mỗi lần mở app. Điểm chỉ là heuristic chọn câu, không hiển thị là điểm năng lực. Đội có thể điều chỉnh qua pilot và ghi `selectionRuleVersion`.

## 3. Ma trận dạng câu và cách chấm

| Nhóm môn | Câu 60–90 giây phù hợp | Trả lời/chấm ban đầu | Tránh trong báo thức |
| --- | --- | --- | --- |
| Toán, Vật lí, Hóa học | Tính nhanh một bước, chọn công thức/đơn vị, điền kết quả; ảnh một bước khi evaluator đã kiểm chứng | Số/biểu thức có tolerance **và một bước viết**, `uncertain` khi ảnh/chữ không rõ | Bài nhiều trang, lời giải dài |
| Tiếng Anh | Điền từ, chọn cấu trúc, sắp câu ngắn, hiểu ý một câu | Chuỗi chuẩn hóa/danh sách đáp án **và lý do/dấu hiệu ngắn**; không chấm phát âm ở v1 | Bài nghe cần tai nghe, accent scoring chưa kiểm chứng |
| Sinh học, Lịch sử, Địa lí | Truy hồi một khái niệm, thứ tự sự kiện, ghép nguyên nhân–kết quả, đọc biểu đồ rất nhỏ | Đáp án cấu trúc/multiple choice + **một lý do ngắn có rubric** | Câu đòi học thuộc cả đoạn hoặc dữ kiện dễ gây tranh cãi |
| Ngữ văn | Nhận diện biện pháp tu từ từ một câu ngắn, chọn luận điểm phù hợp | Câu có rubric rõ; nếu mở nhiều đáp án thì chỉ phản hồi, không buộc chấm đúng/sai để dừng | Chấm bài văn/diễn giải mở lúc mới thức |
| Tin học, Công nghệ, Kinh tế & pháp luật | Dự đoán một kết quả lệnh, chọn bước quy trình, nhận diện khái niệm/tình huống ngắn | Câu cấu trúc do người duyệt | Tình huống pháp lý dài hoặc thông tin có thể lỗi thời |

Mỗi `question` có `subject_code`, `grade_band`, `topic_id`, `learning_outcome`, `answer_type`, `accepted_answers`, `rubric_revision`, `source_license`, `reviewer_id`, `offline_gradable`, `estimated_seconds`. AI chỉ giúp **đề xuất bản nháp câu/rubric, đọc ảnh và gợi ý**, còn người biên tập duyệt trước xuất bản. Câu mở không có đáp án dứt khoát phải dùng `practice_only`, không đưa vào đường “đúng mới hoàn thành báo thức”.

## 4. Thời khóa biểu và việc cần làm hằng ngày

- Người dùng nhập bài tập/việc cần làm; AI có thể gợi ý chia thành các việc 10–25 phút dựa giờ rảnh, môn ưu tiên và hạn nộp. Người dùng xác nhận trước khi tạo task/notification.
- Nhắc lịch dùng mẫu ngắn: `Ngày mai có Toán, Sinh.`; `19:00: làm 2 câu Sinh.`; `Bài Anh đến hạn ngày mai.` Không gửi tên môn/chủ đề chi tiết lên màn khóa nếu người dùng chọn chế độ riêng tư.
- Một lần thay thời khóa biểu sẽ tính lại thông báo cục bộ, hủy thông báo cũ theo ID; không spam nhiều nhắc cho cùng một việc. Mặc định tối đa 2 nhắc học/ngày ngoài báo thức, người dùng đổi/tắt được.
- AI không tự đoán học lực, tự thêm việc vào lịch, tự thay ngày thi hoặc gửi thông báo khi người dùng chưa xác nhận dữ liệu đầu vào.

## 5. Gợi ý giờ dậy khi đặt báo thức

Người dùng chọn ngày có tiết học, giờ bắt đầu, thời gian đi đường, thời gian chuẩn bị và khoảng đệm muốn có. App **tính trên máy** `giờ dậy muộn nhất = giờ bắt đầu − đi đường − chuẩn bị − khoảng đệm` theo múi giờ đã xác nhận, rồi hiển thị 2–3 lựa chọn quanh mốc đó nếu không trùng lịch khác. Ví dụ tiết đầu 07:00, đi đường 25 phút, chuẩn bị 30 phút, đệm 10 phút → mốc muộn nhất **05:55**; UI: `Đề xuất 05:55 · kịp tiết 07:00 theo thời gian bạn nhập` và `Sửa thời gian`. Không làm tròn khiến giờ dậy trễ hơn mốc. Không gán đây là khuyến nghị y khoa hay bảo đảm đến lớp đúng giờ.

AI có thể đọc lịch đã xác nhận để **giải thích** vì sao đề xuất một giờ, nhận ra ngày có tiết sớm/di chuyển khác và gợi ý phân bổ việc buổi tối. AI chỉ trả `suggestions[]` với `input_refs`, `reason_vi`, `confidence_note`; backend/client kiểm lại phép trừ và xung đột, không cho AI ghi alarm, task hoặc notification. Người dùng bấm `Dùng giờ này` rồi app kiểm quyền/lập lịch OS và báo trạng thái thực. Nếu thiếu giờ học/đi đường, hỏi nhập hoặc giữ giờ người dùng đặt tay; offline vẫn tính được từ dữ liệu local. Lịch đổi → hiện `Giờ học đã đổi. Xem lại báo thức 05:55`, không tự chỉnh chuông đang bật.

Không thu vị trí GPS để tính đi đường mặc định; nhập số phút thủ công. Không suy giờ ngủ hoặc chẩn đoán giấc ngủ từ lịch. Nếu giờ đề xuất nằm trước ngày hiện tại, xung đột ngày nghỉ hoặc khoảng chuẩn bị không hợp lệ, yêu cầu người dùng sửa; không âm thầm đặt 00:00. `wake_suggestion_version`/nguồn lịch được lưu để giải thích, không dùng AI để quyết XP/streak.

## 6. Dữ liệu/API dự kiến cho backend SQL

Thêm vào [schema SQL](28-backend-sql.md): `study_profiles(user_id,grade_band,selection_mode,updated_at)`, `profile_subjects(user_id,subject_code,priority,alarm_enabled,answer_mode)`, `exam_goals(id,user_id,label,target_date nullable,status)`, `exam_goal_subjects(goal_id,subject_code,priority)`, `study_tasks(id,user_id,subject_code,title,due_at,status,source,confirmed_at)`, `notification_preferences(user_id,max_daily_study_reminders,quiet_hours_start,quiet_hours_end,lockscreen_detail)`, `wake_preferences(user_id,prep_minutes,commute_minutes,buffer_minutes,time_zone,updated_at)`, `wake_suggestion_audit(user_id,alarm_id,input_revision,calculation_version,suggested_local_time,confirmed_at nullable)`; audit chỉ metadata tối thiểu. Không lưu ảnh thời khóa biểu mặc định sau khi người dùng xác nhận bản trích xuất.

API đề xuất: `GET/PUT /v1/study-profile`, `GET/PUT /v1/exam-goals`, `GET/PUT /v1/timetable`, `POST /v1/timetable/parse-preview` (ảnh → bản nháp, không lưu), `GET/POST/PATCH /v1/study-tasks`, `GET/PUT /v1/notification-preferences`, `GET/PUT /v1/wake-preferences`, `POST /v1/alarms/wake-suggestions` (preview, không ghi alarm), `GET /v1/challenges/next`. Backend xác minh người sở hữu, không cho client quyết định XP/độ đúng. Các endpoint là **đề xuất**, phải chốt contract test khi mở task coding.

## 7. Kiểm thử cốt lõi

- Hai người cùng lớp khác môn ưu tiên nhận câu/nhắc lịch khác nhau; cùng người đổi tổ hợp thì câu kế tiếp đổi theo nhưng không sửa lịch sử.
- Ngày có nhiều môn: xoay vòng công bằng, không lặp một môn suốt tuần; ngày nghỉ: đúng fallback.
- Môn chưa có câu được duyệt: app báo rõ và không dùng làm câu thử thách; offline không khóa chuông vì chưa chấm được, có `Hoàn thành không chấm`/Dừng khẩn cấp.
- `incorrect` đếm lần sai theo [docs/31](31-bao-thuc-thu-thach.md); `uncertain` không đếm. Ngữ văn câu mở không kẹt chuông.
- AI đọc thời khóa biểu sai: không lưu/nhắc trước khi người dùng xác nhận; đổi lịch hủy nhắc cũ.
- Mất mạng, đổi múi giờ, đổi lớp, xóa hồ sơ, quyền thông báo bị từ chối đều có trạng thái rõ và không chặn Dừng khẩn cấp.
- Giờ học 07:00, đi đường 25 phút, chuẩn bị 30 phút, đệm 10 phút → đề xuất 05:55; lịch đổi/thiếu dữ liệu/AI trả giờ trễ hơn phép tính đều không tự sửa alarm.

