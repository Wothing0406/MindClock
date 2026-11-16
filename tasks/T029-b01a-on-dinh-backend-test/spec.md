# Đặc tả nhiệm vụ — T029 (B01a: Ổn định backend test)

## Vấn đề và kết quả mong muốn

Trong phiên `T024`, lệnh `pytest -q` và cả ca đơn lẻ `tests/test_api_v1.py::test_health_and_zero_secret_exposure` bị ghi nhận treo `>90s` trong `TestClient`, khiến trạng thái backend test chưa được xác nhận (`docs/00-start/01-hien-trang.md`, `docs/03-quality/04-moi-truong-chay-thu.md §3`). Đồng thời, `services/api/app/main.py` hiện đang mount vô điều kiện `create_demo_router()` và `create_product_router()`, vi phạm cổng R0 (`docs/00-start/02-lo-trinh.md`: "test route web không mount trong production").

Sau task này:
1. Xác định rõ nguyên nhân gây treo/chậm khi chạy `pytest` (hoặc xác nhận hành vi của SQLite WAL/lifespan/import-time app creation trên Windows) và đảm bảo `pytest -vv` chạy kết thúc nhanh, ổn định cho cả ca health lẫn toàn bộ suite.
2. Không làm hỏng hay ghi đè thay đổi chưa commit của `T022` (`demo_ui.py`) và `T023` (`product_ui.py`, `mobile.html`, `product.css`, `product.js`).
3. Khi `app_env` không thuộc nhóm phát triển/test (`development`, `test`, `local`), ứng dụng FastAPI không mount `/demo` và `/product`, đồng thời không gọi `Base.metadata.create_all()` hay chấp nhận `dev:*` bearer token.

## Phạm vi

- **Trong phạm vi:**
  - Chẩn đoán và ổn định thực thi `pytest` trong `services/api/`.
  - Kiểm soát việc khởi tạo engine/lifespan và mount `demo_router`, `product_router` theo `app_env` trong `services/api/app/main.py` và `services/api/app/db/base.py`.
  - Bổ sung test kiểm chứng cổng bảo mật production (không mount `/demo`, `/product`, từ chối `dev:*` token khi `app_env='production'`) trong `services/api/tests/test_api_v1.py`.
  - Cập nhật `docs/00-start/01-hien-trang.md` và `docs/03-quality/04-moi-truong-chay-thu.md` với bằng chứng chạy thật.
- **Ngoài phạm vi:**
  - Flutter/Android build (thuộc B01b).
  - PostgreSQL migration trên Docker/PostgreSQL thật (thuộc B01c).
  - Thay đổi hợp đồng nghiệp vụ `/v1/*` hiện có.
- **Dữ liệu/role/quyền liên quan:**
  - Bảo mật môi trường `production`: chặn dev token fallback và chặn các route web WIP `/demo`, `/product`.
- **Tài liệu chuẩn:**
  - `AGENTS.md §1, §3, §4`
  - `docs/00-start/01-hien-trang.md`
  - `docs/00-start/02-lo-trinh.md` (R0, B01)
  - `docs/00-start/05-goi-task-dau-tien.md` (B01a)
  - `docs/03-quality/02-van-hanh-phat-hanh.md §2, §3`
  - `docs/03-quality/04-moi-truong-chay-thu.md §3`

## Yêu cầu kiểm chứng được

| ID | Điều kiện | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | Khi chạy `pytest -vv tests/test_api_v1.py::test_health_and_zero_secret_exposure` trong `services/api/` | Test kết thúc nhanh (< 10 giây), trả `200 OK` từ `/v1/health`, không treo và không lộ `gemini_api_key` | TC-01 |
| AC-02 | Khi chạy toàn bộ `pytest -vv` trong `services/api/` | Toàn bộ các test trong `tests/test_api_v1.py` và `tests/test_product_mobile.py` chạy kết thúc ổn định, pass 100%, không vi phạm hợp đồng `/v1` | TC-02 |
| AC-03 | Khi khởi tạo `create_app` với `app_env='production'` | Các route `/demo`, `/demo/bermuda.mp3`, `/product`, `/product/style.css`, `/product/app.js` trả `404`, và `Bearer dev:<uid>` bị từ chối `401 AUTH_EXPIRED` | TC-03 |
| AC-04 | Khi kiểm tra git diff và chạy các script kiểm tra hồ sơ/tài liệu | Các thay đổi WIP của T022/T023 vẫn nguyên vẹn; `check_docs_links.py` và `check_task_records.py` đều pass | TC-04 |

## Hợp đồng và trường hợp biên

- **Hợp đồng API `/v1`:** Giữ nguyên 100% payload, status code, headers và idempotency.
- **Trường hợp biên SQLite trên Windows:** Khi dùng SQLite `:memory:` hoặc file tạm trong `tmp_path`, `PRAGMA journal_mode=WAL` hoặc engine tạo ở module-level (`app = create_app()`) không được giữ file lock hoặc gây treo `TestClient`.
- **Trường hợp biên môi trường `production`:** Chỉ mount `create_demo_router()` và `create_product_router()` khi `cfg.app_env.lower() in {'development', 'test', 'local'}`.

## Quyết định/mâu thuẫn

- Giữ `app = create_app()` hoặc cơ chế tương đương để `uvicorn app.main:app` chạy bình thường theo runbook, nhưng đảm bảo việc import `create_app` trong test và chạy `TestClient` đóng/giải phóng tài nguyên sạch sẽ.
- Bảo vệ toàn bộ thay đổi chưa commit của T022/T023 trong `services/api/app/main.py` bằng cách chỉ bọc điều kiện `if cfg.app_env.lower() in {'development', 'test', 'local'}:` quanh `create_demo_router()` và `create_product_router()`.
