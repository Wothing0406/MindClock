# Nhật ký thực hiện và vòng sửa

| Vòng/ngày | Bước và bằng chứng | Giả thuyết nguyên nhân | Thay đổi | Test chạy lại | Kết luận/bước tiếp |
| --- | --- | --- | --- | --- | --- |
| 1 / 21-11-2026 | Audit route/UI/test: không có kick/delete; mic/cam bị khóa vì `mediaAvailable=false`; pet chỉ có asset | Các task trước cố ý giới hạn ở REST metadata | Mở T073, tách backlog T074–T084 | Chưa chạy | Viết test đỏ và triển khai lifecycle |
| 2 / 21-11-2026 | Flutter runner trong môi trường giới hạn không nối được localhost; pytest ban đầu im lặng | Test runner cần socket localhost/process ngoài giới hạn | Chạy lại đúng quyền, không đổi code để né test | Flutter 13 PASS; API SQLite 3 PASS | Hạ tầng test ổn |
| 3 / 21-11-2026 | Test mới đọc lỗi theo `detail.error`, contract thật trả `error` | Kỳ vọng test sai format middleware chuẩn | Sửa assertion theo API contract | SQLite PASS; PostgreSQL 3/3 PASS | Lifecycle và cascade đạt |
