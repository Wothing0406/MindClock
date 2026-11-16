# Kế hoạch thực hiện T040

- [x] **Bước 1:** Backend: Xây dựng module `services/api/app/services/answer_normalizer.py` bao gồm các hàm chuẩn hóa số thập phân, phân số, biến số và đơn vị đo lường.
- [x] **Bước 2:** Backend: Viết bộ kiểm thử toàn diện `services/api/tests/test_answer_normalizer.py` bao quát AC-01 đến AC-05 (9/9 PASS).
- [x] **Bước 3:** Backend: Tích hợp `answer_normalizer.py` vào `routes/v1.py` (chấm bài phiên sáng) và `pvp_match_service.py` (chấm bài PvP).
- [x] **Bước 4:** Frontend: Xây dựng `app/lib/domain/services/answer_normalizer.dart` và tích hợp vào `DebugFixturePersonalFlowRepository`, viết `test/answer_normalizer_test.dart` (5/5 PASS).
- [x] **Bước 5:** Chạy toàn bộ test suites (backend pytest 16/16 PASS & Flutter test 52/52 PASS), cập nhật tài liệu và hồ sơ bàn giao.
