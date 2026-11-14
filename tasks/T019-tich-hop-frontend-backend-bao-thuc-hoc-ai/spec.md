# Đặc tả T019 — Tích hợp frontend Báo thức thử thách & Không gian học AI

## Vấn đề và kết quả mong muốn

Frontend hiện đã có luồng cá nhân (`/v1/challenges/next`, `/v1/sessions`, `/answers`, `/attempts`, `/feedback`, `/progress/summary` từ `T017`), cầu nối báo thức Android native (`T015`) và Không gian học local (`T018`), nhưng chưa nối đồng bộ `/v1/alarms` + sự kiện dừng khẩn cấp sau local stop, chưa tách rõ 3 lớp trạng thái báo thức (`đã lưu local` / `OS đã lập lịch` / `đã đồng bộ server`), chưa tích hợp Không gian học AI (`POST /v1/study/sessions`, `POST /v1/study/help`, `POST /v1/study/sessions/{id}/finish`), và chưa có tệp cấu hình `.env` mẫu.

## Phạm vi

- **Trong phạm vi:**
  1. **Báo thức thử thách & đồng bộ `/v1/alarms` (`docs/07 §§2–3,8`):**
     - Lưu cấu hình và lập lịch local OS **trước**, không chờ mạng hay backend.
     - Khi đã đăng nhập và có mạng, đồng bộ lên `GET/POST /v1/alarms`, `PATCH /v1/alarms/{id}`, `DELETE /v1/alarms/{id}` qua `PersonalApiClient` (tái sử dụng Bearer Firebase ID token + single refresh khi `401`).
     - UI `TodayScreen` hiển thị phân biệt 3 trạng thái: `Đã lưu trên máy`, trạng thái OS (`OS đã lập lịch: Đã sẵn sàng` / `Thiếu quyền` / `Chưa nối OS`), và trạng thái server (`Đã đồng bộ server` / `Đang đồng bộ server` / `Chưa đồng bộ server`).
     - Lỗi API (500/401/offline/timeout) **tuyệt đối không hủy chuông local** và không báo sai OS đã đặt.
     - `Dừng khẩn cấp` dừng âm/rung local ngay lập tức; việc gửi sự kiện `dismiss`/`emergency_stop` lên server thực hiện sau (kèm hàng đợi retry metadata an toàn dùng `Idempotency-Key`, giới hạn cục bộ 7 ngày theo `docs/07 §8`) và **tuyệt đối không gọi phát lại hay đặt lại chuông đang kêu**.
     - Đổi tài khoản A ↔ B xóa dấu đồng bộ server của tài khoản A khỏi UI trong khi giữ nguyên báo thức local trên máy.
  2. **Không gian học AI (`docs/45 §5`):**
     - Timer, tạm nghỉ/tiếp tục, khôi phục gián đoạn và kết thúc vẫn chạy **100% local**.
     - Khi đăng nhập và có mạng, đồng bộ tạo phiên `POST /v1/study/sessions` dùng lại **cùng `clientSessionId` (`sessionId`)** và **`createIdempotencyKey`** khi retry; không gửi `leftAt`, danh sách app hay XP.
     - Hỏi AI qua `POST /v1/study/help` (không gọi Gemini trực tiếp từ client): chỉ gửi `subject`, `grade`, `task`, `questionText` và tối đa **3 lượt gần nhất**; hiển thị rõ 5 trạng thái (`loading`, `timeout`, `429 quá giới hạn`, `mất mạng/offline` với mẫu cục bộ, `401 hết hạn token`), **giữ nguyên câu người dùng đang nhập khi lỗi**, và có nút `Thử lại`.
     - Kết thúc phiên gọi `POST /v1/study/sessions/{id}/finish` idempotent (cùng `finishIdempotencyKey` trên mọi lần retry); lỗi API không giữ người dùng kẹt trong màn học (vẫn lưu local & thoát ngay được, đồng thời cho phép bấm thử đồng bộ lại thủ công sau đó). Không tự động gửi chat hay bản nháp chưa được người dùng xác nhận.
  3. **Auth & cấu hình môi trường:**
     - Firebase ID token gắn qua `PersonalApiClient`; `401` hết hạn chỉ ảnh hưởng tính năng online; không gắn secret hay UID cố định vào bản release (`MINDCLOCK_DEBUG_FIXTURE` chỉ mở khi `kDebugMode`).
     - Mẫu demo/fixture nằm riêng dưới `app/lib/data/debug/` với nhãn rõ ràng.
     - Tạo `app/.env.example` (git-tracked) và `app/.env` (git-ignored) + cập nhật `.gitignore`.
- **Ngoài phạm vi:** Đấu trường PvP, linh thú/avatar marketplace, voice Live API, camera theo dõi học tập, và backend FastAPI/PostgreSQL thực tế (`T016` vẫn đang `planned`).
- **Tài liệu chuẩn:** `docs/07 §§1–3,8`, `docs/18 §§2–5`, `docs/24`, `docs/25`, `docs/45 §§1,5`, `T016`, `T017`, `T018`.

## Yêu cầu kiểm chứng được

| ID | Yêu cầu | Hành vi hệ thống phải làm | Kiểm thử |
| --- | --- | --- | --- |
| `INT-AC-01` | Chuông hoạt động khi backend tắt / lỗi | Lưu & lập lịch báo thức, tắt chuông bằng `Dừng khẩn cấp` chạy ngay dù backend trả 500/offline/401; không hủy chuông local; ghi nhận server chạy sau và không phát lại chuông | `INT-TC-01` |
| `INT-AC-02` | UI phân biệt 3 lớp trạng thái báo thức | `TodayScreen` hiển thị tách biệt: `Đã lưu trên máy`, `Đã sẵn sàng` (OS), và `Đã đồng bộ server` / `Chưa đồng bộ server` | `INT-TC-02` |
| `INT-AC-03` | Timer học vẫn đúng khi mất mạng | Chọn việc, chạy, rời app, tạm nghỉ/kết thúc tính đúng theo mốc thời gian kể cả khi offline hoặc `POST /v1/study/*` lỗi; lỗi `/finish` vẫn cho lưu local & rời màn hình | `INT-TC-03` |
| `INT-AC-04` | Hỏi AI đi qua `/v1/study/help`, không gọi Gemini trực tiếp | Gửi `clientSessionId`, `subject`, `grade`, `task`, <=3 lượt gần nhất với Bearer token; xử lý `loading`, `timeout`, `429`, `offline`, giữ nguyên text đang nhập khi thất bại và cho `Thử lại`; không tự gửi khi chưa bấm | `INT-TC-04` |
| `INT-AC-05` | Tạo/kết thúc phiên & alarm retry idempotent | Retry `/v1/study/sessions`, `/finish`, `/v1/alarms`, `/events` tái sử dụng đúng `clientSessionId` & `Idempotency-Key` để backend/PostgreSQL không tạo bản ghi trùng | `INT-TC-05` |
| `INT-AC-06` | Phân quyền A/B (`403`) & cách ly đổi tài khoản | Token A nhận `403` khi chạm dữ liệu B; đăng xuất hoặc đổi A → B xóa state AI chat, draft, remote session và đánh dấu `Chưa đồng bộ server` cho B | `INT-TC-06` |
| `INT-AC-07` | Bảo mật secret/token & tách demo local | Không log token/API key/nội dung chat cá nhân; không hardcode secret/UID release; `.gitignore` chặn `.env`; demo/fixture có nhãn phân biệt rõ | `INT-TC-07` |
