# Ma trận truy vết: yêu cầu → mã → test → cổng

Ma trận này giúp AI không “làm đẹp một màn” rồi báo xong sản phẩm. Trạng thái ở đây là **chưa xác nhận qua cổng** trừ khi task có bằng chứng cập nhật [hiện trạng](../00-start/01-hien-trang.md). Khi code thay đổi, chủ task cập nhật hàng tương ứng và `tests.md` với lệnh/máy/ngày.

| ID | Yêu cầu nguồn | Mã hiện có / vị trí đích | Test bắt buộc | Cổng |
| --- | --- | --- | --- | --- |
| P-01 | [PRD §4](../01-product/01-prd.md) đăng ký/hồ sơ học/avatar/plan | `app/lib` Auth/onboarding hiện có một phần; catalog/plan cần mở | UX-01, AUTH-01, ON-01–06 | R2 |
| P-02 | Lưu alarm, quyền OS, gợi giờ cần xác nhận | `app/lib/domain/services/alarm_scheduler_service.dart`, `app/android/` | AL-01–04, AD01/04/07, bridge/unit | R1 |
| P-03 | Chuông thử thách/Dừng khẩn cấp, mở màn→câu | `app/android/AlarmRing*` (T032 dừng âm khi `Mở câu`), Flutter ring UI + `MorningHookCard` (T033) | AL-05–09, MORNING-01, MEDIA-01–03, AD02/03/05/06/09 | R1/R3, release blocker |
| P-04 | Chuông thường/Hoãn local | Android alarm mode + UI | AL-10, AD06 | R1 |
| P-05 | Không có câu/mất mạng | local cache/content resolver | LEARN-01, AL-07 | R3 |
| P-06 | Nộp chữ/ảnh, chấm ba trạng thái; EduSkills hỗ trợ | `/v1/sessions/{id}/answers|attempts`, Gemini service, `eduskills_adapter.py` (T033) | LEARN-02–05, AI-01, EDU-01/03/04, idempotency, eval | R3/R4 |
| P-07 | Sai bài và gợi mở/bỏ lượt sau 5 sai rõ | challenge UI + `/v1/sessions/{id}/abandon` (T033) + study help service | LEARN-06, AI-02, MORNING-02, EDU-02 | R3/R4 |
| P-08 | Tiến độ riêng, XP/chuỗi server, bỏ lượt không thưởng | `xp_ledger`, progress query; streak day policy cần migration | DATA-01, MORNING-03, A/B, duplicate | R3/R4 |
| P-09 | Không gian học, gợi mục tiêu/recap, học sâu im lặng | Flutter study focus + `/v1/study/*` | FOCUS-01–09, Android lifecycle/audio | R5 |
| P-10 | Xóa/rút consent | Auth/consent API + local state | AUTH-04, PRIV-01, SQL purge/ẩn bảng | R2/R9 |
| P-11 | TKB/việc hôm nay/nhắc opt-in | timetable repo + local notifications; AI suggestion sau | PLAN-01–05 | R3/R4 |
| P-12 | Hồ sơ/tiến độ/chia sẻ opt-in | progress API; avatar/moderation/public projection chưa mở | PROFILE-01–04 | R2/R7+ |
| P-13 | Nhiều chuông/lịch ngủ/DND có trạng thái thật | Android alarm hiện có; sleep UI/DND chưa xác nhận | SLEEP-01–05, AD01–09 | R1 |
| P-14 | Hai lựa chọn chính solo/AI; bạn bè sau cổng | study timer/API có phần mã; Live room/bạn chưa có production | ROOM-01–08, FOCUS-01–09 | R5/R7 |
| P-16 | EXP theo thời gian phiên đã hoàn thành | Chưa có ledger thời gian được xác minh; cần API/SQL task riêng | FOCUS-10, ROOM-08, DATA-01 | R5 |
| P-17 | [MultiCal và tìm phòng](../01-product/12-lich-chung-ghep-phong-va-pet-nhom.md) | Chưa có; đích Flutter availability UI, FastAPI matching/vote, PostgreSQL, room security | GROUP-01–05/08, A/B, 2–4 máy | R7b |
| P-18 | [Nhóm cam kết, chuỗi đúng giờ và pet](../01-product/12-lich-chung-ghep-phong-va-pet-nhom.md) | Chưa có; đích group invite/membership, on-time day, AI consent, morning/study care ledger | GROUP-05–09, idempotency, Android alarm, privacy | R7b |
| P-15 | Giao hữu/PvP nộp lý do | `assets/game` art; arena/networking chưa có production | GAME-01–05 | R8 |
| G-01 | Ranked/rank/coin sau [GDD](../04-game/01-pvp-gdd.md) | Đặc tả/asset nghiên cứu, chưa có ranked production | hai máy/reconnect/ledger/playtest/rights | R8+ |
| Q-01 | Môi trường/release | `app/`, `services/api/`, `.github/workflows/ci.yml` (T029–T031 đã xác nhận `pytest` 19 pass, `flutter analyze`, Kotlin unit test 6/6, `app-debug.apk`, backup/restore rehearsal) | chạy CI `postgres:16-alpine` + `flutter test`, build ký, secret scan, rollback | R0/R9 |

## Cách dùng trong task

Spec ghi `source_refs` tới ID/section này và một hành vi cụ thể; AC mới nối TC trong `tests.md`. Plan nêu code/docs/test sửa; handoff nói test thật hay chưa, phiên bản/máy. Với lỗi production, thêm hàng/ràng buộc nếu ma trận chưa phủ. Không đánh dấu R1/R3/R4 chỉ vì API/web mock trả 200 hoặc code test tồn tại.
