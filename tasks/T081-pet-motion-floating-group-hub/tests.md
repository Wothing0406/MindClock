# Kế hoạch và kết quả kiểm thử T081

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Render `MamPetView` + `FloatingMiniPetOverlay` với dữ liệu nhóm, bấm mở popup & thu gọn | Hiện `Chuỗi N`, `X/Y`, popup mở nhanh, không lỗi ticker/Reduce Motion | `flutter test --no-pub -j 1 test/t081_pet_motion_and_group_hub_test.dart` | PASS (2/2 test trong file `t081`) — 27/11/2026 |
| TC-02 | AC-03, AC-04 | Regression `TodayPetCard` & `CommitmentGroupScreen` ở `320dp` `200%` | Không overflow, có nút Tạo nhóm / Nhập mã / Copy mã, không lộ người chưa chăm | `flutter test --no-pub -j 1 test/t081_pet_motion_and_group_hub_test.dart test/t075_today_pet_share_test.dart test/t079_group_streak_and_clean_arena_test.dart` | PASS (9/9 tests passed) — 27/11/2026 |
