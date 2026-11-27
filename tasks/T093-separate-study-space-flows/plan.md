# Kế hoạch thực hiện T093

## Điểm bắt đầu

- Nhánh `main` tại `d340740` (sau khi hoàn tất `T091` và `T092`).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T093-*`, kiểm tra `StudySpaceScreen`, `StudyCommunitySheet`, `TodayScreen` và các test hiện hữu | Chốt sơ đồ 3 luồng không trộn lẫn | [x] |
| 2 | Tái cấu trúc `StudySpaceScreen` & `StudyFocusViewModel`: 3 nút chọn chế độ (`solo`, `ai`, `friends`), bộ chọn `Bắt đầu ngay` / `Hẹn giờ`, tách riêng màn phiên `Học một mình` (thêm ghi chú vướng mắc), `Học cùng AI` (chat phiên, truyền môn/lớp/mục tiêu, hỏi bằng ảnh có consent, bỏ lặp `Tạo câu luyện`), và `Học cùng bạn` (ẩn hoàn toàn phần solo dưới phòng bạn bè) | Không còn chồng chéo UI giữa 3 chế độ | [x] |
| 3 | Lọc môn theo `StudyProfile` và mặc định tắt AI phòng trong `StudyCommunitySheet`; bỏ thẻ Không gian học lặp ở cuối `TodayScreen` | 1 điểm vào duy nhất trên màn chính, đúng môn hồ sơ | [x] |
| 4 | Viết `app/test/t093_study_space_three_flows_test.dart`, chạy `flutter analyze`, toàn bộ 12 bộ test Không gian học, kiểm tra scripts, commit & push `T093` | Tất cả test xanh, commit & push sạch | [x] |

## Rủi ro và đường lui

- Đã giữ nguyên các `ValueKey` kiểm thử hợp đồng (`study-mode-solo`, `study-mode-ai`, `study-personalized-generate-button`, `study-live-consent-toggle`, `study-open-community-hub`, `study-microcheck-toggle`, `study-ai-socratic-lock-toggle`) và bổ sung `study-mode-friends`, `study-timing-start-now`, `study-timing-schedule-later`, `study-confirm-schedule-button`, `study-solo-stuck-note-input`, `study-ai-photo-consent-btn`.
