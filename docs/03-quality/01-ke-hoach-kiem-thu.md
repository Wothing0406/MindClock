# Kế hoạch kiểm thử và bằng chứng

**Quy tắc:** test file tồn tại ≠ test đã chạy; emulator ≠ Android thật; SQLite ≠ PostgreSQL; output model ≠ nhãn người dạy. Mỗi TC trong task ghi command, môi trường, phiên bản/build, ngày, kết quả, link log/ảnh không lộ dữ liệu. [PRD](../01-product/01-prd.md) là hành vi; [traceability](03-truy-vet-yeu-cau.md) nối AC ↔ TC.

## 1. Các tầng test

| Tầng | Kiểm gì | Chạy khi nào |
| --- | --- | --- |
| Dart unit/widget | Domain chọn câu/độ khó, ViewModel trạng thái, text/accessibility, offline, debug fixture không vào release | Mỗi PR Flutter và CI. |
| Kotlin unit + device | Tính occurrence/timezone, quyền, âm/fallback, Service/Receiver, MethodChannel | Mỗi PR Android; máy thật trước pilot và sau mọi đổi alarm/Manifest. |
| Python API/SQL | Auth owner, validation, idempotency, transaction, migration, AI stub, xóa dữ liệu | Mỗi PR API; PostgreSQL thật trong CI/staging. |
| Contract/E2E | Flutter ↔ `/v1`, lỗi 401/403/409/429/timeout, sync hai máy | Khi đổi payload hoặc tích hợp feature. |
| Human content/AI | Rubric, bản quyền, bài thật đa dạng, false grades, gợi ý Socratic | Trước publish câu/model/prompt và định kỳ. |
| Pilot/release | 7 ngày dùng thật, độ tin cậy chuông, crash/ANR, consent, hỗ trợ/rollback | Trước mở rộng người dùng. |

## 2. Ma trận P0 Android

| ID | Ca | Điều kiện pass / bằng chứng |
| --- | --- | --- |
| AD01 | Chuông đặt 1–2 phút sau, app foreground → khóa màn | Giờ dự kiến/thực, âm/rung/UI và Dừng; model/API level/quyền/build video. |
| AD02 | App bị swipe/process chết | Chuông vẫn reo theo khả năng OS; nếu OEM hạn chế phải báo rõ/trạng thái không giả. |
| AD03 | Tắt mạng/token hết hạn | Chuông/Dừng cục bộ; câu cache hoặc Ôn sau; không chờ API. |
| AD04 | Từ chối/thu hồi exact/notification/full-screen | UI báo đúng, fallback/hướng Settings, không hiện `Đã sẵn sàng` sai. |
| AD05 | Dừng khẩn cấp khi reo/đọc/đang chấm | Âm/rung tắt ngay một chạm; không phạt, không kẹt. **Chặn release nếu fail.** |
| AD06 | Mode thường/thử thách | Hoãn chỉ mode thường; thử thách không Hoãn, Dừng vẫn có. |
| AD07 | Reboot/đổi giờ/timezone/update | Không lịch mất/trùng; occurrence được tính lại, trạng thái phản ánh OS. |
| AD08 | Camera bị từ chối/ảnh mờ/AI timeout | Nhập chữ/uncertain/Ôn sau; ảnh không vào log. |
| AD09 | 320/360/390dp, chữ 200%, TalkBack/Reduce Motion | Giờ, câu, Dừng, kết quả đọc và chạm được; không cắt nút. |

AD01/02/07 phải chạy **ít nhất hai máy Android thật** có phiên bản/OEM khác nhau trước pilot; emulator chỉ test nhanh. Mỗi thay đổi native alarm/Manifest phải chạy lại AD01–07. Không dùng `flutter test` để thay những ca OS này.

## 3. API/dữ liệu/AI

| Nhóm | Test tối thiểu |
| --- | --- |
| AUTH | Guest chuông local; token sai/hết hạn 401; A/B 403/404 hợp lý; chưa consent không gửi ảnh/Live/bảng; logout máy chung không lộ cache; xóa/export idempotent. |
| DATA | PostgreSQL migration trống/có dữ liệu/rollback; duplicate session/attempt/XP; transaction fail; draft/retired question không scored; backup/restore/TTL; no key/ảnh/log. |
| CONTENT | Reviewer/rights/rubric/revision; câu nhiều dạng, trùng/câu mơ hồ/đơn vị/LaTeX/ảnh; import `dry_run`, quarantine và không publish nhầm; `MORNING-01`, `MEDIA-01–03`, `EDU-01` bảo đảm hook cùng kiến thức với câu, có fallback chữ và quyền từng asset. |
| AI | `correct/incorrect/uncertain`, ảnh mờ/cắt, cách giải tương đương, prompt injection, AI-validator bất đồng, timeout/rate/quota, không cấp XP/rank; `EDU-02–04` kiểm prompt theo mode và bài viết tay; đánh giá độc lập theo môn/khối. |
| FOCUS | FOCUS-01–08: timer offline/background/restart, finish retry, camera/mic opt-in, trợ lý Socratic, quyền riêng tư và hỗ trợ tiếp cận; không khóa app khác. |
| PLAN/PROFILE | PLAN-01–05: TKB/ngoại lệ/nhắc/quyền/xác nhận; PROFILE-01–04: owner, opt-in, avatar moderation, cache khi đổi account. |
| ON/SLEEP | ON-01–06: email/verify/catalog/plan/resume/offline; SLEEP-01–05: nhiều alarm, DND OS, lock screen riêng tư, MP3 fallback; MORNING-01–03/MEDIA-01–03: mở màn→câu bắt buộc để thưởng, sai 3/5, bỏ lượt/chuỗi, offline/accessibility/nguồn clip. |
| ROOM | ROOM-01–06: solo/AI/bạn, media permission, quota/reconnect, lời nhắc, invite/block/report, prompt eval. |
| GAME (sau) | GAME-01–05: cùng câu/rubric/deadline và lý do, server HP/event/ledger, reconnect/duplicate/void uncertain, cân bằng tướng/FX/âm trên hai máy. |

## 4. Cổng trước pilot/release

P0: build sạch CI; ON-01–06, AUTH-01/04, SLEEP-01–05, MORNING-01–03, MEDIA-01–03 nếu mở cảnh video, PLAN-01/03/05, FOCUS-01–05 và AD01–09 đạt ở các phần đã mở; 0 lỗi không dừng được chuông; schema/API test, quyền A/B, catalog từng lớp/môn có reviewer, nội dung đã duyệt và privacy review. ON/PLAN dùng Firebase emulator, PostgreSQL và máy thật theo tầng phù hợp; không lấy một màn mock làm bằng chứng. AI chấm chỉ bật cho dạng câu có bộ đánh giá độc lập và ngưỡng false-correct/false-incorrect/uncertain/latency/cost được định **trước khi đo**; nếu không đạt, dùng đáp án có validator hoặc `uncertain`. Phòng Live/bạn và PvP/ranked tắt tới cổng riêng. Pilot 7 ngày ghi số chuông dự kiến/thực, lỗi, hữu ích, khó chịu, opt-out, chi phí và sự cố; không dùng dữ liệu học sinh thật khi chưa đồng ý phù hợp.

## 5. Command gợi ý, chỉ tính pass khi chạy

Từ `app/`: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter test integration_test` trên device được chọn, Gradle unit. Từ `services/api/`: cài requirements trong venv, `python -m pytest`, `alembic upgrade head` trên PostgreSQL test. Từ root: `python scripts/check_docs_links.py`, `python scripts/check_task_records.py`, `python scripts/check_game_assets.py` khi đổi art. Ghi exit code, test count, OS/DB/device; môi trường hiện tại có thể chặn Flutter/pytest, phải ghi thay vì giả pass.
