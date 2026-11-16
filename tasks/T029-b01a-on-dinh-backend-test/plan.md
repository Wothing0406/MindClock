# Kế hoạch thực hiện — T029 (B01a)

## Điểm bắt đầu

- Code hiện tại: `services/api/app/main.py`, `services/api/app/db/base.py`, `services/api/tests/test_api_v1.py`, `services/api/tests/test_product_mobile.py`.
- Hiện trạng: Trong `T024`, `pytest` bị ghi nhận treo khi chạy `TestClient`. Ngoài ra, `/demo` và `/product` đang được mount không phân biệt `app_env`.
- Môi trường: Windows, Python 3.11 + `services/api/.venv`.

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Chạy thử `pytest` trên `services/api/.venv` với ca `test_health_and_zero_secret_exposure` và toàn suite để đo thời gian và xác định nguyên nhân treo (nếu còn) | Có log thực tế và nguyên nhân rõ ràng | [x] |
| 2 | Sửa `services/api/app/main.py` và `services/api/app/db/base.py` để chỉ mount `/demo`, `/product` ở `development`/`test`/`local` và tắt SQLite WAL trên in-memory/test DB kèm `busy_timeout=5000` | Code sạch, không phá WIP T022/T023 | [x] |
| 3 | Bổ sung test `test_production_env_disables_web_routes_and_dev_token_fallback` trong `services/api/tests/test_api_v1.py` | Test mới chạy pass | [x] |
| 4 | Cập nhật `docs/00-start/01-hien-trang.md`, `docs/03-quality/04-moi-truong-chay-thu.md`, chạy `check_docs_links.py`, `check_task_records.py` và điền `handoff.md` | Tất cả test và script kiểm tra pass | [x] |

## Rủi ro và đường lui

- **Rủi ro:** Đụng vào các dòng đang sửa dở của T023 trong `services/api/app/main.py`.
- **Đường lui:** Giữ nguyên import `create_product_router` của T023, chỉ đặt `app.include_router(create_demo_router())` và `app.include_router(create_product_router())` vào khối `if cfg.app_env.lower() in {'development', 'test', 'local'}:`.
