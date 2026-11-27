# Đặc tả nhiệm vụ T091

## Vấn đề và kết quả mong muốn

Người dùng phản hồi trực tiếp trên bản APK Android:
1. Sân đấu trước đây đóng khung 2 nhân vật trong 2 hộp chữ nhật hẹp, thiếu vị trí/làn không gian rõ ràng và chưa có cơ chế né chiêu.
2. Thanh chiêu trước đây lấy frame toàn thân nhân vật thay vì asset kỹ năng (`assets/arena/skill_*.png`), nhãn dài gây rối.
3. Chọn bản đồ trong `arena_screen.dart` bị lặp khối 3 lần, thiếu `Ngẫu nhiên` chốt trước trận.
4. Học sinh Lớp 12 vào Đấu trường bị rơi về câu Lớp 10 do thiếu truyền `gradeLevel` và thiếu bộ câu Toán/Lý/Anh/Sinh Lớp 12 trong cache cục bộ, đồng thời `setContinuousQuestionProvider` chưa nối API câu cá nhân hóa.
5. Cần xác minh và ghi rõ quyết định kỹ thuật về Unity dựa trên bằng chứng thực tế trong repo.

## Phạm vi

- **Trong phạm vi:** `services/api/app/routes/v1.py`, `study_ai_models.dart`, `solo_training_question_bank.dart`, `solo_arena_view_model.dart`, `arena_stage_widget.dart`, `arena_skill_hand.dart`, `arena_screen.dart`, `mindclock_shell_screen.dart`, `t091_arena_spatial_dodge_and_ai_test.dart`.
- **Ngoài phạm vi:** Không tích hợp Unity Android AAR/IL2CPP trong `T091`; không mở PvP Ranked; không gộp báo thức hay Không gian học vào `T091`.
- **Dữ liệu/role/quyền liên quan:** `/v1/questions/personalized` trả thêm `acceptedAnswers` cho câu nháp luyện tập `0 XP` thuộc chủ tài khoản; `/v1/challenges/next` của báo thức sáng giữ nguyên bất biến không trả đáp án trước nộp.
- **Tài liệu chuẩn:** `AGENTS.md §3`, `docs/01-product/03-he-thiet-ke.md`, `docs/04-game/01-pvp-gdd.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Chọn bản đồ cụ thể hoặc `Ngẫu nhiên` và vào trận | Chốt `resolvedMapId` cố định trước trận (ngay từ màn chuẩn bị/loading), hiển thị map nền + dải màu token chuẩn `MindClockTheme` (0 hằng màu hex rời), hai nhân vật đối diện nhau đúng hướng trên 3 làn sân dọc. | TC-01, TC-05, TC-06 |
| AC-02 | Người chơi bấm `Né chiêu` / `Chiêu 3` trước khi chốt lượt | Nhân vật bên xanh đổi làn ra khỏi làn báo trước của đối thủ và giảm 65% sát thương nhận vào trong lượt đó; đòn đánh nhắm tới vị trí mục tiêu và hiệu ứng nhận đòn (`arena-hit-impact-*`) chỉ xuất hiện tại phía thực sự mất máu. | TC-02, TC-05 |
| AC-03 | Hiển thị `ArenaSkillHand` và `Tự tung` | Dùng đúng `assets/arena/skill_*.png`, nhãn gọn `Đánh thường`, `Chiêu 1`, `Chiêu 2`, `Chiêu 3`, nội tại tự kích hoạt theo luật tướng (`arena-passive-auto-badge`), `Tự tung` chỉ chọn trong các action hợp lệ của combat engine. | TC-03, TC-05 |
| AC-04 | Hồ sơ học sinh (ví dụ `Lớp 12`) vào Đấu trường | Bộ câu khởi đầu khớp `Lớp 12` từ ngân hàng đã duyệt; khi đăng nhập online, `continuousQuestionProvider` nạp câu cá nhân hóa cùng `difficulty: 1` có kiểm soát, không tự đổi độ khó lệch giữa hai bên. | TC-04 |

## Quyết định kỹ thuật về Unity (Bằng chứng thực tế trong repo)

1. **Bằng chứng kiểm tra repo:**
   - Quét toàn bộ workspace `c:\Users\QuangDev\Downloads\Projects\web\MindClock` tìm `*.unity`, `ProjectSettings/ProjectVersion.txt`, `unityLibrary`, `flutter_unity_widget`: **0 kết quả** (các đường dẫn khớp chuỗi `*unity*` chỉ là `*community*` của tính năng phòng học cộng đồng).
   - Kiểm tra `app/pubspec.yaml`: chỉ phụ thuộc `flutter` và `shared_preferences: ^2.3.2`, không có plugin nhúng Unity.
   - Trên máy phát triển có cài `C:\Program Files\Unity\Hub\Editor\6000.6.0f1`, nhưng hoàn toàn chưa có Unity project, scene C#, asset bundle hay Android AAR trong repo MindClock.
2. **So sánh Flutter renderer hiện tại với Unity:**
   - **Phần Flutter renderer hiện tại đã đáp ứng tốt:** Sân đấu 2D màn dọc 3 làn, hoạt cảnh frame-by-frame WebP (`idle`, `basic`, `skill1`, `skill2`, `hurt`, `stun`, `heal`, `victory`), projectile bay tới tọa độ mục tiêu, hit-impact đúng phía, thanh HP/Giáp/Qi, bàn phím công thức Toán + 4 thẻ đáp án nhanh, hỗ trợ `Reduce Motion` / `TextScaler 200%` / TalkBack `Semantics`, khởi động tức thì trong cùng cây widget.
   - **Phần chỉ thực sự cần Unity khi mở rộng:** Chiến trường 3D thời gian thực có vật lý va chạm liên tục (rigidbody/hitbox 60fps), shader particle phức tạp nhiều lớp, skeletal mesh 2.5D/3D hoặc điều khiển joystick tự do.
   - **Tác động nếu nhúng Unity (`unityLibrary` AAR + IL2CPP) vào Android hiện tại:**
     - **Kích thước APK/AAB:** Tăng thêm khoảng `45–90 MB` riêng runtime `libunity.so` + `libil2cpp.so` (ARM64/ARMv7).
     - **Build & CI:** Phải xuất Unity Android Library trước khi chạy Gradle, phụ thuộc bản quyền/CLI Unity Editor `6000.x`, tăng thời gian build và rủi ro xung đột NDK/Gradle AGP với Kotlin `AlarmManager` native.
     - **Hiệu năng & Pin:** Khởi tạo `UnityPlayer` tiêu tốn thêm RAM/GPU, không phù hợp triết lý nhẹ và ổn định cho học sinh mở nhanh trên máy tầm trung.
   - **Prototype nhỏ nếu muốn đánh giá rủi ro sau này:** Tạo nhánh thử nghiệm độc lập (`spike/unity-arena-view`), xuất 1 scene 2D tối giản qua `flutter_unity_widget`, đo thời gian cold-start tab Đấu trường, mức tăng RAM, APK size và kiểm tra xem tiến trình `AlarmReceiver` nền của Kotlin có bị ảnh hưởng lifecycle khi hủy `UnityPlayer` hay không.
3. **Quyết định trong `T091`:** Giữ nguyên kiến trúc Flutter 2D hiện hành, không nhúng Unity trong `T091`.
