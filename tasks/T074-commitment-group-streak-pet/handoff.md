# Handoff

- **Trạng thái:** `done` — code/test/push và remote SHA đã xác minh.
- **Đã làm:** migration/model/service/API nhóm kín; tối đa 3 nhóm/user và 4 thành viên/group; owner invite/approve/kick/delete; member leave; cleanup account; study/morning care + EXP idempotent; Flutter repository/model/UI pet đa nhóm; docs kỹ thuật và roadmap tách task.
- **Test 21/11/2026:** API SQLite 7 pass; PostgreSQL disposable 1 pass; Flutter 4 pass; analyzer 0 lỗi; docs 661 link pass; task records OK.
- **Bằng chứng UI:** `app/test/goldens/t074_commitment_group_pet.png` là golden cấu trúc 390×844; chưa thay ảnh máy Android thật.
- **Ngoài phạm vi:** dashboard/share T075; QR/phòng chờ/lịch hẹn T076; chat `@MindClock` T077; audio/camera T078/T079; todo/Doze T080; game T083–T085.
- **Rủi ro:** chưa pilot Firebase A/B/máy Android thật; không stage WIP game/Firebase/web ngoài task.
- **Git:** source commit `acb76d802efe3c852714934d6bf211ebe2b0ed7c` trên `main`, `ls-remote` trùng SHA; commit kế tiếp chỉ cập nhật metadata bàn giao.
- **Điểm tiếp tục:** rà staged diff đúng T074, commit/push, rồi mở T075 bằng task folder mới.
