# Kế hoạch thực hiện T019

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T019-tich-hop-frontend-backend-bao-thuc-hoc-ai/`, kiểm tra repo backend (`T016`) và hợp đồng `docs/07`, `docs/45 §5` | Đủ cổng trước coding | [x] |
| 2 | Cập nhật `.gitignore` (chặn `.env` / `app/.env` / `*.env.local`), tạo `app/.env.example` và `app/.env` cục bộ không chứa secret thật | Không đưa secret lên git | [x] |
| 3 | Mở rộng `PersonalApiClient` (`patchJson`, `deleteNoContent`, `putJson` + normalized list response), tạo `AlarmSyncGateway` + `RemoteAlarmSyncGateway`, `PendingAlarmEventStore` (7 ngày), `StudyAiGateway` + `RemoteStudyAiGateway`, cùng `app/lib/data/debug/` có `isDebugFixture => true` | Tái sử dụng 100% `PersonalApiClient` & `FirebaseAuthGateway`, không nhân bản client auth/HTTP | [x] |
| 4 | Nâng cấp `AlarmConfig` (server sync status độc lập OS) + `GuestWorkspaceViewModel` (lưu local/OS trước, sync khi đăng nhập + có mạng, hàng đợi dismiss không phát lại chuông) + `TodayScreen` hiển thị 3 nhãn phân biệt | API lỗi không làm mất/hủy chuông local; đổi tài khoản B không kế thừa nhãn synced của A | [x] |
| 5 | Nâng cấp `StudyFocusSessionSnapshot`/`Record` (`createIdempotencyKey`, `finishIdempotencyKey`), `StudyFocusViewModel` + `StudySpaceScreen` (tạo/kết thúc idempotent không giữ kẹt màn học, chat `Hỏi MindClock` qua `/v1/study/help` đủ loading/timeout/429/offline/401, giữ input khi lỗi + retry thủ công) | Timer local & kết thúc luôn chạy thông khi mất mạng/backend tắt | [x] |
| 6 | Nối DI 1 `PersonalApiClient` duy nhất trong `app/lib/app.dart` & `MindClockShellScreen`, mở rộng `LoopbackV1ContractServer`, viết `app/test/backend_integration_contract_test.dart`, chạy static scan & cập nhật `T019` (`blocked` do thiếu Flutter SDK trên máy & thiếu `services/api/` trong repo) | Báo cáo trung thực chạy thật vs mẫu và giới hạn | [x] |
