# Đặc tả kỹ thuật T060

1. **AC-01 (Model Gemini thực tế & Bảo mật key):** `config.py` dùng model ID chuẩn Gemini Developer API (ví dụ `gemini-2.5-flash` / `gemini-2.5-flash-lite`); `GEMINI_API_KEY` chỉ đọc từ `.env` server, tuyệt đối không commit hay trả key ra API/log/client.
2. **AC-02 (Tái tạo câu hỏi thực tế khó theo giai đoạn từ ngân hàng câu):** Bổ sung tham số `stage` (`foundational` / `applied` / `advanced`) + tham chiếu `seedQuestionId` từ ngân hàng câu đã duyệt để AI tái tạo biến thể gắn bối cảnh thực tế (số liệu/tình huống mới, giữ nguyên chuẩn kiến thức & rubric từng bước).
3. **AC-03 (Chấm bài AI đa bước chính xác & an toàn):** Test đầy đủ các ca `correct`, `incorrect`, `uncertain` với đáp án chứa mũ/phân số/đơn vị/`%`/đạo hàm.
4. **AC-04 (Hiển thị công thức & Bàn phím Toán/Lý/Hóa):** `MathFormulaText` render rõ lũy thừa, phân số, `%`, đạo hàm, căn bậc hai, ký tự Hy Lạp; `MathInputKeypad` cho phép chèn nhanh `^2`, `^3`, `/`, `√`, `%`, `'`, `π`, `Δ`, `→` trực tiếp tại vị trí con trỏ của `TextEditingController`.
