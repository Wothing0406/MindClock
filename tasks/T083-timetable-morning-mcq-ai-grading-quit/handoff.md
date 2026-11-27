# Bàn giao nhiệm vụ T083

- **Trạng thái cuối:** `verifying`
- **Đã làm:**
  1. Thêm bảng & migration `0009_add_subject_memories.py` (`SubjectMemory`) cùng `subject_memory_service.py` theo chương trình tuần GDPT 2018 & API `GET/PATCH /v1/curriculum/memory`.
  2. Nâng cấp `GET /v1/challenges/next` đọc Thời khóa biểu ngày hôm đó (`subject=auto`), sinh câu nhỏ buổi sáng (`mcq` 4 lựa chọn hoặc `mini_quiz` 4 câu đạt `>= 70%`).
  3. Nâng cấp `POST /v1/sessions/{id}/answers` chấm thật ABCD, Mini-quiz `>= 70%`, và tự luận ngắn bằng Gemini rubric (`grade_short_text_answer`), tự cập nhật `mastery_score` trong `SubjectMemory`.
  4. Nâng cấp Flutter `PracticeSessionScreen`: chọn độ khó `Nhẹ (1 câu ABCD)` / `Nâng cao (Đề >= 70%)`, 4 nút chạm ABCD, bỏ cụm chụp ảnh phiền phức khỏi màn chính, và thêm nút `Bỏ cuộc` (`POST /v1/sessions/{id}/abandon?immediate=true`).
- **Điểm tiếp tục chính xác:** Làm tiếp **T084** (Cơ chế Ngày bận / Bảo lưu Chuỗi nhóm), **T085** (Profile Showcase vinh danh tuần & Khung bậc mùa), **T086** (Micro-Check Không gian học & Game Đấu thẻ bài 75% Stage).
- **Git:** Chưa commit/push.
