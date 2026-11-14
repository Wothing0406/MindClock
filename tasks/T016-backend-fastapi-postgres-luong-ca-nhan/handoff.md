# Bàn giao T016

## 1. Tình trạng hiện tại

- Hồ sơ `T016` mới ở trạng thái `planned`, đóng vai trò hợp đồng và dependency backend bắt buộc trước khi xác minh end-to-end thật với `T017`.

## 2. Hợp đồng giao tiếp giữ đồng bộ với `T017`

- Mọi endpoint thuộc `docs/07 §2` dưới prefix `/v1`.
- Error envelope thống nhất: `{"error":{"code","message","requestId","retryable"}}`.
- Header bắt buộc ở các POST ghi nghiệp vụ: `Idempotency-Key` (UUID v4) + `Authorization: Bearer <Firebase ID token>`.
- Không trả `answerSpec`/`rubric` trong `GET /v1/challenges/next`.

## 3. Điểm tiếp tục chính xác

1. Khởi tạo `services/api/` theo cấu trúc `docs/28 §3` và viết migration PostgreSQL đầu tiên theo `docs/28 §4` & `docs/39 §4`.
2. Cài bộ test `BE-TC-01..BE-TC-07` chạy trên PostgreSQL thật, sau đó mở khóa tích hợp staging cho `T017`.
