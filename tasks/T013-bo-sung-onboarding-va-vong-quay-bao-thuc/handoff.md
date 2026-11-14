# Bàn giao T013

## 1. Phần đã làm

- Cập nhật [docs/54-kiem-ke-va-backlog-frontend.md](../../docs/54-kiem-ke-va-backlog-frontend.md):
  - Bổ sung vào bảng màn hình (`§1.2`) và ba phạm vi (`§2`) luồng đăng ký/đăng nhập đơn giản (`A01–A03` mật khẩu mạnh + xác nhận), onboarding hướng dẫn (`S03a–S03c`: chọn trình độ & môn học → tải/nhập TKB có sẵn qua màn xác nhận `Lưu lịch` → chọn 1/6 avatar mặc định), giữ nguyên đường `Dùng thử không cần tài khoản`.
  - Bổ sung vào `S04`/`S06`, `§3.1` (`SleepWakeDial`, `AlarmSoundPicker`, `StrongPasswordField`, `AvatarGridPicker`, `TimetableImportPreview`), `§3.2` (slot `assets/audio/alarm_custom.*` chờ file âm thanh của chủ dự án) và `§4` (`FE-S01`, `FE-S02`, `FE-S03`, `FE-S05`) phần vòng quay 24h Ngủ–Dậy (`22:30 → 05:30`, stepper TalkBack, nút `Thêm báo thức tùy chọn giờ`) cùng báo thức Android full-screen (`USE_FULL_SCREEN_INTENT`, fallback notification, âm thanh khích lệ).
  - Thêm 4 mâu thuẫn/điểm chốt mới (#10–#13) trong `§5.1` và cập nhật danh sách quyết định trước `FE-S01/FE-S02` trong `§5.2`.
- Cập nhật [docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md](../../docs/55-chot-ngon-tu-thiet-ke-va-icon-frontend.md): bổ sung bộ chuỗi `vi-VN` và danh mục icon/`semanticLabel` cho đăng ký mật khẩu mạnh, tải TKB có sẵn, vòng quay 24h (loại bỏ ngôn từ Apple Health/chẩn đoán ngủ) và chọn âm thanh chuông.
- Kiểm tra `/find-skills` đối chiếu `.agents/skills/` hiện có và `search_marketplace` (không tự ý cài plugin).

## 2. Kết quả kiểm tra

- Chạy kiểm tra liên kết tài liệu, hồ sơ task và whitespace: `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `git diff --check` (xem chi tiết lệnh/output tại `tests.md`).
- **Chưa kiểm UI responsive/Android thật:** task này là nhiệm vụ kiểm kê & lập backlog (`chưa sửa code`); chưa có app Flutter, mã Kotlin hay `flutter`/`adb` trên máy.

## 3. Rủi ro & Giới hạn còn lại

1. **Tài khoản `tên` vs `Email` Firebase Auth:** cần chủ dự án xác nhận dùng form `Biệt danh + Email + Mật khẩu mạnh` theo `docs/24` hay bổ sung cơ chế `username`.
2. **Định dạng TKB tải sẵn:** cần chốt ở `S03b` cho phép file cấu trúc offline (`JSON/CSV` mẫu) hay chụp ảnh qua `POST /v1/timetable/parse-preview` (P1/M2).
3. **Âm thanh báo thức Android:** chủ dự án chưa gửi file âm thanh (`assets/audio/alarm_custom.*`); khi nhận được cần rà bản quyền, định dạng (`ogg/mp3/wav`) và kiểm âm thực tế trên loa máy Android thật cùng `USE_FULL_SCREEN_INTENT` ở Android 14+.
4. **Thư viện icon & môi trường Flutter/Android:** cần chốt `Lucide SVG` vs `Material Symbols Rounded` (`docs/55 §5.1`) và cài `Flutter SDK` + `Android SDK` trước khi code `FE-S01`.

## 4. Điểm tiếp tục cụ thể

- Nhận file âm thanh báo thức từ chủ dự án và xác nhận 4 quyết định mở trong `docs/54 §5.2 (mục 1)`, chọn plugin cài từ Marketplace nếu muốn dùng (`Dart and Flutter`, `Android CLI`), rồi mở `T014` để bắt đầu code lát cắt `FE-S01` / `FE-S02`.
