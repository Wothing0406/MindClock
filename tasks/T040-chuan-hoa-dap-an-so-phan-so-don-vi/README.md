# Nhiệm vụ T040: Chuẩn hóa đáp án số thập phân, phân số và đơn vị đo lường

- **Trạng thái:** `done`
- **Mục tiêu:**
  Xây dựng module chuẩn hóa đáp án toán - khoa học tự nhiên (Toán, Vật lí, Hóa học, Sinh học) cho cả Backend FastAPI và Frontend Flutter trong MindClock. Đảm bảo học sinh nhập số thập phân (dấu phẩy `,` hoặc chấm `.`), phân số (`a/b`, `\frac{a}{b}`), phương trình biến số (`x = 8`, `i = 2A`) hoặc kèm đơn vị đo (`m/s`, `kg`, `A`, `V`, `J`, `W`, `°C`...) đều được quy chuẩn và chấm chính xác so với `accepted_answers`, tránh việc bị xử sai oan uổng do định dạng nhập liệu.
- **Tài liệu căn cứ:**
  - `AGENTS.md` §3 (AI và chấm bài: rubric rõ ràng, không phạt học sinh oan).
  - `docs/02-engineering/05-ngan-hang-cau-hoi.md` (đặc tả `answer_spec_json` và accepted answers).
  - `docs/02-engineering/06-ai-va-cham-bai.md` (chấm bài và phản hồi rubric).
- **Phạm vi kiểm thử:**
  - Unit tests cho normalizer trên backend FastAPI (`test_answer_normalizer.py`).
  - Unit tests cho route v1 và PvP matchmaking.
