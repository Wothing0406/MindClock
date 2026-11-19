# Chi Tiết Từng Tính Năng & Giao Diện Android MindClock (`01` → `28`)

Tài liệu này mô tả chi tiết từng màn hình đã chạy và chụp thực tế từ bản `app-debug.apk` trên Android Emulator (`1080×2400`).

---

## Chương 1: Khởi đầu minh bạch quyền, Đăng nhập THPT & Thiết lập Avatar / Lộ trình

| # | Ảnh chụp thật | Mô tả giao diện & điểm đảm bảo chất lượng |
| --- | --- | --- |
| **01** | [`01_welcome_permissions.png`](screenshots/01_welcome_permissions.png) | **Màn Chào mừng & Giải thích quyền:** Không tự ý bật popup xin quyền hệ thống ngay khi mở app; giải thích minh bạch quyền chuông chính xác, thông báo, màn khóa, DND, cam/mic đều tắt mặc định. Cho phép 4 lựa chọn rõ ràng: Đăng ký/Đăng nhập, Dùng thử không tài khoản, `Chỉ báo thức` offline, hoặc `Để sau`. |
| **02** | [`02_auth_register_login.png`](screenshots/02_auth_register_login.png) | **Đăng ký / Đăng nhập tài khoản học tập:** Chấp nhận mọi email hợp lệ (không ép Gmail riêng), xác nhận mật khẩu và bắt buộc 2 ô đồng ý điều khoản + độ tuổi THPT (15–18 tuổi / đồng ý phụ huynh). Ghi rõ *ảnh bài làm không lưu mặc định*. |
| **03** | [`03_onboarding_avatar_presets.png`](screenshots/03_onboarding_avatar_presets.png) | **Chọn Avatar minh họa & Ảnh từ máy:** Hiển thị vòng tròn preview cùng bộ avatar gốc (`Bình minh`, `Hà Nhân`, `Tuyệt Đỉnh`, `Hàn Bội Pháp`), 3 icon vector dự phòng (`Trang sách`, `Kỷ luật`, `Học sinh`) và nút `Chọn ảnh từ máy` (lưu cục bộ qua SAF). |
| **04** | [`04_onboarding_avatar_selected.png`](screenshots/04_onboarding_avatar_selected.png) | **Xác nhận Avatar đang chọn:** Vòng tròn preview cập nhật ngay sang `Hà Nhân` sắc nét kèm viền trạng thái chọn. |
| **05** | [`05_onboarding_plan_draft.png`](screenshots/05_onboarding_plan_draft.png) | **Kế hoạch học tập nháp có kiểm soát:** Chọn Lớp 11 + Toán/Vật lí/Tiếng Anh sinh ra tối đa 3 việc cụ thể theo `Catalog gdpt-2018-v1 · rule-plan-v0.1`, ghi rõ môn nào chưa có câu duyệt (`Vật lí`) và **cam kết không tự bật báo thức nếu người dùng chưa xác nhận**. |
| **06** | [`06_today_dashboard_initial.png`](screenshots/06_today_dashboard_initial.png) | **Dashboard Hôm nay:** Gắn avatar học sinh ở header, đồng hồ `Thời gian thực` nhảy giây trực tiếp, banner nhắc quyền hệ thống trung thực (`Cần cấp quyền hệ thống...` thay vì báo ảo), và danh sách `Kế hoạch hôm nay` gắn badge `Có câu ôn duyệt`. |

---

## Chương 2: Thời khóa biểu 7 ngày, Gợi ý giờ dậy & Báo thức MP3 từ máy

| # | Ảnh chụp thật | Mô tả giao diện & điểm đảm bảo chất lượng |
| --- | --- | --- |
| **07** | [`07_timetable_7days_and_ocr.png`](screenshots/07_timetable_7days_and_ocr.png) | **Thời khóa biểu 7 ngày & Quét ảnh AI:** Chuyển nhanh T2–CN, đánh dấu ngày nghỉ (`CN (Nghỉ)`), có nút `Quét ảnh thời khóa biểu (AI tự động điền)` (tạo bản nháp cho user sửa trước khi lưu) và chỉnh nhanh lớp/môn/mục tiêu. |
| **08** | [`08_timetable_period_added.png`](screenshots/08_timetable_period_added.png) | **Thêm tiết học thực tế:** Sau khi bấm `Thêm tiết môn` và `Lưu tiết`, lịch cập nhật tức thì mà **không tự ý sửa giờ chuông** của người dùng. |
| **09** | [`09_alarm_config_wake_suggestion.png`](screenshots/09_alarm_config_wake_suggestion.png) | **Cấu hình báo thức & Công thức giờ dậy:** Hiển thị đồng hồ cấu hình, phần tính giờ dậy có giải thích công thức (`Giờ vào học - di chuyển - chuẩn bị - đệm`), chỉ áp dụng khi người dùng bấm `Dùng giờ này`. |
| **10** | [`10_alarm_saf_audio_picker.png`](screenshots/10_alarm_saf_audio_picker.png) | **Trình chọn nhạc SAF Android (`Downloads`):** Mở `Intent.ACTION_OPEN_DOCUMENT` (`MediaPickerBridgeHandler.kt`), thấy trực tiếp file `mindclock_demo_ringtone.mp3` & `mindclock_demo_avatar.png` trong `Downloads` để chọn và copy an toàn vào vùng riêng `filesDir/sounds/`. |
| **11** | [`11_alarm_config_challenge_and_sound.png`](screenshots/11_alarm_config_challenge_and_sound.png) | **Chế độ Thử thách & Môn kèm theo buổi sáng:** Chọn 1 trong 11 môn GDPT 2018 (hoặc `Theo lịch học hôm nay` / `Chỉ báo thức`), khi bật `Báo thức thử thách` hiện banner cam giải thích rõ: *Không có nút Hoãn; Dừng khẩn cấp luôn có 1 chạm*. |
| **12** | [`12_today_with_alarm_saved.png`](screenshots/12_today_with_alarm_saved.png) | **Dashboard sau khi lưu TKB & Báo thức:** Hiển thị TKB Thứ 5, câu ôn sáng đề xuất theo quy tắc (`Toán · Phương trình lượng giác cơ bản`, badge `Đã duyệt`), tách bạch báo thức đã lưu. |

---

## Chương 3: Luyện tập có trình bày, Nháp 24h & Không gian học Tập trung

| # | Ảnh chụp thật | Mô tả giao diện & điểm đảm bảo chất lượng |
| --- | --- | --- |
| **13** | [`13_practice_hub.png`](screenshots/13_practice_hub.png) | **Tab Luyện tập:** Phân rõ phần đăng nhập đồng bộ server (không ép buộc khách local), lối vào `Mở Không gian học tập trung`, trạng thái tiến độ riêng tư và 2 nút thử nghiệm: `Bắt đầu câu thường` / `Thử phiên báo thức thử thách`. |
| **14** | [`14_morning_hook_and_practice_question.png`](screenshots/14_morning_hook_and_practice_question.png) | **Bài tập có bước trình bày & Nháp offline:** Yêu cầu vừa nhập đáp án vừa viết cách làm; có nút `Lưu trên máy để gửi sau (nháp chữ ≤24h)`, nút `Chụp bài làm viết tay (tùy chọn)` kèm cảnh báo quyền riêng tư không chụp tên riêng, và nút `Hoàn thành không chấm`. |
| **15** | [`15_study_space_solo_no_ai.png`](screenshots/15_study_space_solo_no_ai.png) | **Không gian học — `Học một mình`:** Badge `Học một mình · Không có AI`, gợi ý việc học từ hồ sơ (`Ôn tập Toán`, `Ôn tập Vật lí`, `Học tự do`), ẩn hoàn toàn vùng AI. |
| **16** | [`16_study_space_ai_and_music_optin.png`](screenshots/16_study_space_ai_and_music_optin.png) | **Không gian học — `Học cùng MindClock` + `Học ngắt quãng`:** Tạo câu hỏi cá nhân hóa theo lớp 11 (`0 XP`, không thay ngân hàng báo thức), công tắc `Gemini Live thoại` mặc định `Đang tắt` cần đồng ý rõ ràng, card `Nhạc nền tập trung (từ máy · mặc định tắt)` có nút `Chọn nhạc nền từ máy`, và nút `Mở Digital Wellbeing Focus mode` (cam kết không khóa app khác/không trừ điểm xao nhãng). |
| **17** | [`17_study_space_deep_silent_locked.png`](screenshots/17_study_space_deep_silent_locked.png) | **Chế độ `Học sâu (im lặng)`:** Khóa cứng âm báo hết giờ, nhắc ngoài app và khóa luôn nhạc nền cục bộ (`Đang khóa im lặng hoàn toàn theo chế độ Học sâu`), AI chỉ trả bằng chữ khi hỏi. |
| **18** | [`18_study_space_running_timer.png`](screenshots/18_study_space_running_timer.png) | **Đồng hồ tập trung đang chạy (`23:22`):** Tính giờ theo mốc thời gian thiết bị thực tế, hiển thị song song `Thời gian thực tế` và `Trong app`, hỗ trợ `Tạm nghỉ` / `Kết thúc` và AI đồng hành khi đã đăng nhập. |

---

## Chương 4: Đấu trường G1 Công bằng, Chi tiết Tướng/Chiêu & Tab Tôi

| # | Ảnh chụp thật | Mô tả giao diện & điểm đảm bảo chất lượng |
| --- | --- | --- |
| **19** | [`19_arena_hub_modes.png`](screenshots/19_arena_hub_modes.png) | **Hub Đấu trường:** Trình bày 3 cửa trung thực — `Luyện đơn` (`Sẵn sàng · Offline`, `0 RP`), `Đấu đơn 1v1` (`Sắp mở · G2` khóa rõ chờ test 2 máy thật), `Đấu đội 2v2` (`Chưa mở · G3`), kèm nút `Xem Luật chơi (solo-three-v0.1)`. |
| **20** | [`20_arena_setup_champions.png`](screenshots/20_arena_setup_champions.png) | **Thiết lập Luyện đơn:** Chọn môn (`Toán` có câu duyệt vs môn chưa duyệt hiển thị trung thực), chọn 1 trong 3 tướng gốc kèm ảnh chân dung, xem độ khó Máy tập (deterministic theo `Seed #20261118`). |
| **21** | [`21_arena_champion_detail_modal.png`](screenshots/21_arena_champion_detail_modal.png) | **Modal xem trước Nội tại & Chiêu thức (`Hà Nhân`):** Cho user xem đầy đủ trước trận: chỉ số `100 HP · 50 Giáp · Tối đa 3 Qi · 6 Round`, mô tả `Nội tại: Kiên Định` và cả 3 icon chiêu gốc (`Đánh thường 28 ST`, `Chiêu 1 · Bước Vững 1 Qi`, `Chiêu 2 · Tĩnh Tâm Phản Kích 2 Qi`). |
| **22** | [`22_arena_battle_question.png`](screenshots/22_arena_battle_question.png) | **Màn chiến đấu trên `Võ đường Bình minh`:** Nền sân gốc MindClock (`map_courtyard.png`), thanh HP/Giáp/Qi hai bên rõ ràng, ưu tiên khung câu hỏi + đáp án + bước trình bày rộng rãi; sẵn nút `Bỏ qua hiệu ứng` (Reduce Motion) và `Âm: Tắt` mặc định. |
| **23** | [`23_arena_uncertain_no_penalty.png`](screenshots/23_arena_uncertain_no_penalty.png) | **Cơ chế phản hồi công bằng & Gợi ý 1 bước:** Khi bài làm chưa đủ/chưa đúng, hiện `Gợi ý 1 bước` đúng bài toán đang giải và cho phép `Sửa bài & thử lại` trước khi quyết định tiếp tục — không giấu đề hay trừ oan ngay lập tức. |
| **24** | [`24_arena_action_skill_picker.png`](screenshots/24_arena_action_skill_picker.png) | **Bảng chọn Đòn đánh / Chiêu thức (`Kết quả: Đúng rõ`):** Chỉ mở sau khi trả lời đúng kèm bước trình bày hợp lệ; hiển thị icon chiêu thức gốc. |
| **25** | [`25_arena_round_feedback.png`](screenshots/25_arena_round_feedback.png) | **Hồi đáp chiến đấu sau Round 1:** Giáp giảm minh bạch (`50/50 -> 22/50`), Qi tăng công bằng (`0/3 -> 1/3`), dòng log `Hiệu ứng riêng tướng` rõ sát thương hai bên. |
| **26** | [`26_arena_rubric_revealed.png`](screenshots/26_arena_rubric_revealed.png) | **Minh bạch chiêu khóa & `Cách chấm (Rubric rev 1)`:** Hiển thị đúng lý do khóa chiêu (`Thiếu Qi: cần 1, đang có 0` / `cần 2, đang có 0`) và cho mở `Cách chấm` từng bước sau khi nộp. |
| **27** | [`27_arena_summary_and_replay.png`](screenshots/27_arena_summary_and_replay.png) | **Tổng kết trọn trận 6 Round (`0 RP`):** Toàn bộ 6 round đánh giải Toán đều đạt `Đúng rõ`, ghi lịch sử từng câu + sát thương + HP còn lại + nút `Xem cách chấm` lại từng round để ôn kiến thức. |
| **28** | [`28_me_profile_avatar_and_permissions.png`](screenshots/28_me_profile_avatar_and_permissions.png) | **Tab Tôi (Avatar, Tài khoản & Quyền OS):** Hiện Avatar đã chọn kèm nút `Đổi ảnh đại diện từ máy`, form đăng nhập online tùy chọn, và `Trạng thái dịch vụ báo thức` đọc trực tiếp quyền OS thật (`Quyền báo thức chính xác: Đã cấp`, `Quyền màn hình khóa: Đã cấp`, `Quyền thông báo: Chưa cấp` — không báo sẵn sàng giả). |

---

## Tài nguyên gốc đóng gói sẵn trong App (`app/assets/`)

- **Avatar học sinh (`app/assets/avatars/`):** `avatar_sunrise.png` (`256×256`, cắt gọn viền trắng, bản quyền sở hữu bởi dự án).
- **Đấu trường G1 (`app/assets/arena/`):** `map_courtyard.png` (Sân Võ đường Bình minh `1024×576`), 3 chân dung tướng (`champ_ha_nhan.png`, `champ_tuyet_dinh.png`, `champ_han_boi_phap.png`), và 7 icon chiêu thức (`skill_basic.png`, `skill_ha_nhan_1.png`, `skill_ha_nhan_2.png`, `skill_tuyet_dinh_1.png`, `skill_tuyet_dinh_2.png`, `skill_han_boi_phap_1.png`, `skill_han_boi_phap_2.png`).

---

## Điểm lưu ý nhỏ phát hiện qua UI Audit thực tế (đề xuất cho task kế tiếp)
1. **Launcher Icon Android:** Trong ngăn ứng dụng Android, `MindClock` hiện vẫn dùng adaptive launcher icon mặc định của Flutter (`ic_launcher`) — nên thay bằng icon mặt trời/đồng hồ thương hiệu MindClock trước khi phát hành beta.
2. **Màn Tổng kết Luyện đơn (`27`):** Sau Round 6, phần thẻ log 6 round khá dài nên tiêu đề tổng kết (`0 RP`) và nút `Luyện lại cùng seed` nằm ở đầu/cuối cuộn; có thể ghim tóm tắt `Thắng/Hòa/Thua · 0 RP · Luyện lại` ngay trên đầu trang Tổng kết để nhìn gọn hơn ở màn nhỏ.
3. **Kiểm tra máy thật & Staging:** Cần test `AlarmRingActivity` đổ chuông MP3 tùy chỉnh trên 2 máy Android vật lý khi tắt màn hình và test đăng ký/đăng nhập Firebase Auth thật + Gemini API key qua `services/api/`.
