# Kế hoạch thực hiện T091

## Điểm bắt đầu

- Repo có `T091` đang mở trên `main` (`9558f70`), Docker `api-postgres-1` và `api-api-1` đang healthy.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Rà toàn bộ diff hiện có của `T091`, đối chiếu AC trong `spec.md`, kiểm tra hiện trạng Unity và token `MindClockTheme` | Xác định rõ 9 hằng hex cần xóa, lỗi thứ tự `_matchFinished` khi né, thiếu câu Toán Lớp 12 offline và căn tọa độ hit-impact | [x] |
| 2 | Cập nhật `_question_to_personalized_wire`, `PersonalizedPracticeQuestion`, bổ sung bộ câu duyệt GDPT 2018 Lớp 12 (`math`, `physics`, `english`, `biology`) trong `solo_training_question_bank.dart`, sửa `_settleCurrentRound` trong `solo_arena_view_model.dart` | Không còn lỗi Lớp 12 rơi về Lớp 10; né đòn giảm sát thương chính xác | [x] |
| 3 | Chuẩn hóa `ArenaStageWidget` (0 raw hex, projectile bay đúng tọa độ mục tiêu, `arena-hit-impact-*` đúng phía), `ArenaSkillHand` (`Đánh thường`, `Chiêu 1`, `Chiêu 2`, `Chiêu 3`, `arena-passive-auto-badge`), dọn lặp map ở `ArenaScreen` và giữ độ khó công bằng ở `MindClockShellScreen` | `flutter analyze --no-pub` 0 lỗi, 0 raw hex | [x] |
| 4 | Chạy `t091_arena_spatial_dodge_and_ai_test.dart`, bộ test Đấu trường liên quan, `pytest` API + PostgreSQL 16 và script kiểm tra hồ sơ/liên kết | Toàn bộ bài test chạy qua xanh, ghi nhận đầy đủ vào `tests.md` & `handoff.md` | [x] |

## Rủi ro và đường lui

- Đã loại bỏ trùng `ValueKey('arena-map-*')` do 3 khối chọn bản đồ lặp trong `arena_screen.dart`.
- Chưa có thiết bị Android vật lý cắm ADB nên giữ trạng thái `verifying` theo đúng `AGENTS.md`.
