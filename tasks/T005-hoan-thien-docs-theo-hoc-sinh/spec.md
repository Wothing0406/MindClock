# Đặc tả T005

## Kết quả mong muốn

Học sinh nhìn vào sản phẩm biết hôm nay cần làm gì, đặt báo thức trong vài bước, có thể làm bài theo cách phù hợp và thoát an toàn, hiểu vì sao kết quả chấm như vậy, không bị ép cạnh tranh. Đội coding có một quyết định hiện hành cho SQL/API/offline/demo và acceptance rõ.

## Phạm vi và giới hạn

- **Trong phạm vi:** cập nhật docs; nguồn chuẩn mới về nhu cầu học sinh và traceability; sửa tài liệu cũ xung đột; ghi rõ API, offline, UI copy, cổng nội dung/AI.
- **Ngoài phạm vi:** app/backend, Figma/sprite thật, quyền tái sử dụng corpus, xác nhận luật/thể lệ cuộc thi, kiểm chứng với học sinh thật.
- **Bảo vệ bắt buộc:** Dừng khẩn cấp local; không tự cấp XP/rank bởi AI; ảnh không lưu mặc định; ranked opt-in; không khẳng định tác động giấc ngủ/học tập chưa đo.

## Acceptance

| ID | Điều kiện | Kết quả docs phải có | Test |
| --- | --- | --- | --- |
| AC-01 | Học sinh dùng app lần đầu/những ngày không đều | nhu cầu, hành trình, nội dung tối thiểu, trường hợp biên và AC UX kiểm được | TC-01 |
| AC-02 | Coding đọc nhiều docs | một nguồn hiện hành cho PostgreSQL, auth, tài khoản, chế độ chuông và D0 demo; tài liệu cũ không chỉ đạo trái chiều | TC-02 |
| AC-03 | Mất mạng/không camera/AI lỗi | quyết định rõ câu/đáp án cache, chấm offline, XP pending, quyền dừng và bản nháp dữ liệu | TC-03 |
| AC-04 | Chấm bài/trận/khiếu nại | ranh giới chấm công tâm, quyền học sinh và cổng ranked với test/ownership | TC-04 |
| AC-05 | Đội chuẩn bị demo 0 đồng | runbook nói đúng live/mock, UI phù hợp luật mới, thiết bị và nhánh dự phòng | TC-05 |
| AC-06 | Đội coding bắt đầu task | tài liệu có quyết định, acceptance, thứ tự P0 và nơi cần reviewer; không tuyên bố đã triển khai | TC-06 |

## Quyết định trước khi sửa

1. Dữ liệu nghiệp vụ dùng PostgreSQL, SQLite chỉ local/demo một máy; Firebase Authentication chỉ danh tính cho tài khoản online, khách local không cần đăng nhập. Không viết nghiệp vụ mới vào Firestore.
2. API tài khoản chuẩn theo `/v1/me`: GET, PATCH, DELETE tạo yêu cầu xóa 202; thêm POST export và GET delete-status. Các tên khác trong docs/24 là cũ.
3. Chế độ thử thách không Hoãn; Dừng khẩn cấp luôn dừng local. Offline không tự kết luận `correct` cho lý do viết tự do; có thể hoàn thành không chấm và chỉ đồng bộ bài khi người học chọn.
4. XP học cá nhân khác RP thi đấu; bảng chỉ từ RP và opt-in. Không dùng giờ dậy/streak để xếp hạng.
5. D0 ưu tiên một luồng học sinh thật/fixture rõ nhãn; không dùng demo HTML cũ như bằng chứng có PvP/AI/báo thức OS.
