# Kế hoạch thực hiện T018 — Không gian học local

## Điểm bắt đầu

- `app/` đã có luồng khách local (`T014`), cầu nối báo thức Android native (`T015`), và luồng cá nhân online/offline (`T017`).
- Chưa có model/repository/ViewModel/UI/Android bridge nào cho Không gian học tập trung (`docs/45`).
- Phát hiện `app/lib/ui/core/widgets/mindclock_icon.dart` thiếu enum `warning` dù các màn hình trước đang dùng.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T018-khong-gian-hoc-local/` (`README.md`, `spec.md`, `plan.md`, `tests.md`) sau khi đọc `docs/45`, hai skill chính/bổ trợ và mã nguồn hiện tại | Đủ cổng trước coding | [x] |
| 2 | Xây domain models & bridge contract (`app/lib/domain/models/study_focus_models.dart`, `app/lib/domain/services/study_focus_bridge.dart`): state machine chuẩn `docs/45 §2`, ngưỡng `Linh hoạt` / `Tập trung thường` / `Cam kết`, `elapsedWallSeconds` vs `inAppFocusSeconds` tính từ mốc thời gian | Test logic thuần chính xác, không phụ thuộc UI | [x] |
| 3 | Xây `LocalStudyFocusRepository` scoped `ownerScopeKey` + idempotent finish (`app/lib/data/repositories/local_study_focus_repository.dart`) và `MethodChannelStudyFocusBridge` (`app/lib/data/services/method_channel_study_focus_bridge.dart`) | Lưu/khôi phục snapshot & history sạch giữa các tài khoản; fallback unbound an toàn ngoài Android | [x] |
| 4 | Nối Android native (`StudyFocusBridgeHandler.kt`, cập nhật `MainActivity.kt`, `<queries>` Digital Wellbeing trong `AndroidManifest.xml`): mở Digital Wellbeing Focus settings với fallback trung thực, kênh notification riêng `mindclock_study_focus` (`NOTIFICATION_ID = 4301`, `setOnlyAlertOnce(true)`), xin `POST_NOTIFICATIONS` chỉ khi user bật tùy chọn, không chạm `AlarmSchedulerImpl`/`AlarmRingService` | Bridge trả kết quả typed, không dùng Accessibility/overlay/UsageStats/kiosk | [x] |
| 5 | Sửa `MindClockIconKind` (`warning`, `play`, `pause`, `stop`) + `AppStrings`; xây `StudyFocusViewModel` (`app/lib/ui/features/study_focus/view_models/study_focus_view_model.dart`) và `StudySpaceScreen` (`app/lib/ui/features/study_focus/views/study_space_screen.dart`); tích hợp vào `TodayScreen`, `PracticeSessionScreen`, `MindClockShellScreen` và `app.dart` | Đủ vòng chọn việc → thời lượng 5–120p → bắt đầu → tạm nghỉ/tiếp tục → rời app/gián đoạn → kết thúc; không XP ảo; 320–600 dp & chữ 200% | [x] |
| 6 | Viết unit + contract + widget tests (`app/test/study_focus_local_test.dart`) phủ `F01–F03`, `F07–F09`, cập nhật `tests.md`, `worklog.md`, `handoff.md`, `README.md`, chạy `check_docs_links.py`, `check_task_records.py` và rà soát tĩnh | Không còn lỗi P0/P1 trong phạm vi; phản ánh trung thực phần chưa chạy nếu thiếu Flutter SDK/máy thật | [x] |

## Rủi ro và đường lui

- **Sai đồng bộ vòng đời Android (`hidden` vs `paused`):** Flutter 3.13+ gửi cả `hidden` lẫn `paused` khi app xuống nền; nếu xử lý cả hai lần lượt có thể ghi đè `leftAt`. Giảm thiểu bằng cờ `_isBackgrounded` trong `StudyFocusViewModel` chỉ ghi `leftAt` một lần cho tới khi nhận `resumed`.
- **Chồng thông báo trên Android:** Nếu dùng ID động mỗi lần rời >30s sẽ vi phạm *"không chồng thông báo"*. Cố định `NOTIFICATION_ID = 4102` + `setOnlyAlertOnce(true)` và tự hủy khi `resumed`.
- **Mất dữ liệu hoặc đếm sai sau kill app:** Nếu giữ nguyên trạng thái `running` qua cold start sẽ cộng nhầm thời gian app đã chết vào `inAppFocusSeconds`. Luôn chuyển snapshot chưa đóng từ cold start sang `interrupted` (`Phiên đã gián đoạn`).
