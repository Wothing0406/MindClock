# Bàn giao T024

- **Trạng thái:** `verifying` vì API pytest runtime chưa xong; phần tái cấu trúc và docs đã đạt QA riêng.
- **Đã làm:** xóa `demo/` và `demo_video/`; giữ 228 file game art ở `assets/game/`; sửa 7 script asset; viết docs/56–57, README và chỉ mục/những trang trạng thái đang lỗi thời. Flutter/API và WIP T022/T023 không bị ghi đè.
- **Test:** builder/preview/asset QA, docs links (60 file), task checker, Python compile và diff phạm vi task đạt ngày 15/11/2026. Hai thư mục demo không còn. Xem [tests.md](tests.md).
- **Giới hạn:** `pytest -q` treo >90 giây; test health đơn lẻ cũng treo trong TestClient, đã dừng. `pytest --collect-only` thấy 14 test. Global `git diff --check` lỗi whitespace trong `services/api/app/demo_ui.py` đang được T022 sửa; không thuộc thay đổi T024. Chưa chạy Flutter/Android thật, PostgreSQL/Firebase/AI production. Web `/demo`, `/product` trong API còn lại do WIP; phải tắt/bỏ trước release theo docs/56–57.
- **Rủi ro:** asset game chưa có quyền phát hành thương mại được xác minh. `demo_video/` untracked đã xóa theo yêu cầu và không thể khôi phục bằng Git; bản render không được giữ. File `mp3/` nguồn của T020 vẫn ở gốc vì backend web WIP đang đọc nó.
- **Điểm tiếp tục:** điều tra TestClient/pytest bằng ca `tests/test_api_v1.py::test_health_and_zero_secret_exposure` trong T022/T023 hoặc task backend riêng; sau khi có kết quả, ghi TC-04. Tiếp tục product bằng P0.0 trong docs/56: build/test Flutter trên máy được phép chạy, migration PostgreSQL và CI, rồi AD01–AD09 trên Android thật. Không mở thêm web client.
