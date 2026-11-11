# Kế hoạch T003

## Điểm bắt đầu

Repo mới có docs và demo tĩnh. `.agents/skills/` chưa có skill sprite; bản Codex toàn máy có một số skill cùng nguồn nhưng chưa nằm trong dự án. Chưa có backend/data.

| Bước | Việc làm | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Kiểm tra repo skill, dataset, format thi và giấy phép | Có ghi nguồn/giới hạn sử dụng | [x] |
| 2 | Cài nhóm skill sprite vào `.agents/skills/` và kiểm tra file | Skill nằm trong project, không cài runtime/API key | [x] |
| 3 | Chốt docs kinh tế, rank, HP, 2D asset; update docs nguồn | Không còn mâu thuẫn hiện hành | [x] |
| 4 | Chốt registry/luồng nhập dataset và format 2025 | Có cổng provenance/licence/review | [x] |
| 5 | Chạy test tài liệu/task, rà diff, ghi handoff và đẩy Git | Bằng chứng thực, không có corpus chưa duyệt | [x] |

## Rủi ro và đường lui

Skill sprite có script/API tùy chọn: chỉ cài hướng dẫn, không chạy tạo ảnh/trả phí. Dataset không rõ quyền: giữ metadata/adapter trong kế hoạch, chỉ dùng câu đội tự viết cho demo. Nếu bộ skill quá nặng, ghi rõ thành phần được cài và không tự bật script phụ thuộc.
