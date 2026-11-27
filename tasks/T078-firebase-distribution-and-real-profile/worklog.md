# Nhật ký xử lý lỗi T078

- **27/11/2026 (Vòng 1):** Kiểm tra `npx -y firebase-tools@latest login:list` cho kết quả `! No authorized accounts, run "firebase login"`. Phát hiện lỗi lệch mã môn (`TOAN` ở server vs `math` ở Flutter `SubjectCatalog`), thiếu `GET /v1/timetable` ở repository Flutter, và `MeGuestScreen` + `TimetableProfileScreen` chưa hiển thị/cho sửa đủ thông tin Hồ sơ cá nhân.
- **27/11/2026 (Vòng 2):** Chạy `t078_real_profile_and_sync_test.dart` phát hiện `Row` trong `TimetableProfileScreen:369` bị tràn `14px` ở màn `320dp` chữ `200%` -> đổi sang `Wrap` và chạy lại pass 3/3.
