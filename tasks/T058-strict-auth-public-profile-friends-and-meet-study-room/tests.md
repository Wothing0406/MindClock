# Kế hoạch và kết quả kiểm thử T058

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Render `WelcomeScreen` (không còn nút Guest) & `AuthScreen` nhập mật khẩu yếu (`123456`), mật khẩu mạnh (`MindClock@2026`), mở xem toàn văn Chính sách trước khi tích đồng ý | Mật khẩu yếu bị chặn kèm checklist; mở được sheet Chính sách; bật tài khoản sau khi đủ điều kiện | `flutter test test/auth_onboarding_flow_test.dart` | Chưa chạy |
| TC-02 | AC-03 | Gọi API Gói B trên PG16: tìm kiếm bạn, kết bạn hai chiều, tạo phòng `public` vs `invite_only`, `/ai-match` xếp điểm phù hợp khối/môn, check không lộ email/giờ chuông, check `DELETE /v1/me` | API trả 200/201/403 đúng owner & block rule, không rò dữ liệu riêng, PG16 pass hết | `pytest tests/test_community_rooms_and_friends.py` trên PostgreSQL 16 | Chưa chạy |
| TC-03 | AC-04, AC-05 | Widget test xem Profile công khai, gửi kết bạn, quét phòng công khai, chạy `AI ghép nhóm`, vào phòng Meet grid có cam/mic toggle + AI avatar 2D ở `320dp`, `textScale=2.0` | Render đủ lưới thẻ Meet, nút cam/mic mặc định tắt, AI 2D avatar hoạt động, không tràn layout | `flutter test test/community_friends_and_meet_room_test.dart` | Chưa chạy |
| TC-04 | AC-05 | Full `flutter analyze`, full `flutter test`, full `pytest` PG16, build APK debug & kiểm trên `emulator-5554` | 0 issue, `RAW_COLOR_HITS: 0`, 100% test pass, docs/task check pass | CI local + `emulator-5554` | Chưa chạy |
