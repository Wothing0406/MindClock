# Kiểm thử T086

| Test ID | Mapping AC | Lệnh kiểm tra | Trạng thái | Ngày / Môi trường |
| --- | --- | --- | --- | --- |
| `TC-01` | `AC-01`, `AC-02` | `flutter test --no-pub -j 1` (`t086_study_microcheck_and_arena_stage_test.dart`, `study_room_modes_and_exp_test.dart`) | `passed` | `2026-11-27` / Windows Flutter `TestWidgets` |
| `TC-02` | `AC-03` | `flutter test --no-pub -j 1` (`t086`, `solo_arena_widget_test.dart`, `t065_skill_hand_test.dart`, tổng `181 passed`) | `passed` | `2026-11-27` / Windows Flutter `TestWidgets` |
| `TC-03` | Repo & Docs | `python scripts/check_docs_links.py ; python scripts/check_task_records.py ; python scripts/check_game_assets.py` | `passed` | `2026-11-27` / Windows Python |
