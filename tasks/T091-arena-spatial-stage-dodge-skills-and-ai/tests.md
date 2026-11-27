# Kế hoạch và kết quả kiểm thử T091

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Chọn bản đồ `Ngẫu nhiên` hoặc bản đồ cụ thể và bắt đầu trận (`showLoadingScreen: true`) | `resolvedMapId` chốt cố định ngay trước trận và giữ nguyên xuyên suốt trận | `flutter test --no-pub -j 1 test/t091_arena_spatial_dodge_and_ai_test.dart` (Windows 11, Flutter test VM) | PASS (`2026-11-27`) |
| TC-02 | AC-02 | Nhấn `Né chiêu` (`arena-dodge-btn`) trước khi giải/ra đòn | Đổi sang làn khác `botAttackLane`, `dodgeActiveThisTurn = true`, sát thương nhận từ Máy tập giảm 65% so với không né | `flutter test --no-pub -j 1 test/t091_arena_spatial_dodge_and_ai_test.dart` | PASS (`2026-11-27`) |
| TC-03 | AC-03 | Bật `Tự tung` rồi giải đúng câu hỏi | Engine tự chọn chiêu hợp lệ cao nhất theo Qi hiện có và chuyển sang `roundFeedback` | `flutter test --no-pub -j 1 test/t091_arena_spatial_dodge_and_ai_test.dart test/t065_skill_hand_test.dart` | PASS (`2026-11-27`) |
| TC-04 | AC-04 | Hồ sơ `Lớp 12` vào Đấu trường + chuyển đổi `PersonalizedPracticeQuestion` (`POST /v1/questions/personalized`) | Bộ câu đầu trận khớp `Lớp 12`; wire trả `acceptedAnswers` (0 XP) và nạp câu AI có kiểm soát | `flutter test` + `pytest -q tests/test_api_v1.py -k personalized` | PASS (`2026-11-27`) |
| TC-05 | AC-01, AC-02, AC-03 | Render màn dọc `360x800` với `ArenaStageWidget` + `ArenaSkillHand` sau pha người chơi đánh trúng, đối thủ trượt | Hai tướng đối diện đúng hướng (`facingRight` trái/phải), `arena-hit-impact-bot` chỉ xuất hiện ở phía đối thủ, dùng đúng `assets/arena/skill_*.png` và nhãn `Đánh thường`, `Chiêu 1`, `Chiêu 2`, `Chiêu 3` | `flutter test --no-pub -j 1 test/t091_arena_spatial_dodge_and_ai_test.dart` | PASS (`2026-11-27`) |
| TC-06 | AC-01 | Kiểm tra tĩnh hệ thống token giao diện | `flutter analyze --no-pub` 0 lỗi; `arena_stage_widget.dart` có 0 hằng màu `Color(0x...)` | `flutter analyze --no-pub` + `TC-06` + bộ 8 file test Đấu trường (`28/28 PASS`) | PASS (`2026-11-27`) |
| TC-07 | Rủi ro thiết bị | Chạy thử trực tiếp trên máy Android vật lý | Kiểm tra tốc độ dựng frame và cảm giác bấm trên màn hình vật lý | Cần cắm máy Android qua ADB (`adb devices` hiện trống) | Giới hạn môi trường: chưa cắm máy Android vật lý (`2026-11-27`) |

## Lệnh kiểm thử thực tế đã chạy (`2026-11-27`)

- `cd app; flutter analyze --no-pub` -> `No issues found! (ran in 7.9s)`.
- `cd app; flutter test --no-pub -j 1 test/t091_arena_spatial_dodge_and_ai_test.dart test/solo_arena_widget_test.dart` -> `10/10 All tests passed!`.
- Bộ mở rộng Đấu trường (`t065_skill_hand_test.dart`, `t086_study_microcheck_and_arena_stage_test.dart`, `t087_arena_quick_cards_test.dart`, `t079_group_streak_and_clean_arena_test.dart`, `t062_offline_bank_alarm_and_arena_timer_test.dart`, `arena_pvp_and_sprites_test.dart`) -> Tất cả PASS.
- `cd services/api; .\.venv\Scripts\pytest.exe -q tests/test_api_v1.py -k "personalized"` -> `2 passed`.
- `python scripts/check_docs_links.py` -> `PASS local links in 754 Markdown files`.
