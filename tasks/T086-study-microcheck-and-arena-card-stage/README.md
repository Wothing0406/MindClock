# T086 — Không Gian Học Micro-Check + AI Khóa Giải Hộ & Sân Đấu Arena Card-Stage

- **Trạng thái:** `verifying`
- **Mục tiêu:**
  1. Nâng cấp Không gian học (`StudySpaceScreen`): thêm thẻ **Micro-Check 60 giây** kiểm tra nhanh kiến thức môn đang học để giữ tỉnh táo trong block `Học cùng MindClock`, và khóa Socratic (`Bước bạn đã tự thử`) ở phần MindClock AI.
  2. Nâng cấp **Đấu trường 2D Luyện đơn** (`ArenaStageWidget`, `ArenaSkillHand`, `ArenaScreen`): thêm thanh **Cảnh báo tụ chiêu** đối thủ (`arena-enemy-charge-bar`), mở rộng kích thước sprite + sân đấu mở rộng, dock thẻ chiến đấu (`arena-skill-hand-dock`), và chip điền nhanh khung bước biến đổi.
- **Nguồn yêu cầu:** Yêu cầu trực tiếp của người dùng ngày `27/11/2026`.
- **Chủ sở hữu/reviewer:** MindClock Team
- **Phạm vi file đã sửa:**
  - `app/lib/ui/features/study_focus/views/study_space_screen.dart`
  - `app/lib/ui/features/arena/views/arena_stage_widget.dart`, `arena_skill_hand.dart`, `arena_screen.dart`
  - `app/test/t086_study_microcheck_and_arena_stage_test.dart`
- **Liên quan:** Kế thừa `T082`, `T083`, `T065`.
- **Source refs đã đọc:** `docs/01-product/08-phong-hoc-ai-va-ban-be.md`, `app/lib/ui/features/study_focus/views/study_space_screen.dart`, `app/lib/ui/features/arena/views/arena_screen.dart`.
- **Điểm tiếp tục:** Kiểm tra trải nghiệm thực chiến trên máy Android thật và commit khi người dùng yêu cầu.

## Cổng trước coding

- [x] Đã đọc bất biến phòng học (`camera/mic tắt mặc định`, `không chấm gian lận`, `AI không làm bài hộ`) và bất biến Arena (`2D gốc MindClock`, `Reduce Motion & Bỏ qua hiệu ứng giữ nguyên số liệu`).
- [x] `spec.md`, `plan.md`, `tests.md` có nội dung cụ thể.

## Cổng kết thúc

- [x] Acceptance trong `spec.md` đạt và test xanh.
- [x] Các bước `plan.md` đã đánh dấu thật.
- [x] `tests.md` có lệnh, kết quả, ngày/môi trường.
- [x] `handoff.md` nêu cách kiểm tra và điểm tiếp tục.
