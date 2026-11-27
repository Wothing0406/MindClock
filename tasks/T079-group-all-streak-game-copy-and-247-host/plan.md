# Kế hoạch thực hiện T079

| Bước | Việc làm và file dự kiến | Điều kiện xong | Trạng thái |
| --- | --- | --- | --- |
| 1 | Tạo hồ sơ `tasks/T079-group-all-streak-game-copy-and-247-host/` | `check_task_records.py` hợp lệ | [x] |
| 2 | Cập nhật `commitment_group_service.py` tính chuỗi nhóm theo 100% thành viên active + thêm test đa thành viên trong `test_commitment_groups_and_pet.py` | `pytest` pass kịch bản 2 & 3 thành viên | [x] |
| 3 | Cập nhật `commitment_group_models.dart`, `today_pet_card.dart`, `commitment_group_sheet.dart`, `pet_share_card.dart`, làm sạch toàn bộ text Đấu trường ở `arena_*.dart` và cập nhật test (`t076`, `t064`, `solo_arena_widget_test`, `t062`, `t079`) | `flutter analyze` & `flutter test` xanh | [x] |
| 4 | Tạo `render.yaml` + `docs/03-quality/06-trien-khai-247-va-tai-apk.md` + cập nhật `docs/02-engineering/13-nhom-cam-ket-va-pet-ledger.md` | `check_docs_links.py` PASS | [x] |
| 5 | Chạy toàn bộ test backend + Flutter + repo scripts và cập nhật `tests.md`, `handoff.md` | Toàn bộ cổng xanh | [x] |
