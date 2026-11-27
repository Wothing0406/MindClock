# Kế hoạch thực hiện T095

## Điểm bắt đầu

- Nhánh `main` tại `1668df1` (sau khi hoàn tất `T091`–`T094`).

## Các bước nhỏ

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T095-*` và rà soát toàn bộ chuỗi chữ kỹ thuật + luồng báo thức | Xác định đầy đủ mọi vị trí chữ thừa và điểm cộng trùng báo thức trong ngày | [x] |
| 2 | Mở chọn `Hẹn giờ thường` vs `Báo thức dậy học` trên `AlarmConfigScreen`, cập nhật `AlarmRingScreen`, `MindClockShellScreen`, `GuestWorkspaceViewModel`, `TodayScreen` và `routes/v1.py` cho quy tắc tối đa 1 báo thức hoàn thành/ngày | Chọn Hẹn giờ thường lưu `AlarmMode.normal`; chuông thứ 2+ trong ngày không tính hoàn thành lần 2 hay cộng EXP trùng | [x] |
| 3 | Quét sạch chữ `local`, `cục bộ`, `máy chủ`, `server`, `GDPT 2018`, `chuẩn quy tắc` trên toàn bộ UI Flutter & thông báo API liên quan; bỏ chế độ khách không đăng nhập; rút gọn chat AI còn 1 ô nhập; cập nhật `docs/01-product/09-giac-ngu-va-bao-thuc.md` | Giao diện gọn, sạch, tự nhiên; các test cũ được đồng bộ câu chữ | [x] |
| 4 | Sửa `scripts/build_release_apk.ps1`, chạy `pytest` (PostgreSQL 16), `flutter analyze`, `flutter test`, build `dist/apk/mindclock-android.apk` + `product/`, rebuild Docker API và commit/push `T095` | Tất cả test xanh (`24/24` pytest, `200/200` Flutter), có file `dist/apk/mindclock-android.apk` & `product/mindclock-android.apk` (`67.2 MB`), push sạch lên `origin/main` | [x] |

## Rủi ro và đường lui

- Các khóa `ValueKey` phục vụ kiểm thử (`ring-open-question`, `ring-emergency-stop`, `ring-snooze-5m`, `alarm-auto-challenge-card`, `save-alarm-config`) được giữ nguyên đúng ngữ cảnh chế độ để không phá vỡ kiểm thử hợp đồng.
