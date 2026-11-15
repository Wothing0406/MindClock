# Đặc tả T027

## AC ↔ TC

| AC | Yêu cầu | Test |
| --- | --- | --- |
| AC-01 | App vào mở màn ngắn gắn kiến thức rồi câu; không màn hỏi bắt đầu/chụp nước; hook bỏ qua được, câu bắt buộc để nhận thưởng | TC-01 |
| AC-02 | Sai rõ lần 3 hint, lần 5 có Bỏ lượt không EXP/chuỗi; Dừng âm bất kỳ lúc nào; lỗi hệ thống/uncertain không xử sai | TC-02 |
| AC-03 | EduSkills dùng làm authoring/pedagogy/grading guidance đa môn, có reviewer/version/eval; không lộ lời giải trước lượt | TC-03 |
| AC-04 | PRD→UX→content/AI/API/SQL→test/agent rules/truy vết/backlog đồng bộ; WIP runtime nguyên trạng | TC-04 |

## Quyết định

Mở màn là asset nhỏ đã duyệt và cached, không gọi AI lúc chuông reo; kết cảnh xem được sau lượt kể cả bỏ. `Bỏ lượt` sau 5 `incorrect` xác nhận, nhưng Dừng khẩn cấp luôn cho thoát. Ngày bỏ lượt không cộng EXP/ngày chuỗi và kết thúc chuỗi liên tiếp của ngày đã chọn có thử thách; không trừ điểm cũ. EduSkills prompt đầy đủ lời giải chỉ dùng biên tập/hậu lượt; runtime dùng mode nhỏ và backend chốt verdict. Đây là tài liệu, chưa là API/chức năng chạy.
