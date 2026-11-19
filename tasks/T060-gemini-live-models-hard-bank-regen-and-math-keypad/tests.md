# Kế hoạch và kết quả kiểm thử T060

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02, AC-03 | Gọi API tái tạo câu hỏi với `stage=advanced` từ `seedQuestionId` trong bank và chấm bài mẫu có đạo hàm/`%`/phân số | Trả JSON schema hợp lệ, bước giải chi tiết, không lộ key/đáp án sớm | `pytest tests/test_gemini_regen_and_grading.py` + kiểm tích hợp `.env` | Chưa chạy |
| TC-02 | AC-04 | Render `MathFormulaText` với chuỗi `f'(x) = 3x^2 + 1/2 - 25%` và bấm các phím trên `MathInputKeypad` ở `320dp`, `textScale=2.0` | Hiển thị đúng ký hiệu/mũ/phân số/%, chèn đúng vị trí con trỏ, không tràn layout | `flutter test test/math_formula_and_keypad_test.dart` | Chưa chạy |
