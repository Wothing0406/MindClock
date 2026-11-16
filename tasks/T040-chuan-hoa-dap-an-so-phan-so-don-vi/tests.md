# Kế hoạch & Kết quả kiểm thử T040

## Ma trận kiểm thử

| Mã TC | Nội dung kiểm thử | Kết quả mong đợi | Trạng thái |
|---|---|---|---|
| TC-NORM-01 | Số thập phân: `0,5` vs `0.5`, `3,14` vs `3.14`, số 0 đuôi `2.50` vs `2.5` | Khớp đúng tương đương | PASS (`test_answer_normalizer.py`) |
| TC-NORM-02 | Phân số: `3/4` vs `0.75`, `\frac{1}{2}` vs `0,5`, `6/8` vs `3/4` | Khớp đúng tương đương | PASS (`test_answer_normalizer.py`) |
| TC-NORM-03 | Biến số & phương trình: `x = 8`, `x=8`, `X = 8`, `8` | Khớp đúng tương đương | PASS (`test_answer_normalizer.py`) |
| TC-NORM-04 | Đơn vị đo: `2A`, `2 A`, `2 a`, `I = 2A`, `10 m/s`, `10m/s` | Khớp đúng khi đúng đơn vị hoặc khuyết đơn vị tương thích | PASS (`test_answer_normalizer.py`) |
| TC-NORM-05 | Sai đơn vị: `2V` khi đáp án chuẩn là `2A` | Đánh giá sai (`incorrect`) | PASS (`test_answer_normalizer.py`) |
| TC-NORM-06 | Văn bản / trắc nghiệm chữ: `ẩn dụ`, `A`, `Aa`, `has lived` | Hoạt động bình thường như cũ | PASS (`test_answer_normalizer.py`) |
| TC-NORM-07 | Tích hợp Route v1: `submit_alarm_answer` nhận diện `8,0` khi accepted là `['8', 'x=8']` | Trả về `result: 'correct'` | PASS (`test_v1_route_submit_answer_normalizer_decimal_and_fractions`) |
| TC-NORM-08 | Tích hợp PvP: `submit_round_answer` nhận diện `2A` khi accepted là `['2', '2 A']` | Trả về `grade_status: 'correct'` | PASS (`test_pvp_matchmaking.py`) |
| TC-NORM-09 | Flutter Client Unit Test: `test/answer_normalizer_test.dart` (5 nhóm kiểm thử) | 5/5 assertions PASS | PASS (`test/answer_normalizer_test.dart`) |
