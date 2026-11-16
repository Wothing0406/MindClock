# Kế hoạch và kết quả kiểm thử — T029 (B01a)

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Chạy đơn lẻ `test_health_and_zero_secret_exposure` | Kết thúc < 10s, `1 passed`, không lộ secret | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_api_v1.py -k test_health_and_zero_secret_exposure` trên Windows Python 3.11.0rc2 | Pass (`1 passed in 3.81s`, 16/11/2026) |
| TC-02 | AC-02 | Chạy toàn bộ test suite trong `services/api/tests/` | Tất cả ca trong `test_api_v1.py` và `test_product_mobile.py` đều `passed` ổn định | `services/api/.venv/Scripts/python.exe -m pytest -vv --durations=20` trên Windows Python 3.11.0rc2 | Pass (`15 passed in 9.01s`, 16/11/2026) |
| TC-03 | AC-03 | Khởi tạo `create_app` với `app_env='production'`, gọi `/demo`, `/product` và `/v1/me` kèm `Bearer dev:spoof_user` | `/demo` và `/product` trả `404`; `/v1/me` trả `401 AUTH_EXPIRED`; `/v1/health` trả `200` không lộ secret | `services/api/.venv/Scripts/python.exe -m pytest -vv tests/test_api_v1.py -k test_production_env` trên Windows Python 3.11.0rc2 | Pass (`0.22s call`, 16/11/2026) |
| TC-04 | AC-04 | Kiểm tra liên kết tài liệu và cấu trúc task records | Cả 2 script trả exit code 0 | `python scripts/check_docs_links.py` và `python scripts/check_task_records.py` tại gốc repo | Pass (`Docs links OK (338 markdown files)` & `Task records OK`, 16/11/2026) |

## Cổng theo rủi ro

- Auth/dữ liệu: token `dev:*` bị từ chối khi `app_env='production'`, user A/B isolation và idempotency trong `test_api_v1.py` pass.
- Vận hành/release: `/demo` và `/product` không mount khi `app_env='production'`.
