# Kế hoạch và kết quả kiểm thử T062

| ID | Liên kết AC | Kịch bản/đầu vào | Kết quả mong đợi | Cách chạy/môi trường | Kết quả thực/ngày |
| --- | --- | --- | --- | --- | --- |
| TC-01 | AC-01 | Gửi ảnh TKB thật (`media_1795104908791_f6e57b17.jpg`) qua `GeminiService.parse_timetable_image` | Trả về đủ 27 tiết gồm 22 môn học chính khóa + `ND GDĐP` (`civic_econ`) + `Chào cờ`/`SHL`/`HĐTN-HN` (`activity`) | Live Python script + `services/api/.env` + `docker compose up -d --build api` | **PASS (27/27 slots chính xác, 2026-11-19)** |
| TC-02 | AC-01 | Unit test parser alias TKB + route `/v1/challenges/next?mode=ai_regen` và `TimetableProfileScreen` khi chưa đăng nhập | Parser map đúng `Chào cờ`, `SHL`, `HĐTN-HN`, `ND GDĐP`, `KTPL`; client không trả TKB cứng giả khi chưa login | `POSTGRES_TEST_URL=... pytest -q` (PG16) & `flutter test` | **PASS (65 passed, 0 skipped, 2026-11-19)** |
| TC-03 | AC-02 | Mất mạng / chưa kết nối server trong `PersonalFlowViewModel.startSession(subjectCode: 'chemistry')` và đối chiếu đáp án offline | Trả câu hỏi + đáp án/lời giải sẵn đúng môn từ kho cục bộ (37 câu, 11 môn), xoay vòng không lặp 1 câu; giữ `xpAwarded = 0` | `flutter test --no-pub -j 1` (`t062_offline_bank_alarm_and_arena_timer_test.dart`) | **PASS (2026-11-20)** |
| TC-04 | AC-03 | Bấm "Tạo câu mới từ đề gốc (AI)" ở `PracticeSessionScreen` / `/v1/challenges/next?mode=ai_regen` | Gọi `mode=ai_regen`, sinh & lưu câu mới gắn user (`ai_q_...`) và nạp trực tiếp vào phiên để trả lời & chấm bình thường | `pytest` + `flutter test` | **PASS (2026-11-20)** |
| TC-05 | AC-04 | Thiết lập Solo chọn 30s/lượt, hết giờ đồng hồ đếm ngược, và quay vòng nạp câu liên tục; PvP hiển thị countdown `deadlineAtIso` | Hết giờ tự chuyển `uncertain` an toàn; nạp/quay vòng câu liên tục; PvP countdown hiện `Còn ...s` và dispose timer sạch | `flutter test --no-pub -j 1` (`t062_offline_bank_alarm_and_arena_timer_test.dart`) | **PASS (2026-11-20)** |
| TC-06 | AC-05 | Báo thức `AlarmMode.challenge` reo với `subjectCode: null` khi TKB hôm đó có Chào cờ ở S1 và Vật lí ở S2 -> bấm `Mở câu hỏi` | `MorningQuestionSelector` bỏ qua `activity`, tự phân giải môn `physics` -> mở `PracticeSessionScreen` với câu hỏi Vật lí | `flutter test --no-pub -j 1` (`t062_offline_bank_alarm_and_arena_timer_test.dart`) | **PASS (2026-11-20)** |
| TC-07 | AC-06 | Quét toàn bộ `app/lib/ui/`, `app/lib/domain/` và `debug_fixture_pvp_gateway.dart` tìm chuỗi `demo`, `Thử phiên`, `Đề mẫu`, `mẫu debug`, `mẫu mock`, `Mẫu PvP` + build APK | 0 kết quả vi phạm; `flutter analyze` 0 issues; `RAW_HEX_COLOR_HITS=0`; `flutter test` **98/98 passed**; APK `dist/mindclock-debug.apk` (`152.37 MB`) | `git grep` + `flutter analyze` + `flutter test --no-pub -j 1` + `build_android_apk.ps1` | **PASS (98/98 + APK 152.37 MB, 2026-11-20)** |

## Cổng theo rủi ro

- Báo thức: giữ nguyên tách biệt `AlarmSchedulerService`; phân giải môn TKB dùng fallback an toàn nếu chưa có TKB.
- AI: luôn có fallback về đề gốc ngân hàng nếu Gemini Vision hoặc Regen gặp 503/timeout.
- Điểm/thi đấu: offline đối chiếu cục bộ chỉ để luyện tập, tuyệt đối `xpAwarded = 0` và `isServerAuthoritative = false`.
