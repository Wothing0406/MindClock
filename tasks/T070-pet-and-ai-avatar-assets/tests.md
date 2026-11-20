# Kiểm thử

TC01 ↔ AC01/02: xem master/biểu cảm ở kích thước dùng, alpha trên nền sáng/tối, cùng nhận diện.
TC02 ↔ AC03: file manifest/hash/frame size/anchor/nguồn và preview.
TC03 ↔ AC04: state/Reduce Motion/fallback Flutter nếu nối runtime.

## Kết quả 20/11/2026 Windows

- 7 lần image_gen built-in thực: master Mầm, master AI, expression AI, stages pet, reactions v1, nền học, sửa reactions v2. Không có video route; không gọi CLI/API với key. Source/prompt/generation IDs trong assets/companions/prompts.md và manifest.
- Xem trực tiếp master/source và contact sheet final trên nền sáng/tối: tai/tay/pouch trong canvas, AI cùng nhận diện. Bộ pet: 4 stage + 6 reaction tĩnh; AI 9 expression UI; nền 960×640.
- Raw reactions v1 FAIL cross_cell_components=1 threshold0, cross_cell_visible=1 threshold0; không dùng. Sửa bằng image_gen tăng gutter, v2 không còn cross-cell fail. Các WARN boundary_band/safe_frame/faint_specks nguồn giữ nguyên đủ giá trị/file/threshold trong assets/companions/qa-report.md và JSON, không tuyên bố mọi nguồn đều sạch.
- Sprite process strict-QC PASS cho AI/stages/reactions-v2; export alpha hygiene/registration/downscale premultiplied; không vẽ/sửa thiết kế nhân vật bằng code. Mỗi runtime tile256×256 RGBA, không cắt biên.
- `python scripts/check_companion_assets.py`: PASS 19 tile, hash/source/app copies, alpha, biên, số frame preview. Tổng runtime19 tile+nền777138 bytes, ZIP10649115 bytes tại thời điểm kiểm (metadata có thể đổi kích thước archive sau cập nhật docs).
- `flutter test --no-pub test/t070_companion_assets_test.dart test/community_friends_and_meet_room_test.dart test/t068_community_room_controls_test.dart test/t069_room_settings_and_refresh_test.dart`: PASS21 trước bổ sung2 ca cadence/fallback.
- `flutter test --no-pub test/t070_companion_assets_test.dart`: PASS7 sau bổ sung cadence/fallback. Các ca blink frame riêng, audioLevel gate, dừng khi hết audio, Reduce Motion/animatefalse, thinking/listening/encouraging, nhãn AI và petprops.
- Analyze trước bổ sung2 test PASS, sửa lint if braces. Kiểm cuối sẽ chạy trước commit.

Lỗi môi trường: Flutter không xóa được app/build/unit_test_assets do directory ReadOnly; đã kiểm path trong build, không reparse, gỡ ReadOnly và dọn riêng cache sinh ra rồi chạy lại PASS. Lặp lại khi đóng gói lại art; chưa xác định nguyên nhân Windows đặt ReadOnly. Không sửa SDK/source/assets để lách test.

Chưa build/rà Android APK, đo FPS/memory máy thật, full-body video motion, lip sync âm vị, Live audio transport hay nhóm/pet ledger/share. Speaking UI là trạng thái caller phải cấp từ audio thật; màn text hiện để false, không suy từ chat history.
