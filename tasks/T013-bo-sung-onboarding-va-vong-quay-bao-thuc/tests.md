# Kế hoạch và kết quả kiểm thử T013

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Kiểm tra bảng màn hình & backlog `docs/54` cho luồng Đăng ký/Đăng nhập → Trình độ/Môn → Tải TKB → Chọn avatar | Đủ điểm vào/ra, local/API, validation mật khẩu mạnh, duyệt nháp TKB và vẫn giữ `Khách local` | Đối chiếu trực tiếp `docs/54` với `docs/05, 24, 32, 52` | Đạt (tài liệu, 2026-11-14): đủ `A01–A03`, `S03a–S03c`, `S05` nháp `Lưu lịch`, vẫn giữ `Dùng thử không cần tài khoản` |
| TC-02 | AC-02 | Đối chiếu `SleepWakeDial` 24h với ảnh `media_1794620679858_7b86f075.jpg` và quy tắc `docs/04, 32, 41, 55` | Có 2 tay nắm ngủ/dậy qua nửa đêm, nhập số cho TalkBack, nút thêm chuông lẻ, không chẩn đoán y khoa | Đối chiếu trực tiếp `docs/54` & `docs/55` với ảnh mẫu | Đạt (tài liệu, 2026-11-14): có `SleepWakeDial` trong `S04/S06`, `AC-S02-1`, stepper `+/-`, nút `Thêm báo thức tùy chọn giờ`, không dùng chữ Apple Health hay chẩn đoán ngủ |
| TC-03 | AC-03 | Kiểm tra spec `S07` full-screen Android + âm thanh tùy chỉnh | Nêu rõ `USE_FULL_SCREEN_INTENT` + fallback notification, kiểm âm an toàn, `Dừng khẩn cấp` không phụ thuộc mạng | Đối chiếu `docs/54` với `docs/31, 47` & `mindclock-android-native` | Đạt (tài liệu, 2026-11-14): đã ghi `AC-S02-2,3,6` và slot `assets/audio/alarm_custom.*` (test chạy audio/APK Android thật thuộc task code `FE-S02`) |
| TC-04 | AC-04 | Kiểm tra `docs/55` & `docs/54 §5` về chuỗi, icon và mâu thuẫn mới | Có chuỗi `vi-VN` chuẩn cho login/TKB/vòng quay 24h và bảng mâu thuẫn rõ ràng | Rà chéo `docs/54 §5` và `docs/55 §§3,5` | Đạt (tài liệu, 2026-11-14): đã bổ sung mâu thuẫn #10–#13 trong `docs/54` và chuỗi/icon trong `docs/55` |
| TC-05 | AC-05 | Chạy `check_docs_links.py`, `check_task_records.py`, `git diff --check` | Cả 3 lệnh exit 0 | Windows 11, Python 3.11 | Đạt (2026-11-14): `PASS local links in 57 documentation files`, `Task records OK`, `git diff --check` exit 0 |

## Lệnh kiểm tra đã chạy

```powershell
python scripts/check_docs_links.py
# PASS local links in 57 documentation files (exit 0)

python scripts/check_task_records.py
# Task records OK (exit 0)

git diff --check
# (exit 0)
```

- **Phần chưa kiểm trên thiết bị/môi trường chạy thật:** `flutter analyze`, `flutter test`, build APK, `SleepWakeDial` ở `320/360/390/600 dp` + chữ `100/150/200%` + TalkBack, phát âm thanh báo thức và bật màn hình full-screen Android thật — chỉ kiểm tra sau khi cài `Flutter SDK` / `Android SDK` và mở lát cắt code `FE-S01`, `FE-S02`.
