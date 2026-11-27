# Đặc tả nhiệm vụ T094

## Vấn đề và kết quả mong muốn

Hiện tại bảng `study_rooms` và `study_room_members` chưa lưu `expires_at`, `last_heartbeat_at`, `closed_at` hay bảng lời mời có hạn (`study_room_invites`). Phòng chỉ có chuỗi `active`/`ended`, chưa phân biệt `waiting -> active -> closing -> closed | expired`, chưa có cơ chế heartbeat phát hiện chủ phòng mất mạng để chuyển chủ cho thành viên còn lại, chưa tự dọn phòng rỗng/quá hạn TTL và chưa có link/QR mời opaque có hạn & thu hồi được. Ngoài ra khi mở lại ứng dụng từ nền, `MindClockShellScreen` cần xác minh phòng còn mở để không bao giờ giữ người dùng trong phòng đã đóng.

## Phạm vi

- **Trong phạm vi:** Migration PostgreSQL `0011`, SQLAlchemy models, `CommunityService`, REST endpoints `/v1/study-rooms/*`, tài liệu `docs/02-engineering/09-phong-hoc-realtime.md`, Flutter `CommunityRepository` / `StudyRoomSessionViewModel` / `MindClockShellScreen`, và bộ kiểm thử PostgreSQL 16 + Flutter.
- **Ngoài phạm vi:** Truyền tải luồng âm thanh/video WebRTC/SFU thời gian thực.
- **Tài liệu chuẩn:** `AGENTS.md §3`, `docs/02-engineering/09-phong-hoc-realtime.md`, `docs/01-product/08-phong-hoc-ai-va-ban-be.md`.

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Tạo phòng và có thành viên vào/rời | Phòng lưu đủ `roomId`, `ownerUserId`, `maxMembers`, `visibility`, `createdAt`, `expiresAt`, `lastHeartbeatAt`; chuyển trạng thái chuẩn `waiting` (1 người chờ bạn) -> `active` (>=2 người) -> `closing -> closed | expired`; phòng đang hoạt động hợp lệ không bị xóa/đóng sớm. | TC-01 |
| AC-02 | Nhiều người cùng rời / Chủ phòng rời hoặc mất mạng / Heartbeat hết hạn | Nhiều người rời đồng thời cập nhật đúng membership & presence (`left_at`, tắt mic/cam) không race condition; chủ phòng mất mạng (heartbeat quá hạn) tự chuyển chủ cho thành viên active vào sớm nhất; chủ phòng chủ động rời có thể đóng phòng (mặc định hợp đồng cũ) hoặc chuyển chủ (`transferHost=true`); toàn bộ thành viên hết hạn heartbeat hoặc quá TTL phòng chuyển sang `expired` và không xóa dữ liệu lịch sử cá nhân khác. | TC-02, TC-03 |
| AC-03 | Phòng đầy hoặc dùng link/QR mời | Phòng đủ `maxMembers` trả `409 ROOM_FULL`; link/QR mời dùng opaque token (hash SHA-256 trên DB, không chứa PII), kiểm tra hạn (`410 INVITE_EXPIRED`) và thu hồi (`410 INVITE_REVOKED`) mà không đuổi thành viên đã vào hợp lệ. | TC-04 |
| AC-04 | Đóng phòng hoặc mở lại ứng dụng trên client | Client gửi heartbeat khi đang mở phòng, xóa ngay state phòng khi `closed | expired` hoặc lỗi `401/403/404`, giữ nguyên đồng hồ học cá nhân; mở lại app không tự đưa người dùng vào phòng đã đóng. | TC-05 |

## Quyết định/mâu thuẫn

- Giữ nguyên hành vi tương thích hợp đồng `T069`/`T073`: khi chủ phòng chủ động gọi `POST /v1/study-rooms/{id}/leave` không kèm `transferHost=true` (hoặc gọi `/close`), phòng chuyển `closing -> closed` để các test hiện hữu (`test_room_settings.py`, `test_community_capacity_postgres.py`) không gãy; khi truyền `transferHost=true` hoặc khi chủ phòng **mất mạng (heartbeat hết hạn)** mà vẫn còn thành viên active hợp lệ, server tự động chuyển quyền `host` sang thành viên active vào sớm nhất (`joined_at ASC`).
