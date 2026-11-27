# Nhật ký thực hiện T088

- `2026-11-27`: Phát hiện GitHub Actions bị khóa billing runner trên tài khoản `Wothing0406` khiến workflow release `v1.0.0` fail trước khi chạy step. Chuyển sang xuất bản GitHub Release trực tiếp kèm file `mindclock-android.apk` + bật thêm mirror `/download` ngay trên `https://api.ieltsoasis.site`.
- `2026-11-27`: Trong lần chạy live Docker đầu tiên, `_resolve_repo_file` đánh `here.parents[3]` gây `IndexError` khi chạy ở `/app/app/main.py` trong container; đã sửa thành `here.parents[:4]` và xác nhận `GET /download` (200) + `HEAD /download/mindclock-android.apk` (200, `70295061` bytes) + full `/v1` live flow trên PostgreSQL 16 hoạt động thông suốt.
