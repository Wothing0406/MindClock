# Kế hoạch và kết quả kiểm thử T060

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02, AC-03 | Gọi API tái tạo câu hỏi với `stage=advanced` từ `seedQuestionId` trong bank và chấm bài mẫu có đạo hàm/`%`/phân số; kiểm tra live Gemini qua `.env` cục bộ | Trả JSON schema hợp lệ, tái tạo bối cảnh thực tế theo giai đoạn, không lộ key/đáp án sớm, PG16 pass | `POSTGRES_TEST_URL="postgresql+psycopg://mindclock:mindclock_local_dev@127.0.0.1:5432/postgres" .\.venv\Scripts\python.exe -m pytest -q` + live `GeminiService` verification | **PASS: 64 passed, 0 skipped** + live `gemini-3.1-flash-lite` OK (19/11/2026) |
| TC-02 | AC-04 | Render `MathFormulaText` với chuỗi `f'(x) = 3x^2 + \frac{1}{2} - 25% + \sqrt{9} -> \Delta\pi` và bấm các phím trên `MathInputKeypad` ở `320dp`, `textScale=2.0` | Hiển thị đúng ký hiệu/mũ/phân số/%, chèn đúng vị trí con trỏ, không tràn layout | `flutter analyze --no-pub`; `RAW_HEX_COLOR_HITS=0`; `flutter test --no-pub -j 1` | **PASS: 92/92 Flutter tests (`No issues found!`, `RAW_HEX_COLOR_HITS=0`)** (19/11/2026) |
