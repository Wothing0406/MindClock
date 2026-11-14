# T019 — Tích hợp frontend MindClock với hợp đồng backend (Báo thức thử thách & Không gian học AI)

- **Trạng thái:** `blocked`
- **Mục tiêu:** hoàn thiện tầng tích hợp frontend cho **Báo thức thử thách** (lưu/lập lịch local trước, đồng bộ `/v1/alarms` khi đăng nhập + có mạng, phân biệt 3 trạng thái `đã lưu local` / `OS đã lập lịch` / `đã đồng bộ server`, `Dừng khẩn cấp` dừng ngay và ghi nhận server sau không phát lại chuông) và **Không gian học AI** (timer local, đồng bộ phiên idempotent `POST /v1/study/sessions` & `/finish` không giữ kẹt người dùng khi lỗi API, `POST /v1/study/help` tối đa 3 lượt gần nhất với đủ trạng thái loading/timeout/rate-limit/offline giữ nguyên câu đang nhập); kèm file cấu hình `.env.example` + `.env` (ignored trong `.gitignore`) và bộ test đối chiếu 7 mục kiểm chứng.
- **Nguồn yêu cầu:** nhiệm vụ tích hợp frontend–backend (chỉ phạm vi Báo thức thử thách và Không gian học AI), tái sử dụng repo/service hiện có (`docs/07 §§1–3,8`, `docs/18`, `docs/24`, `docs/25`, `docs/45 §§1,5`, `T016`, `T017`, `T018`); ngày 14/11/2026.
- **Chủ sở hữu/reviewer:** coding agent / chủ dự án duyệt.
- **Phạm vi file dự kiến:** `.gitignore`, `app/.env.example`, `app/.env` (local untracked), `app/lib/domain/**`, `app/lib/data/**`, `app/lib/ui/**`, `app/lib/app.dart`, `app/test/**`, `tasks/T019-tich-hop-frontend-backend-bao-thuc-hoc-ai/*`.
- **Liên quan:** tái sử dụng `PersonalApiClient`, `FirebaseAuthGateway`, `GuestWorkspaceViewModel`, `StudyFocusViewModel`; phụ thuộc triển khai chạy thật backend [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md) (`planned`) + endpoint `/v1/study/*` trong `docs/45 §5` (chưa có trong repo).
- **Source refs đã đọc:** `docs/07 §§1–8`, `docs/45 §§1,5`, `tasks/T016-backend-fastapi-postgres-luong-ca-nhan/{README,spec,handoff}.md`, `tasks/T017-tich-hop-dich-vu-that-luong-ca-nhan/handoff.md`, `app/lib/data/services/personal_api_client.dart`, `app/lib/data/repositories/remote_personal_flow_repository.dart`, `app/lib/domain/models/alarm_config.dart`, `app/lib/ui/features/guest_shell/view_models/guest_workspace_view_model.dart`, `app/lib/ui/features/study_focus/**`, `.gitignore`.
- **Điểm tiếp tục:** hoàn tất chỉnh sửa code & bộ test `T019`, chạy kiểm tra tĩnh khả dụng; vì repo chưa có backend chạy thật và máy chưa cài Flutter SDK, đánh dấu `blocked` và lập bảng đối chiếu trung thực chạy thật vs mẫu.

## Cổng trước coding

- [x] Đã kiểm tra trạng thái backend thực tế trong repo: `services/api/` chưa tồn tại, `T016` đang ở trạng thái `planned`, `docs/45 §5` đánh dấu `/v1/study/*` là đặc tả hợp đồng.
- [x] Đã rà code frontend hiện có (`T014`, `T015`, `T017`, `T018`) để tái sử dụng `PersonalApiClient`, `FirebaseAuthGateway`, `GuestWorkspaceViewModel`, `StudyFocusViewModel`, không tạo client HTTP/Auth song song và không mở rộng ra Đấu trường/Avatar/Voice Live.
- [x] `spec.md`, `plan.md`, `tests.md` điền đầy đủ trước khi sửa code.

## Cổng kết thúc

- [ ] `flutter analyze` và `flutter test` pass toàn bộ suite (bao gồm test loopback `/v1` cho báo thức, đồng bộ `emergency_stop`, `/v1/study/sessions`, `/v1/study/help`, `/finish`, phân quyền A ↔ B và 0 leak key/token).
- [ ] Chạy kiểm chứng đầu-cuối thật với backend `services/api/` + PostgreSQL + Gemini + Firebase Auth (hiện bị chặn do backend chưa có trong repo).
