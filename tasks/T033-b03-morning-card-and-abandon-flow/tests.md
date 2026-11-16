# Kế hoạch và kết quả kiểm thử — T033 (B03/B05)

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Gọi `GET /v1/challenges/next?subject=TOAN` | Trả `morningCard` (`cardId`, `setupVi`, `cliffVi`, `staticFallbackVi`), không chứa `revealVi`, `answerSpec`, `rubric` | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_api_v1.py -k test_morning_card_hook_and_abandon_at_5_incorrect` | Pass (16/11/2026) |
| TC-02 | AC-02 | Gửi 1 lần `uncertain`, tiếp theo 5 lần `incorrect` rõ | `uncertain` không tăng `confirmedIncorrectCount`; sai 1–2 chưa có hint; sai 3–4 có hint không lộ đáp án; sai 5 có `canAbandon=true` | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_api_v1.py -k test_morning_card_hook_and_abandon_at_5_incorrect` | Pass (16/11/2026) |
| TC-03 | AC-03 | Gọi `POST /v1/sessions/{id}/abandon` ở lần sai 4 (409) và ở lần sai 5 (200 idempotent) | Lần 4 trả `409 ABANDON_THRESHOLD_NOT_MET`; lần 5 trả `200` với `state='abandoned'`, `xpAwarded=0`, `streakDayAwarded=false`, có `revealVi` | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_api_v1.py -k test_morning_card_hook_and_abandon_at_5_incorrect` | Pass (16/11/2026) |
| TC-04 | AC-04 | Kiểm tra `EduSkillsAdapter` 4 mode + chống lộ đáp án và chạy `flutter analyze` | `pytest` pass cho `test_eduskills_adapter_modes_and_answer_leak_guard`; `flutter analyze` trả `No issues found!` | `pytest -vv` + `.local-sdk\flutter\bin\flutter.bat analyze` | Pass (`21 passed, 1 skipped`, `flutter analyze`: `No issues found!`, 16/11/2026) |

## Cổng theo rủi ro

- Nội dung/AI (`MORNING-01..03`, `EDU-01..04`, `LEARN-06`): Không lộ đáp án trước khi kết thúc phiên; bỏ lượt ở lần sai 5 không cộng EXP/chuỗi và không phạt trừ điểm cũ.
