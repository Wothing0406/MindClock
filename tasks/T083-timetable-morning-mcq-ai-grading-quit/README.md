# T083 — Bộ Nhớ Môn Học Theo Tuần/Ngày, Câu Hỏi Sáng Đọc TKB (ABCD & Đề Ngắn >=70%), Chấm AI Thật & Nút Bỏ Cuộc

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Thêm bảng & migration `subject_memories` (lưu chương/bài theo tuần học thực tế và điểm thành thạo cho từng môn GDPT 2018 của user) + API `GET/PATCH /v1/curriculum/memory`.
  2. Nâng cấp `GET /v1/challenges/next`: đọc Thời khóa biểu ngày hôm đó (`Timetable`), chọn random 1 môn học hôm nay (hoặc môn từ query), lấy `SubjectMemory`, sinh câu hỏi buổi sáng nhỏ gọn đúng trình độ (`basic`: Trắc nghiệm 4 lựa chọn ABCD / điền 1 từ-số; `advanced`: Đề ngắn nhiều câu đạt >= 70%), bỏ yêu cầu chụp ảnh mặc định.
  3. Nâng cấp `POST /v1/sessions/{session_id}/answers` để chấm thật qua Backend + Gemini (cả câu ABCD, tự luận ngắn theo rubric và đề ngắn >= 70%), đồng thời cập nhật ngược vào `SubjectMemory`.
  4. Nâng cấp UI Flutter buổi sáng (`PracticeSessionScreen`, `AlarmRingScreen`, `PersonalFlowRepository`): hiển thị nút bấm A/B/C/D 1 chạm, công tắc độ khó `Nhẹ / Đề >= 70%`, nguồn TKB/tuần học, và đổi cơ chế thoát thử thách sang nút `Bỏ cuộc` (ghi nhận bỏ lượt an toàn, không phạt thêm).
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026` (sau `/grill-me`).
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file dự kiến:**
  - `services/api/app/db/models.py`, `services/api/alembic/versions/0009_add_subject_memories.py`
  - `services/api/app/services/{subject_memory_service.py,gemini_service.py}`
  - `services/api/app/routes/v1.py`, `services/api/tests/test_t083_subject_memory_and_mcq.py`
  - `app/lib/domain/models/personal_flow_models.dart`, `app/lib/data/repositories/remote_personal_flow_repository.dart`, `app/lib/ui/features/personal_flow/views/practice_session_screen.dart`
- **Liên quan:** Kế thừa `T076`, `T078`, `T082`.
- **Source refs đã đọc:** `services/api/app/routes/v1.py`, `services/api/app/services/gemini_service.py`.
- **Điểm tiếp tục:** Kiểm tra `models.py` và tạo migration `0009_add_subject_memories.py`.

## Cổng trước coding

- [x] Đã rà `GET /v1/challenges/next` và `POST /v1/sessions/{session_id}/answers`.
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [ ] Acceptance trong `spec.md` đạt và test xanh.
- [ ] Các bước `plan.md` đã đánh dấu thật.
- [ ] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [ ] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
