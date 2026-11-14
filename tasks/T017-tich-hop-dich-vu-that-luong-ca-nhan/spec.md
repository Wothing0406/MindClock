# Đặc tả T017 — Dịch vụ thật cho luồng cá nhân & tách Debug Fixture

## 1. Nguồn chuẩn & Dependency Backend

- **Kết quả kiểm tra backend thật (14/11/2026):** chưa có `services/api/` trong repo. Client **không tự bịa endpoint** ngoài bảng hợp đồng `/v1` trong `docs/07 §2`, và mọi phụ thuộc backend được ghi ở [T016](../T016-backend-fastapi-postgres-luong-ca-nhan/README.md).
- **Endpoint `/v1` sử dụng theo `docs/07 §2`:**
  - `GET /v1/health`
  - `GET /v1/me`, `PATCH /v1/me`, `DELETE /v1/me`, `GET /v1/me/delete-status`
  - `GET /v1/alarms`, `POST /v1/alarms`, `PATCH /v1/alarms/{id}`, `DELETE /v1/alarms/{id}`
  - `GET /v1/timetable`, `PUT /v1/timetable`, `POST /v1/alarms/wake-suggestions`
  - `GET /v1/challenges/next?date=YYYY-MM-DD`
  - `POST /v1/sessions`, `POST /v1/sessions/{id}/events`, `POST /v1/sessions/{id}/answers`, `POST /v1/sessions/{id}/attempts`, `POST /v1/sessions/{id}/feedback`
  - `GET /v1/progress/summary`, `GET /v1/sessions?limit=&cursor=`

## 2. Acceptance Criteria (AC)

| ID | Tiêu chí nghiệm thu | Tài liệu nguồn |
| --- | --- | --- |
| `PF-AC-01` | **Auth online & hết hạn token không phá báo thức:** hỗ trợ đăng nhập/đăng ký/đăng xuất; khi HTTP trả `401`, thử refresh ID token đúng 1 lần; nếu hết hạn hẳn thì chuyển trạng thái yêu cầu đăng nhập lại và **giữ nguyên 100% báo thức local + Dừng khẩn cấp**. | `docs/07 §1,§8`, `docs/18 §2`, `docs/24 §§1,3,4` |
| `PF-AC-02` | **Tách repository thật & fixture debug:** `RemotePersonalFlowRepository` gọi HTTP `/v1` thật; `DebugFixturePersonalFlowRepository` đặt trong `lib/data/debug/`, bắt buộc gắn cờ `isDebugFixture = true` và UI hiển thị nhãn rõ `Fixture debug · Không phải AI/XP thật`. | `docs/18 §1,§4` |
| `PF-AC-03` | **Nối question/session/attempt/progress đúng hợp đồng:** tải câu không kèm đáp án/rubric, tạo session idempotent, nộp bài chữ (`/answers`) gồm đáp án + trình bày ngắn hoặc ảnh (`/attempts`), chỉ hiện gợi ý từ lần `incorrect` thứ 3 ở chế độ thử thách (`uncertain` không tăng lượt sai), báo chấm sai (`/feedback`), xem tiến độ riêng tư (`/progress/summary`). | `docs/07 §§2,3,5,6`, `docs/31`, `docs/39 §§1–3` |
| `PF-AC-04` | **Idempotency key khi retry:** mỗi lượt nộp giữ cố định `clientAttemptId` và `Idempotency-Key` UUID qua các lần retry do mạng/timeout; khi user sửa nội dung mới sinh cặp key mới; `409` đồng bộ lại state thay vì tạo điểm trùng. | `docs/07 §1`, `docs/18 §2` |
| `PF-AC-05` | **XP chỉ hiện từ phản hồi server hợp lệ:** UI chỉ hiển thị XP từ `xpAwarded` / `GET /v1/progress/summary` khi đang dùng dịch vụ thật + đăng nhập; offline/khách/fixture không tự cộng XP. | `docs/06`, `docs/07 §8`, `docs/17 §4` |
| `PF-AC-06` | **Camera xin quyền đúng lúc & xác nhận trước upload:** chỉ gọi xin quyền `CAMERA` khi người dùng bấm chụp bài; bắt buộc qua màn xem lại + thông báo quyền riêng tư + xác nhận trước `POST /attempts`; **không lưu ảnh mặc định xuống máy, không xếp ảnh chờ tải ngầm**. | `docs/07 §8`, `docs/17 §4`, `docs/25 §§2,4` |
| `PF-AC-07` | **Offline an toàn & bản nháp chữ tự chọn 24h:** mất mạng/timeout 15s không tự chấm đúng/sai mà hiển thị `Chưa thể chấm`; người dùng tự chọn `Lưu trên máy để gửi sau` (chỉ chữ, TTL 24 giờ, gắn `ownerKey`); chỉ upload sau khi user xác nhận `Gửi bài này để nhận nhận xét?`. | `docs/07 §8`, `docs/17 §3`, `docs/25 §3` |
| `PF-AC-08` | **Cô lập tài khoản A/B trên cùng máy:** đăng xuất hoặc đổi tài khoản xóa/ẩn sạch cache tiến độ, lịch sử, phiên và bản nháp chữ của tài khoản trước; báo thức local vẫn giữ theo chủ máy mà không lộ lịch sử học hay email người trước. | `docs/24 §4`, `docs/25 §1,§5` |
| `PF-AC-09` | **Integration test hiện hành:** viết `app/integration_test/personal_flow_e2e_test.dart` dùng `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, **không** bật `enableFlutterDriverExtension()` hay `flutter_driver`. | `docs/16 §1`, `docs.flutter.dev/testing/integration-tests` |
