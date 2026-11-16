# Đặc tả nhiệm vụ — T033 (B03/B05: MorningCard, Bỏ lượt lần sai thứ 5 & EduSkills-VN adapter)

## Vấn đề và kết quả mong muốn

Theo `docs/03-quality/03-truy-vet-yeu-cau.md` (`P-03`, `P-06`, `P-07`), `docs/02-engineering/04-hop-dong-api.md §3`, `docs/01-product/09-giac-ngu-va-bao-thuc.md` (`MORNING-01..03`) và `docs/02-engineering/11-eduskills-vn-tich-hop.md`:
1. Chưa có adapter `EduSkills-VN` ở backend (`AUTHOR_DRAFT`, `GRADE_CANDIDATE`, `HINT_ONE_STEP`, `POST_ATTEMPT_EXPLAIN`) để chuẩn hóa hướng dẫn chấm theo môn học THPT và chặn rò rỉ đáp án trước khi kết thúc lượt.
2. `GET /v1/challenges/next` chưa trả cấu trúc `morningCard` công khai (gồm `cardId`, `durationTargetSeconds`, `setupVi`, `cliffVi`, `staticFallbackVi`, `learningOutcome`) gắn với cùng `questionId + questionRevision`, và chưa ẩn `revealVi` cho tới khi hoàn thành hoặc bỏ lượt.
3. `POST /v1/sessions/{id}/answers` và `/attempts` chưa trả `confirmedIncorrectCount` và `canAbandon`, đồng thời chưa có route `POST /v1/sessions/{id}/abandon` (mở từ lần `incorrect` rõ thứ 5, idempotent, `xpAwarded = 0`, `streakDayAwarded = false`, trả `revealVi` hậu lượt).
4. Trên giao diện Flutter (`PracticeSessionScreen` / `PersonalFlowViewModel`), chưa hiển thị thẻ mở màn `MorningCard` (có nút `Bỏ qua mở màn` chuyển thẳng vào câu hỏi và hỗ trợ `Reduce Motion` / fallback chữ tĩnh), cũng như nút `Bỏ lượt (không nhận EXP)` từ lần sai rõ thứ 5.

## Phạm vi

- **Trong phạm vi:**
  - Tạo `services/api/app/services/eduskills_adapter.py` triển khai 4 chế độ prompt `EduSkillsMode` (`AUTHOR_DRAFT`, `GRADE_CANDIDATE`, `HINT_ONE_STEP`, `POST_ATTEMPT_EXPLAIN`) và hàm kiểm tra không lộ đáp án (`sanitize_pre_reveal_hint`).
  - Bổ sung dữ liệu `morning_card` gốc của đội vào `SEED_QUESTIONS` trong `services/api/app/db/seed.py` (không lộ `reveal_vi` ở `GET /v1/challenges/next`).
  - Cập nhật `services/api/app/routes/v1.py`:
    - `GET /v1/challenges/next` trả thêm `morningCard` công khai (không chứa `revealVi`).
    - `POST /v1/sessions/{id}/answers` và `/attempts` trả `confirmedIncorrectCount`, `canAbandon` (`wrong_attempts >= 5`), thêm `'abandon'` vào `nextActions` khi `wrong_attempts >= 5`, và chỉ trả `revealVi` khi `result == 'correct'`.
    - Thêm `POST /v1/sessions/{id}/abandon` (idempotent theo `Idempotency-Key`, kiểm tra owner 403, chặn 409 `ABANDON_THRESHOLD_NOT_MET` nếu `wrong_attempts < 5`, trả `state='abandoned'`, `xpAwarded=0`, `streakDayAwarded=False`, `revealVi`).
  - Cập nhật Flutter (`personal_flow_models.dart`, `personal_flow_repository.dart`, `remote_personal_flow_repository.dart`, `debug_fixture_personal_flow_repository.dart`, `personal_flow_view_model.dart`, `practice_session_screen.dart`) hiển thị `MorningCard` (với `Bỏ qua mở màn`), đếm sai rõ, gợi ý lần 3, nút `Bỏ lượt` lần 5 và giải thích hậu lượt `revealVi`.
- **Ngoài phạm vi:**
  - Dựng video clip MP4/WebM thương mại (hiện dùng cảnh chữ tĩnh / storyboard gốc đội tạo theo `T028`).
- **Dữ liệu/role/quyền liên quan:**
  - Không trả `answer_spec_json`, `rubric_json` hay `reveal_vi` trước khi phiên kết thúc (`correct` hoặc `abandoned`).
- **Tài liệu chuẩn:**
  - `AGENTS.md §3, §5`
  - `docs/01-product/09-giac-ngu-va-bao-thuc.md` (`MORNING-01..03`)
  - `docs/02-engineering/04-hop-dong-api.md §3`
  - `docs/02-engineering/11-eduskills-vn-tich-hop.md`

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi gọi `GET /v1/challenges/next` | Trả `morningCard` gắn cùng `questionId` + `questionRevision` (`setupVi`, `cliffVi`, `staticFallbackVi`), tuyệt đối không chứa `revealVi`, `answerSpec` hay `rubric` | TC-01 |
| AC-02 | Khi nộp bài `uncertain`, sau đó nộp `incorrect` từ lần 1 đến lần 5 | `uncertain` giữ `confirmedIncorrectCount = 0`; lần sai rõ 1–2 chưa có `hint` và `canAbandon = false`; lần 3–4 có `hint` (đã qua bộ lọc không lộ đáp án) và `canAbandon = false`; lần 5 có `canAbandon = true` và `nextActions` chứa `'abandon'` | TC-02 |
| AC-03 | Khi gọi `POST /v1/sessions/{id}/abandon` trước và sau ngưỡng 5 lần sai rõ | Trước lần sai 5 trả `409 ABANDON_THRESHOLD_NOT_MET`; từ lần sai 5 trả `200` với `state = 'abandoned'`, `xpAwarded = 0`, `streakDayAwarded = false` và `revealVi` (idempotent khi gọi lại cùng key) | TC-03 |
| AC-04 | Khi kiểm tra `EduSkillsAdapter` với 4 mode và chạy `flutter analyze` | Mode `HINT_ONE_STEP` và `GRADE_CANDIDATE` chặn lộ đáp án; `flutter analyze` trên toàn bộ `app/` đạt `No issues found!` | TC-04 |

## Hợp đồng và trường hợp biên

- Giữ tương thích ngược 100% với các test hiện có trong `test_api_v1.py` và `app/test/`.
- `Bỏ qua mở màn` trên UI chỉ ẩn phần cảnh mở màn để vào thẳng khung nhập câu trả lời của cùng câu hỏi đó (`MORNING-01`), không tính là hoàn thành phiên.

## Quyết định/mâu thuẫn

- Lưu cấu hình `morning_card` của câu seed bên trong `rubric_json['morning_card']` (và chỉ trích xuất phần công khai khi trả `GET /v1/challenges/next`), nhờ đó không cần tạo bảng trống mới mà vẫn bảo đảm tính nguyên tử cùng `Question.revision`.
