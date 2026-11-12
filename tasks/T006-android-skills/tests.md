# Kiểm thử T006

| ID | AC | Cách kiểm | Kỳ vọng | Kết quả thực |
| --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Đọc `.agents/skills/mindclock-android-native/SKILL.md` và đối chiếu docs/31,45 | Có alarm/focus/camera và máy thật | PASS 12/11/2026: đủ phạm vi và ranh giới OS |
| TC-02 | AC-02 | Liệt kê thư mục skill mới, kiểm frontmatter + tài liệu tham chiếu | Skill đọc được, đúng Flutter/Android | PASS 12/11/2026: 3 SKILL.md hiện diện; `testing-setup` chỉ cho Kotlin native, `flutter-add-integration-test` cho Flutter |
| TC-03 | AC-03 | `rg` docs/16 và AGENTS; chạy `python scripts/check_task_records.py`, `git diff --check` | Docs nhất quán, hồ sơ hợp lệ | PASS 12/11/2026: định tuyến có trong docs/AGENTS, task checker OK, diff check không báo lỗi whitespace |

Không có app chạy nên không thể chạy emulator/thiết bị ở task này; test chỉ xác nhận cài và định tuyến skill, không xác nhận báo thức hoạt động.
