# Kế hoạch thực hiện T060

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật model ID chuẩn trong `services/api/app/config.py` + logic tái tạo câu hỏi thực tế theo giai đoạn & chấm bài trong `gemini_service.py` / `v1.py` | `pytest` contract + live verification script PASS (không log secret) | [ ] |
| 2 | Viết `MathFormulaText` và `MathInputKeypad` + tích hợp vào màn câu thử thách / luyện tập / đấu trường | `math_formula_and_keypad_test.dart` PASS ở 320dp/200%, `RAW_COLOR_HITS: 0` | [ ] |
| 3 | Full `pytest` PG16 + `flutter analyze` + `flutter test` + push `origin/main` | Test pass 100%, ghi SHA vào `handoff.md` | [ ] |
