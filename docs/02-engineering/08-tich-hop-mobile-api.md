# Tích hợp Flutter ↔ FastAPI theo lát cắt

**Đích:** một repository/gateway có contract rõ cho mỗi luồng, không dựng UI web thay. [API](04-hop-dong-api.md), [architecture](01-kien-truc.md), [runbook](../03-quality/04-moi-truong-chay-thu.md). Hiện Flutter có `PersonalApiClient`, `RemotePersonalFlowRepository`, `RemoteAlarmSyncGateway`, `RemoteStudyAiGateway`; API có `/v1`, nhưng cổng end-to-end chưa được xác nhận trên Android thật/PostgreSQL.

## 1. Trật tự gọi trong từng luồng

| Luồng | Trình tự trên thiết bị | Trình tự server | Khi lỗi |
| --- | --- | --- | --- |
| Lưu alarm | Lưu local → gọi Kotlin schedule → hiển thị OS state → sync config nếu đã Auth | Validate owner/revision, lưu config | API lỗi không hủy local; OS lỗi không báo `Đã sẵn sàng`; retry sync sau. |
| Reo/Dừng | Android Service phát/dừng ngay → ghi event local → UI/câu | Chỉ nhận metadata sau; không là nguồn chuông | Mất mạng vẫn dừng; event retry key ổn định, không phát lại. |
| Tải câu | Cache published revision phù hợp TKB trước giờ reo → chọn local | `/challenges/next` chỉ trả prompt/metadata | Không có câu → `Ôn sau`, không khóa chuông. |
| Nộp chữ/ảnh | User xác nhận → tạo `clientAttemptId` → giữ UI loading/draft → gọi API | Auth/owner/rubric/validator/AI/transaction | 401 hướng đăng nhập, 409 sync conflict, 429/503/504 uncertain/retry; không tự cấp XP. |
| Không gian học | Timer local start/finish không chờ mạng; AI chỉ khi hỏi | `/study/sessions`, `/finish`, `/help` idempotent/limit | Offline vẫn học/kết thúc; không lưu ảnh/video mặc định. |

## 2. Auth, môi trường, secret

`MINDCLOCK_API_BASE_URL`/Firebase client config qua `--dart-define-from-file=app/.env` trong debug, không commit `.env`; Gemini key chỉ `services/api/.env` server. API production bắt buộc HTTPS, Firebase ID token hợp lệ, local dev bearer fallback **false**. Thiết bị thật qua LAN hoặc `adb reverse` ở dev, không hardcode `10.0.2.2` vào release. Sau login, token refresh trước request; 401 không xóa alarm local, nhưng không hiển thị dữ liệu account cũ trên máy dùng chung.

## 3. Contract và đồng bộ

Mỗi endpoint Flutter gọi có test loopback/contract đối chiếu Pydantic response/error thật, enum/field optional/revision. Cùng `Idempotency-Key` qua retry; `localSessionId`/`clientAttemptId` tạo một lần và giữ ổn định. Queue chỉ metadata sự kiện đủ điều kiện (TTL 7 ngày); nháp chữ lưu tối đa 24h khi người dùng chọn và xác nhận lại trước gửi; ảnh không queue. Khi timetable/conflict revision, hiển thị hai bản và để user chọn, không tự đổi alarm OS. Không bao giờ suy API alarm đã lưu = OS đã schedule.

## 4. Test dọc tối thiểu

Từ app khách đặt alarm offline → OS xác nhận → reo/khóa màn → Dừng; từ app đăng nhập tạo/sync TKB → tải câu published → nộp chữ → correct/incorrect/uncertain → XP ledger một lần; tắt mạng giữa nộp/retry; hai account A/B; token hết hạn; camera từ chối; API timeout; logout/đổi account; xóa dữ liệu. Chạy trên Android thật + FastAPI/PostgreSQL test, ghi build/DB/schema version và request ID không lộ bài. [Acceptance cases](../03-quality/05-ca-nghiem-thu.md).
