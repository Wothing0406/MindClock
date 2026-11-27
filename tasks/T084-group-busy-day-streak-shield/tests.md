# Kế hoạch và kết quả kiểm thử T084

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Nhóm 2 người: ngày 1 cùng làm (`Chuỗi 1`), ngày 2 B báo bận + A làm, ngày 3 cả 2 làm; thử báo bận lần 3 trong tháng | Ngày 2 bảo lưu `Chuỗi 1`, ngày 3 lên `Chuỗi 2`; lần 3 trong tháng bị chặn `409` | `pytest -q tests/test_t084_group_busy_days.py tests/test_commitment_groups_and_pet.py` | PASS (6/6 passed) — 27/11/2026 |
| TC-02 | AC-03 | Render `CommitmentGroupScreen` & `TodayPetCard` ở `320dp 200%`, bấm Báo bận hôm nay | Hiện trạng thái bảo lưu Chuỗi, cập nhật quota `1/2`, không lộ tên thành viên bận | `flutter test --no-pub -j 1 test/t084_group_busy_day_test.dart test/t081_pet_motion_and_group_hub_test.dart test/t079_group_streak_and_clean_arena_test.dart` | PASS (5/5 passed) — 27/11/2026 |
