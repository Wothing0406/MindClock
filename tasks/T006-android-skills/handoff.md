# Bàn giao T006

- **Trạng thái:** done, 12/11/2026.
- **Đã làm:** cài `testing-setup` từ Android Skills và `flutter-add-integration-test` từ Flutter Agent Plugins; tạo `mindclock-android-native`; cập nhật docs/16 và AGENTS.
- **Test:** TC-01–TC-03 PASS; `python scripts/check_task_records.py` → `Task records OK`; `git diff --check` không có lỗi whitespace.
- **Giới hạn:** chưa có app nên chưa chạy emulator/máy thật; skill Flutter nguồn ngoài có gợi ý Flutter Driver extension, docs/16 đã ràng buộc phải đối chiếu hướng dẫn Flutter hiện hành.
- **Rủi ro:** Android permission/API đổi theo SDK; cần đối chiếu tài liệu chính thức tại thời điểm code.
- **Điểm tiếp tục:** task coding alarm đầu tiên đọc `.agents/skills/mindclock-android-native/SKILL.md`, docs/31 và lập ma trận quyền/trạng thái; test máy Android thật trước khi gọi báo thức hoạt động.
