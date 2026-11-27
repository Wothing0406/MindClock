# Kế hoạch thực hiện T083

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T083-timetable-morning-mcq-ai-grading-quit/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Thêm model `SubjectMemory`, migration `0009`, và `subject_memory_service.py` (chương trình tuần GDPT 2018 + cập nhật theo ngày/báo cáo) | `pytest` pass API `GET/PATCH /v1/curriculum/memory` | [x] |
| 3 | Nâng cấp `gemini_service.py` & `v1.py` (`/v1/challenges/next`, `/v1/sessions/{id}/answers`, `/abandon?immediate=true`) hỗ trợ đọc TKB ngày, câu ABCD, đề ngắn >=70% và chấm AI thật | `pytest` pass full flow TKB + MCQ + Mini-quiz | [x] |
| 4 | Nâng cấp Flutter `PersonalFlowModels`, `RemotePersonalFlowRepository`, `PersonalFlowViewModel`, `PracticeSessionScreen` với 4 nút ABCD, chọn `Nhẹ / Đề >=70%`, bỏ chụp ảnh mặc định, thêm nút `Bỏ cuộc` | `flutter analyze` & `flutter test` xanh | [x] |
| 5 | Viết test backend + Flutter (`t083`), cập nhật `tests.md`, `handoff.md` | Toàn bộ cổng xanh | [x] |
