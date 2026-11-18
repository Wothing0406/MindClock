# Đặc tả T051 — Đồng bộ hồ sơ/TKB/consent, Xóa tài khoản & Ngân hàng câu THPT 10–12

## Yêu cầu kiểm chứng được

| ID | Liên kết | Hành vi hệ thống phải làm | Bằng chứng/test |
| --- | --- | --- | --- |
| AC-01 | B5, ON-04 | `seed.py` có đủ câu `published` (`approved_bank`) cho Lớp 10, Lớp 11, Lớp 12 (`TOAN`, `TIENG_ANH`, `SINH_HOC`); gọi `GET /v1/challenges/next` với tài khoản Lớp 10/11/12 trả đúng câu khớp khối lớp và môn | TC-01 |
| AC-02 | Privacy, ON-06 | `DELETE /v1/me` xóa sạch cả dữ liệu PvP (`MatchQueue`, `RoundAction`, `RoundSubmission`, `MatchPlayer`) cùng dữ liệu cá nhân khác mà không lỗi FK trên PostgreSQL 16 | TC-02 |
| AC-03 | B7, ON-05 | `RemotePersonalFlowRepository` + `PersonalFlowViewModel` gửi đúng `PATCH /v1/me`, `POST /v1/me/consent`, `PUT /v1/timetable`, `DELETE /v1/me`; khi offline/lỗi mạng, lưu local và báo thức vẫn an toàn | TC-03 |
| AC-04 | Timetable bug | `TimetableProfileScreen._saveProfileChanges()` giữ nguyên `alias`, `avatarId`, `selfAssessments`, `confirmedPlan` của hồ sơ; `_applyAiDraftTimetable()` thông báo rõ giờ báo thức cũ vẫn giữ nguyên | TC-04 |
| AC-05 | ON-06, Privacy | Trên `MeGuestScreen`, tài khoản đã đăng nhập thấy nút `Xóa tài khoản & dữ liệu trực tuyến`, cần xác nhận 2 bước, xóa xong đăng xuất về màn Chào mừng, dọn sạch hồ sơ/TKB scoped của tài khoản đó nhưng giữ nguyên báo thức local trên máy | TC-05 |
