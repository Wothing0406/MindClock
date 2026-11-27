# Kế hoạch và kết quả kiểm thử T082

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01, AC-02 | Toàn bộ 176 test Flutter + `t082_theme_sync_and_study_space_test.dart` kiểm tra không còn `mc.night` trên nền sáng thông thường | 0 lỗi phân tích tĩnh, 176/176 test pass ở `320dp 200%` | `dart analyze . --fatal-infos`, `flutter analyze --no-pub`, `flutter test --no-pub -j 1` | PASS (176/176 passed, 0 issues) — 27/11/2026 |
