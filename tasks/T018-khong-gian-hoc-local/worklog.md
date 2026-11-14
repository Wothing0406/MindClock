# Nhật ký thực hiện và vòng sửa T018

## 2026-11-14

- Đọc `docs/45 §§1–6`, `AGENTS.md`, `tasks/README.md`, hai skill `flutter-apply-architecture-best-practices` & `mindclock-android-native`, cùng code Flutter & Android hiện tại.
- Phát hiện trước khi code: `app/lib/ui/core/widgets/mindclock_icon.dart` đang thiếu enum `MindClockIconKind.warning` (dù nhiều màn hình `T014/T015/T017` gọi nó) — đưa vào kế hoạch sửa trong bước 5 của `T018`.
- Hoàn tất hồ sơ `T018` (`README.md`, `spec.md`, `plan.md`, `tests.md`) trước khi sửa code.
- Cài đặt domain (`study_focus_models.dart`, `study_focus_bridge.dart`), data scoped theo `ownerScopeKey` + idempotent finish (`local_study_focus_repository.dart`, `method_channel_study_focus_bridge.dart`), Android native (`StudyFocusBridgeHandler.kt`, `MainActivity.kt`, `AndroidManifest.xml`), sửa `MindClockIconKind` (`warning`, `play`, `pause`, `stop`), xây `StudyFocusViewModel` + `StudySpaceScreen` và tích hợp vào `TodayScreen`, `PracticeSessionScreen`, `MindClockShellScreen`, `app.dart`.
- Viết bộ test `app/test/study_focus_local_test.dart` phủ `SF-TC-01..08` (`F01–F03`, `F07–F09`).
- Phát hiện và sửa ngay lúc rà soát: (1) stream bị gián đoạn trước đó làm mất `tasks/T018-khong-gian-hoc-local/README.md` (`check_task_records.py` báo thiếu) — đã tạo lại đầy đủ với trạng thái `blocked`; (2) `leftAtEpochMs` chỉ ghi khi đang `running && !commitmentAwaitingResume` để tránh trừ kép thời gian khi người dùng vừa `Tạm nghỉ` vừa thoát nền.
