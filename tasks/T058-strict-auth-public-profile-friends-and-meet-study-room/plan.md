# Kế hoạch thực hiện T058

## Điểm bắt đầu

- Đã xong T057 (`4f56aac` trên `origin/main`) và cập nhật docs chuẩn `04`, `07`, `08`, `02-engineering/04`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Cập nhật `WelcomeScreen`, `AuthScreen` (bỏ Guest UI, bắt buộc Mật khẩu mạnh + checklist, dialog Toàn văn Chính sách Bảo mật & Điều khoản), cập nhật `auth_onboarding_flow_test.dart` và các widget test liên quan | Auth widget tests PASS ở 320dp/200%, `flutter analyze` sạch | [ ] |
| 2 | Viết Alembic `0004` + ORM + FastAPI endpoints Gói B (`profiles`, `friends`, `study-rooms/public`, `ai-match`, dọn khi `DELETE /v1/me`) + `test_community_rooms_and_friends.py` | `pytest` trên PostgreSQL 16 thật PASS 100%, kiểm tra A không đọc dữ liệu riêng B | [ ] |
| 3 | Viết Flutter domain/repository models Gói B + UI `StudyCommunitySheet` (Profile công khai, Kết bạn, Quét phòng, AI ghép nhóm) + Meet-grid & `MindClockAiAnimatedAvatar` trong `StudySpaceScreen` | `community_friends_and_meet_room_test.dart` PASS ở 320dp/200%, `RAW_COLOR_HITS: 0` | [ ] |
| 4 | Chạy full `pytest` PG16, `flutter analyze`, `flutter test`, build/check emulator `emulator-5554`, cập nhật docs & push `origin/main` | Mọi test & script docs/task checks PASS, remote SHA ghi vào `handoff.md` | [ ] |
