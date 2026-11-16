# Nhật ký thực hiện T040

## Vòng 1: Khởi tạo nhiệm vụ
- Phân tích yêu cầu người dùng: Chuẩn hóa đáp án số thập phân, phân số, đơn vị đo lường và biểu thức toán học.
- Tạo cấu trúc task T040, xác định AC-01 đến AC-05 và thiết kế ma trận kiểm thử.

## Vòng 2: Xây dựng Backend Answer Normalizer
- Tạo module `services/api/app/services/answer_normalizer.py`:
  - Phân tích và chuẩn hóa dấu phẩy số thập phân (`0,5` -> `0.5`, `3,14` -> `3.14`).
  - Phân tích phân số dạng thường (`3/4`), phân số tối giản và LaTeX (`\frac{a}{b}`).
  - Bóc tách tên biến phương trình (`x = 8`, `v = 10`, `i = 2a`).
  - Bảng tra cứu từ đồng nghĩa đơn vị đo lường chuẩn hóa THPT (dòng điện, điện thế, điện trở, vận tốc, gia tốc, lực, công, công suất, áp suất, nhiệt độ, góc, phần trăm, độ dài, khối lượng, thời gian).
  - Hàm so khớp `is_answer_accepted` với dung sai epsilon số học $10^{-5}$ và linh hoạt đơn vị.
- Viết bộ unit test `services/api/tests/test_answer_normalizer.py`: 9/9 PASS.

## Vòng 3: Tích hợp Hệ thống Backend
- Tích hợp vào `services/api/app/routes/v1.py`:
  - Chấm bài tự luận text trong phiên học sáng (`submit_alarm_answer`).
  - Lưới an toàn cho ảnh chụp bài làm (`submit_alarm_photo_attempt`).
- Tích hợp vào `services/api/app/services/pvp_match_service.py`:
  - Chấm bài làm vòng đấu PvP 1v1 (`submit_round_answer`).
- Rebuild Docker container backend `api-api-1` và kiểm tra hoạt động.

## Vòng 4: Xây dựng Client Normalizer trên Flutter Dart
- Tạo `app/lib/domain/services/answer_normalizer.dart` đồng bộ logic chuẩn hóa toán và đơn vị.
- Tích hợp vào `app/lib/data/debug/debug_fixture_personal_flow_repository.dart`.
- Viết `app/test/answer_normalizer_test.dart`: 5/5 test groups PASS.
- Chạy toàn bộ Flutter test suite: 52/52 PASS.
