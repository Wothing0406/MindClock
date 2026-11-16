# Nhật ký thực hiện và vòng sửa — T029 (B01a)

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 2026-11-16 | Chạy `pytest -vv` cho `test_health_and_zero_secret_exposure` và toàn bộ suite trên `.venv` | `build_engine` trong `services/api/app/db/base.py` bật `PRAGMA journal_mode=WAL` trên mọi kết nối SQLite kể cả `:memory:` và file tạm `tmp_path` khi test trên Windows, dễ gây khóa/chậm file `.db-shm`/`.db-wal`; ngoài ra `main.py` đang mount `/demo` và `/product` cả ở `production` | Sửa `services/api/app/db/base.py` đặt `timeout=10`, `PRAGMA busy_timeout=5000`, tắt `WAL` khi `app_env == 'test'` hoặc `:memory:`; sửa `services/api/app/main.py` chỉ mount `/demo` và `/product` khi `app_env` thuộc `{'development', 'test', 'local'}`; thêm `test_production_env_disables_web_routes_and_dev_token_fallback` | `15 passed in 9.01s` | Đạt toàn bộ AC của B01a, chuyển sang B01b |
