# Kế hoạch thực hiện — T033 (B03/B05)

## Điểm bắt đầu

- Code hiện tại: `services/api/app/routes/v1.py`, `services/api/app/db/seed.py`, `app/lib/domain/models/personal_flow_models.dart`, `app/lib/ui/features/personal_flow/*`.
- Hiện trạng: Đã có gợi ý ở lần sai thứ 3, nhưng chưa có `MorningCard`, chưa có `EduSkillsAdapter`, và chưa có `canAbandon` / `POST /v1/sessions/{id}/abandon` ở lần sai thứ 5.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo `services/api/app/services/eduskills_adapter.py` và cập nhật `services/api/app/db/seed.py` với `morning_card` gốc đội tạo | Adapter hỗ trợ 4 mode `EduSkillsMode` và chặn lộ đáp án | [x] |
| 2 | Cập nhật `services/api/app/routes/v1.py` bổ sung `morningCard`, `confirmedIncorrectCount`, `canAbandon`, `revealVi` và route `POST /v1/sessions/{id}/abandon` | API hợp đồng `/v1` đạt AC-01..AC-03 | [x] |
| 3 | Cập nhật Flutter `personal_flow_models.dart`, `personal_flow_repository.dart`, `remote_personal_flow_repository.dart`, `debug_fixture_personal_flow_repository.dart`, `personal_flow_view_model.dart`, `practice_session_screen.dart` | UI hiển thị `MorningCard` (`Bỏ qua mở màn`), nút `Bỏ lượt` lần 5 và `revealVi`; `flutter analyze` pass | [x] |
| 4 | Bổ sung test trong `services/api/tests/test_api_v1.py`, chạy `pytest`, `flutter analyze`, `check_docs_links.py`, `check_task_records.py` và điền `handoff.md` | Tất cả test pass 100% | [x] |

## Rủi ro và đường lui

- **Rủi ro:** Thay đổi `SEED_QUESTIONS` trong `seed.py` không tự cập nhật các dòng đã tồn tại nếu chỉ kiểm `existing is None`.
- **Đường lui:** Trong `seed_approved_questions(db)`, nếu câu seed đã tồn tại nhưng thiếu `morning_card` trong `rubric_json`, cập nhật bổ sung `rubric_json` để cả DB cũ lẫn DB mới đều có `MorningCard`.
