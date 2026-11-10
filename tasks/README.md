# Nhật ký nhiệm vụ coding

Mỗi yêu cầu có thay đổi code, cấu hình chạy, dữ liệu, API hoặc giao diện phải có một thư mục `tasks/TNNN-ten-ngan/` tạo **trước khi sửa code**. Số `TNNN` tăng dần; một yêu cầu tiếp diễn dùng lại thư mục cũ. Không tạo task mới cho mỗi lượt chat hoặc mỗi lần sửa lỗi trong cùng mục tiêu. Các file trong `_template/` là mẫu, không phải nhiệm vụ đã hoàn thành.

## Bắt đầu

1. Đọc `AGENTS.md`, `docs/README.md`, tài liệu nguồn đúng phạm vi, rồi đọc task liên quan và code hiện tại.
2. Chọn ID kế tiếp, sao chép `_template/` thành `TNNN-ten-ngan/`. Điền `README.md`, `spec.md`, `plan.md`, `tests.md` **trước khi sửa code**. Nếu là lỗi khẩn cấp, ghi tối thiểu hành vi mong đợi, rủi ro và test tái hiện trước khi sửa; hoàn thiện plan ngay sau khi ổn định.
3. Ghi `source_refs` là file + mục cụ thể. Nếu docs mâu thuẫn, ghi quyết định vào task; sửa docs chuẩn trước/cùng code, không tự chọn theo trí nhớ.
4. Làm từng bước nhỏ; sau mỗi bước cập nhật checkbox `plan.md`, chạy test phù hợp, ghi bằng chứng ở `tests.md`. Nếu thất bại, ghi vòng sửa ở `worklog.md` rồi lặp **tái hiện → xác định nguyên nhân → sửa → kiểm tra lại**.
5. Trước khi xong: chạy cổng test phù hợp rủi ro, rà soát diff, cập nhật docs chuẩn và `handoff.md`. Chỉ đặt trạng thái `done` khi acceptance pass; nếu chưa, đặt `in_progress` hoặc `blocked` với bước tiếp theo cụ thể.

## Trạng thái và quay lại

`planned → in_progress → verifying → done`. Có thể chuyển sang `blocked` khi phụ thuộc ngoài chưa có; từ `blocked` trở lại `in_progress` sau khi điều kiện được giải quyết. Một lỗi mới phát hiện ở task đã `done` tạo **task sửa lỗi mới** và liên kết task gốc, trừ khi còn trong cùng lượt kiểm chứng/chưa bàn giao thì mở lại task hiện tại. Mỗi lần quay lại đọc `README.md`, `handoff.md`, vòng lỗi cuối trong `worklog.md` và phần test chưa đạt trước khi sửa tiếp.

Không dùng trạng thái `done` khi mới chạy mock UI, chưa kiểm tra thiết bị thật cho báo thức, hoặc chỉ có test xanh nhưng chưa đạt acceptance. Không lặp vô hạn: sau 3 vòng sửa cùng một lỗi mà không có tiến bộ, dừng chỉnh mò, ghi giả thuyết, bằng chứng và thay đổi cần quyết định trong `handoff.md`; tiếp tục phần độc lập được.

Chạy `python scripts/check_task_records.py` tại gốc repo trước khi bàn giao/merge. Script kiểm tra cấu trúc hồ sơ; người review vẫn phải đọc bằng chứng test và xác nhận hành vi thật.

## Nguồn chuẩn và độ ưu tiên

Yêu cầu người dùng hiện tại → `AGENTS.md` và quy tắc an toàn → docs sản phẩm/API/kiến trúc/test → `spec.md` của task → code. Task không được lặng lẽ thay đổi quy tắc sản phẩm. Nếu phát hiện docs chuẩn sai hoặc lỗi thời, cập nhật chúng cùng task và ghi rõ ở `handoff.md`.

