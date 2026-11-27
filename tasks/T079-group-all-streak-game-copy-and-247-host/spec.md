# Đặc tả T079 — Chuỗi Nhóm Đủ Thành Viên, Ngôn Từ Game Thuần & Host 24/7

- **AC-01 (Streak nhóm chỉ cộng khi cả nhóm cùng hoàn thành trong ngày):**
  - Trong `CommitmentGroupService._pet_summary`, một ngày `local_date` chỉ được tính vào tập `days` tạo nên `currentStreakDays` và `bestStreakDays` khi **mọi thành viên `status='active'` hiện tại** trong nhóm đều có ít nhất 1 `CommitmentPetCare` hợp lệ (`study_care`, `morning_challenge`, `daily_report`) vào `local_date` đó.
  - Nếu nhóm có 2+ người và mới chỉ có 1 người làm hôm nay, `todayCareCount = 1`, `memberCount = 2`, `allMembersDoneToday = false`, chuỗi giữ ở mốc ngày hôm qua (hoặc 0 nếu chưa có chuỗi trước đó) cho tới khi người còn lại hoàn thành cùng ngày -> lập tức tăng `+1` (`Chuỗi 1`, `Chuỗi 2`, ..., `Chuỗi 100`). Không lộ danh sách thành viên chưa làm.
  - API trả thêm `memberCount`, `allMembersDoneToday`, `bestStreakDays`, `streakMilestoneLabelVi` (`Chuỗi N`, `Chuỗi 100+`...) trong object `pet`.
- **AC-02 (Ngôn từ Đấu trường & Game tự nhiên 100%, không lẫn text kỹ thuật/demo):**
  - Toàn bộ nhãn UI hiển thị cho người chơi trong `arena_screen.dart`, `arena_lobby_panel.dart`, `arena_pvp_lobby.dart` không còn cụm từ `Tướng gốc`, `tướng gốc`, `solo-three-v0.1`, `bộ pose`, `bảng thử nghiệm`, `playtest`, `0 RP Ranked`, `0 pay-to-win`, `G1`, `G2`, `G3`, `Seed`.
- **AC-03 (UI Chuỗi nhóm kiểu TikTok & Tài liệu + Blueprint host 24/7):**
  - `TodayPetCard`, `CommitmentGroupSheet`, `PetShareCard` hiển thị rõ biểu tượng ngọn lửa vector + `Chuỗi ${pet.currentStreakDays}`, mốc `Hôm nay X/Y người` và giải thích ngắn gọn `"Cả nhóm cùng hoàn thành hôm nay để giữ và tăng Chuỗi"`.
  - Có `render.yaml` và `docs/03-quality/06-trien-khai-247-va-tai-apk.md` chi tiết cho phương án host backend 24/7 ổn định + ký APK + phân phối qua Firebase App Distribution / Play / R2.
- **AC-04 (Kiểm thử):** Toàn bộ `pytest`, `flutter test`, `dart analyze`, `flutter analyze`, `check_docs_links.py`, `check_task_records.py` xanh.
