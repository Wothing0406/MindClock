# Worklog

## 21/11/2026

- Audit xác nhận chưa có runtime group/pet; T043 chỉ là docs.
- Người dùng đổi yêu cầu từ một nhóm sang nhiều nhóm. Chốt MVP tối đa 3 nhóm active/user và cập nhật spec/test trước khi tiếp tục.
- Thêm migration `0005`, service/API cho create/invite/accept/request/approve/kick/leave/delete và cleanup account.
- Thêm ledger care/EXP server: study ≥ 300 giây +10, morning correct +20; chiếu vào từng nhóm active và chống trùng theo group/source.
- Thêm Flutter contract/repository, UI trong tab Tôi, đổi giữa pet, owner actions, 320dp/200%/Reduce Motion và golden cấu trúc.
- Lần test đầu treo vì môi trường chặn socket localhost của TestClient/Flutter, không phải deadlock DB. Chạy lại với quyền localhost: API/Flutter đạt.
- Test API đầu có một assert alias fixture quá chặt; sửa kiểm tiền tố `Học sinh`, chạy lại đạt.
- PostgreSQL test ban đầu skip do thiếu biến admin URL; lấy URL từ `.env` mà không ghi secret vào task, tạo DB UUID, migration/concurrency đạt và fixture tự xóa DB.
- Không làm chat/media/share/dashboard/PvP trong T074; tách thành task sau ở roadmap.
