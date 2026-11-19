# Kế hoạch và kết quả kiểm thử T061

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Render `ArenaSpriteStage` chuyển trạng thái `idle → basic → skill1 → victory`, test Reduce Motion và điều kiện khóa/mở Chiêu 1 (`1 qi`) / Chiêu 2 (`2 qi`) | Sprite chạy đúng frame, nút Chiêu báo thiếu qi khi `<1`/`<2`, trả lời đúng tăng `qi` | `flutter test test/arena_pvp_and_sprites_test.dart` | Chưa chạy |
| TC-02 | AC-03 | Mô phỏng 2 user ghép trận `/v1/pvp/matchmake`, cùng nhận round, submit + action -> settle -> result | Cả hai client hiển thị HP/armor/qi khớp server, `uncertain` thành `void`, 0 RP | `pytest tests/test_pvp_*.py` + Flutter contract test | Chưa chạy |
| TC-03 | AC-04 | Build APK & quay lại demo flow trên `emulator-5554` vào `test_demo_android/` | APK cài mượt, ảnh/video khớp 100% tính năng mới | `.\scripts\build_android_apk.ps1` + ADB demo script | Chưa chạy |
