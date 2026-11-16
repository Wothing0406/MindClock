# Bàn giao nhiệm vụ T040

- **Trạng thái:** `done`
- **Commit SHA:** `422b2c5c9603099a4c878e38d7265db267a1518f` (nhánh `main`)
- **Thay đổi chính:**
  1. Xây dựng module chuẩn hóa đáp án toán học và khoa học tự nhiên `services/api/app/services/answer_normalizer.py`:
     - Tự động nhận diện và quy đổi số thập phân dấu phẩy `,` sang dấu chấm `.` (`0,5` == `0.5`, `3,14` == `3.14`).
     - Tự động nhận diện phân số `a/b`, LaTeX `\frac{a}{b}` và rút gọn phân số (`3/4` == `0.75` == `6/8`).
     - Bóc tách phương trình biến số (`x = 8`, `v = 10`, `i = 2a`).
     - Chuẩn hóa hệ thống đơn vị đo lường phổ biến THPT (A, mA, V, ohm, m/s, km/h, m/s^2, N, J, kJ, W, kW, Pa, °C, mol, rad, kg, g, s, min, h, %).
     - So khớp thông minh: chấp nhận viết liền hoặc cách đơn vị (`2A` vs `2 A`), cho phép khuyết đơn vị nếu đề bài đã có sẵn, phạt sai nếu nhập nhầm đơn vị khác loại (`2V` vs `2A`).
  2. Tích hợp Backend:
     - `services/api/app/routes/v1.py`: Chấm bài tự luận chữ và lưới an toàn cho bài chụp ảnh trong phiên báo thức sáng.
     - `services/api/app/services/pvp_match_service.py`: Chấm bài nộp trong từng round đấu trường PvP 1v1.
  3. Tích hợp Flutter Client:
     - `app/lib/domain/services/answer_normalizer.dart`: Đồng bộ logic parser số và đơn vị trên client.
     - `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`: Sử dụng `isAnswerAccepted` cho luồng debug fixture.
- **Kiểm thử & Môi trường:**
  - Backend: `pytest test_answer_normalizer.py` (9/9 PASS), toàn bộ cụm PvP & Timetable (16/16 PASS).
  - Frontend: `flutter test test/answer_normalizer_test.dart` (5/5 PASS), toàn bộ Flutter test suite (52/52 PASS).
  - Docker Container: `api-api-1` đã được rebuild và chạy healthy.
- **Rủi ro & Ghi chú:**
  - Với các câu hỏi trắc nghiệm chữ cái (A, B, C, D) hoặc tiếng Anh/văn học, normalizer giữ nguyên cơ chế chuỗi thuần để tránh nhận nhầm chữ cái đơn thành đơn vị.
- **Điểm tiếp tục chính xác:**
  - Tiếp tục nâng cấp các quy tắc so khớp cho vector toán học và tọa độ điểm `(x; y)` hoặc `(x, y)`.
