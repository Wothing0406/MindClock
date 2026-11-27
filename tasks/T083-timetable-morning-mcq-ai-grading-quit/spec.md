# Đặc tả T083 — SubjectMemory, TKB Sáng (ABCD & Đề >=70%), Chấm AI Thật & Bỏ Cuộc

## Acceptance Criteria

- **AC-01 (Bộ nhớ môn học `SubjectMemory` theo tuần/ngày):** Mỗi user có bản ghi chương/bài tuần hiện tại cho các môn theo khối lớp GDPT 2018; cập nhật qua `GET/PATCH /v1/curriculum/memory` và tự cập nhật khi làm câu sáng / báo cáo ngày.
- **AC-02 (Đọc TKB hôm nay + chọn random môn + câu ABCD / Đề ngắn >=70%):** `GET /v1/challenges/next?subject=auto&difficulty=basic|advanced` đọc lịch học thứ hiện tại trong TKB user, chọn random 1 môn (fallback môn Profile), trả `options` (4 lựa chọn ABCD cho trắc nghiệm nhanh) hoặc `subQuestions` (đề ngắn `passThreshold = 0.7`), kèm `sourceScheduleReasonVi`.
- **AC-03 (Chấm thật trên Backend + AI & Nút `Bỏ cuộc`):** `POST /v1/sessions/{id}/answers` chấm câu ABCD, đề ngắn >= 70%, hoặc tự luận ngắn qua Backend + Gemini rubric thật, cập nhật `SubjectMemory`. UI Flutter hiện 4 nút chạm A/B/C/D, bỏ bước chụp ảnh mặc định, và có nút `Bỏ cuộc` ghi nhận abandon an toàn.
