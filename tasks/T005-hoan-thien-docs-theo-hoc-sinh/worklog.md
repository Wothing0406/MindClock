# Worklog T005

## 11–12/11/2026 — Rà soát và sửa tài liệu

- Tái hiện: PRD/UX/API/workflow cũ yêu cầu đăng nhập hoặc chụp ảnh để đi qua chuông, nêu Hoãn ở mode thử thách, cấp điểm từ metadata offline, hoặc dùng Firestore trong khi docs/28 đã chốt SQL. Một số trang đấu trường nói luật một câu/ELO cũ; hướng dẫn task 30% dùng ID trùng T005 docs.
- Nguyên nhân: các tài liệu được mở rộng qua nhiều vòng nhưng trang nguồn và trang phụ chưa cập nhật cùng một lần.
- Quyết định: docs/41 định nghĩa nhu cầu U01–U10, docs/42 ánh xạ sang test/task; PostgreSQL là nguồn nghiệp vụ, Firebase Auth chỉ cho online; chuông/Dừng local; bài offline không giả chấm; XP server; giao hữu trước ranked. Viết lại docs/06,17,18,19,21 và sửa các trang liên quan.
- Vòng kiểm tra: `rg` tìm Firestore/Hoãn/nhân vật/số lượt gợi ý; phát hiện nút Dừng còn yêu cầu giữ 2 giây, hint lộ qua `firstIssue`, trang vận hành còn Firestore và docs/29 gợi ID T005. Đã sửa theo cùng quy tắc hiện hành.
- Kiểm tra đã chạy: `git diff --check` pass; kiểm tra liên kết local sau khi đủ hồ sơ 50 file, 0 link thiếu; `python -X utf8 scripts/check_task_records.py` ban đầu báo thiếu worklog/handoff, đã tạo hai file và chạy lại ở `tests.md`. Không chạy app/device/AI/pilot vì task chỉ sửa docs.

## Rủi ro chưa được giải quyết bằng docs

- Chưa có kết quả thử thật với học sinh, người duyệt chuyên môn từng câu, quyền sử dụng corpus ngoài hoặc xác nhận quy chế cuộc thi.
- Chưa có app Android/iOS/backend đang chạy; `demo/index.html` là prototype UI có nhãn mô phỏng và nút gợi ý cũ, không phải bằng chứng luật alarm/chấm AI.
