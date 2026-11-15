# Ma trận truy vết: yêu cầu → mã → test → cổng

Ma trận này giúp AI không “làm đẹp một màn” rồi báo xong sản phẩm. Trạng thái ở đây là **chưa xác nhận qua cổng** trừ khi task có bằng chứng cập nhật [hiện trạng](../00-start/01-hien-trang.md). Khi code thay đổi, chủ task cập nhật hàng tương ứng và `tests.md` với lệnh/máy/ngày.

| ID | Yêu cầu nguồn | Mã hiện có / vị trí đích | Test bắt buộc | Cổng |
| --- | --- | --- | --- | --- |
| P-01 | [PRD §4](../01-product/01-prd.md) khách/onboarding | `app/lib/ui/features/guest_shell`, local repo; Auth gateway sau | UX-01, AUTH-01; guest offline/logout máy chung | R1/R3 |
| P-02 | Lưu alarm, quyền OS, gợi giờ cần xác nhận | `app/lib/domain/services/alarm_scheduler_service.dart`, `app/android/` | AL-01–04, AD01/04/07, bridge/unit | R1 |
| P-03 | Chuông thử thách/Dừng khẩn cấp | `app/android/AlarmRing*`, Flutter ring UI | AL-05–09, AD02/03/05/06/09 | R1, release blocker |
| P-04 | Chuông thường/Hoãn local | Android alarm mode + UI | AL-10, AD06 | R1 |
| P-05 | Không có câu/mất mạng | local cache/content resolver | LEARN-01, AL-07 | R2 |
| P-06 | Nộp chữ/ảnh, chấm ba trạng thái | `/v1/sessions/{id}/answers|attempts`, Gemini service; client text path | LEARN-02–05, AI-01, idempotency, eval | R2/R4 |
| P-07 | Sai bài và gợi mở | challenge UI + study help service | LEARN-06, AI-02 | R2/R4 |
| P-08 | Tiến độ riêng, XP server, không dùng giờ dậy xếp hạng | `xp_ledger`, progress query | DATA-01, A/B, duplicate | R3 |
| P-09 | Không gian học | Flutter study focus + `/v1/study/*` | FOCUS-01–05, Android lifecycle | R5 |
| P-10 | Xóa/rút consent | Auth/consent API + local state | AUTH-04, PRIV-01, SQL purge/ẩn bảng | R3/R8 |
| P-11 | TKB/việc hôm nay/nhắc opt-in | timetable repo + local notifications; AI suggestion sau | PLAN-01–05 | R2/R5 |
| P-12 | Hồ sơ/tiến độ/chia sẻ opt-in | progress API; avatar/moderation/public projection chưa mở | PROFILE-01–04 | R3/R7+ |
| G-01 | Giao hữu/rank theo [GDD](../04-game/01-pvp-gdd.md) | `assets/game` art; backend/Flutter **chưa có PvP thực** | hai máy/reconnect/ledger/playtest | R7+ |
| Q-01 | Môi trường/release | `app/`, `services/api/`, CI cần bổ sung | build sạch, PostgreSQL, secret scan, rollback | R0/R8 |

## Cách dùng trong task

Spec ghi `source_refs` tới ID/section này và một hành vi cụ thể; AC mới nối TC trong `tests.md`. Plan nêu code/docs/test sửa; handoff nói test thật hay chưa, phiên bản/máy. Với lỗi production, thêm hàng/ràng buộc nếu ma trận chưa phủ. Không đánh dấu R1/R3/R4 chỉ vì API/web mock trả 200 hoặc code test tồn tại.
